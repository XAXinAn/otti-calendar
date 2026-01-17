import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:otti_calendar/config/xfyun_config.dart';

class XfyunSpeechService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 8),
  ));

  final AudioRecorder _record = AudioRecorder();
  String? _recordPath;

  Future<void> start() async {
    final hasPermission = await _record.hasPermission();
    if (!hasPermission) {
      throw Exception('缺少录音权限');
    }

    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/xfyun_record.pcm';

    await _record.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: XfyunConfig.sampleRate,
        numChannels: 1,
      ),
      path: _recordPath!,
    );
  }

  Future<String> stopAndRecognize() async {
    final path = await _record.stop();
    if (path == null) {
      throw Exception('录音失败');
    }

    final audioBytes = await File(path).readAsBytes();
    if (audioBytes.isEmpty) {
      throw Exception('录音内容为空');
    }

    _ensureConfig();

    final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final signa = _buildSigna(ts);

    final headers = {
      'appId': XfyunConfig.appId,
      'ts': ts,
      'signa': signa,
      'Content-Type': 'application/json',
    };

    final body = {
      'audio': base64Encode(audioBytes),
      'encoding': 'raw',
      'sample_rate': XfyunConfig.sampleRate.toString(),
      'language': XfyunConfig.language,
      'accent': XfyunConfig.accent,
    };

    final response = await _dio.post(
      XfyunConfig.baseUrl,
      data: body,
      options: Options(headers: headers),
    );

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final code = data['code'] as int? ?? data['err_no'] as int? ?? 0;
      if (code == 0 || code == 200) {
        final text = _extractText(data);
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
        throw Exception('未识别到有效内容');
      }
      final message = data['message']?.toString() ?? data['err_msg']?.toString() ?? '语音识别失败';
      throw Exception(message);
    }

    throw Exception('语音识别失败');
  }

  Future<void> dispose() async {
    if (await _record.isRecording()) {
      await _record.stop();
    }
  }

  void _ensureConfig() {
    if (XfyunConfig.appId == 'YOUR_APP_ID' || XfyunConfig.apiKey == 'YOUR_API_KEY') {
      throw Exception('请先配置讯飞 AppID 和 ApiKey');
    }
  }

  String _buildSigna(String ts) {
    final md5Str = md5.convert(utf8.encode('${XfyunConfig.appId}$ts')).toString();
    final hmac = Hmac(sha1, utf8.encode(XfyunConfig.apiKey));
    final signaBytes = hmac.convert(utf8.encode(md5Str)).bytes;
    return base64Encode(signaBytes);
  }

  String? _extractText(Map<String, dynamic> data) {
    if (data['data'] is Map<String, dynamic>) {
      final inner = data['data'] as Map<String, dynamic>;
      if (inner['text'] != null) return inner['text'].toString();
      if (inner['result'] is String) return inner['result'].toString();
      if (inner['result'] is Map<String, dynamic>) {
        return _parseResult(inner['result'] as Map<String, dynamic>);
      }
    }

    if (data['result'] is Map<String, dynamic>) {
      return _parseResult(data['result'] as Map<String, dynamic>);
    }

    if (data['text'] != null) return data['text'].toString();
    return null;
  }

  String? _parseResult(Map<String, dynamic> result) {
    final ws = result['ws'];
    if (ws is List) {
      final buffer = StringBuffer();
      for (final item in ws) {
        if (item is Map && item['cw'] is List) {
          final cw = item['cw'] as List;
          if (cw.isNotEmpty && cw.first is Map) {
            final w = (cw.first as Map)['w'];
            if (w != null) buffer.write(w.toString());
          }
        }
      }
      return buffer.toString();
    }
    return null;
  }
}
