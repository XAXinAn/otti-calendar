import 'package:flutter/material.dart';
import 'package:otti_calendar/services/group_service.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final TextEditingController _codeController = TextEditingController();
  final GroupService _groupService = GroupService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showErrorTip('请输入邀请码');
      return;
    }

    setState(() => _isLoading = true);
    final response = await _groupService.joinGroup(code);
    setState(() => _isLoading = false);

    if (mounted) {
      if (response['code'] == 200) {
        // 成功后直接返回，由主页显示提示
        Navigator.pop(context, true); 
      } else {
        _showErrorTip(response['message'] ?? '加入失败，请检查邀请码');
      }
    }
  }

  // 仅用于错误提示（不退出页面时使用）
  void _showErrorTip(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 1), () {
          if (Navigator.of(ctx).canPop()) Navigator.pop(ctx);
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('加入群组', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : IconButton(
                  icon: const Icon(Icons.check, size: 28, color: Colors.black54),
                  onPressed: _handleJoin,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _codeController,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: '邀请码',
                      hintStyle: TextStyle(color: Colors.black26),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('加入群组，加入高效', style: TextStyle(color: Colors.black26, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
