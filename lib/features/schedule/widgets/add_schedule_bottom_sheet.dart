import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:otti_calendar/services/ocr_service.dart';

class AddScheduleBottomSheet extends StatefulWidget {
  const AddScheduleBottomSheet({super.key});

  @override
  State<AddScheduleBottomSheet> createState() => _AddScheduleBottomSheetState();
}

class _AddScheduleBottomSheetState extends State<AddScheduleBottomSheet> with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _manualTitleController;
  late TextEditingController _aiTextController;

  bool _isManualSendEnabled = false;
  bool _isAiSendEnabled = false;

  // New fields for OCR
  final OcrService _ocrService = const OcrService();
  final ImagePicker _picker = ImagePicker();
  bool _isRecognizing = false;


  @override
  void initState() {
    super.initState();
    // Set the initial index to 1 to default to the AI Assistant tab
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);

    _manualTitleController = TextEditingController();
    _aiTextController = TextEditingController();

    _manualTitleController.addListener(() {
      final isEnabled = _manualTitleController.text.isNotEmpty;
      if (isEnabled != _isManualSendEnabled) {
        setState(() {
          _isManualSendEnabled = isEnabled;
        });
      }
    });

    _aiTextController.addListener(() {
      final isEnabled = _aiTextController.text.isNotEmpty;
      if (isEnabled != _isAiSendEnabled) {
        setState(() {
          _isAiSendEnabled = isEnabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualTitleController.dispose();
    _aiTextController.dispose();
    super.dispose();
  }

  // New method to handle image picking and OCR
  Future<void> _pickAndRecognizeImage() async {
    if (_isRecognizing) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() {
      _isRecognizing = true;
      _aiTextController.text = '正在识别图片...';
    });

    try {
      final text = await _ocrService.recognize(image.path);
      if (mounted) {
        // Prepend the recognized text to any existing text.
        final currentText = _aiTextController.text == '正在识别图片...' ? '' : _aiTextController.text;
        final newText = text.isEmpty ? '未识别到文字' : text;
        _aiTextController.text = (currentText + ' ' + newText).trim();
      }
    } catch (e) {
      if (mounted) {
        _aiTextController.text = '识别出错: 请检查权限或模型文件。';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // This Padding ensures the sheet moves up with the keyboard
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35,
        decoration: const BoxDecoration(
          color: Colors.white, // Pure white background
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: '手动添加'), Tab(text: 'AI助手')],
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black, // Simple, elegant underline indicator
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.label,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildManualAddTab(), _buildAiAssistantTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAssistantTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _aiTextController,
              maxLines: null, // Allows expanding
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '用一句话，快速添加日程、提醒或待办',
                hintStyle: TextStyle(color: Colors.grey), // Set hint text color to grey
                border: InputBorder.none,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_in_picture_alt_outlined, color: Colors.black54, size: 20),
                label: const Text('悬浮窗', style: TextStyle(color: Colors.black54)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                ),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.mic_none_outlined, color: Colors.black54), onPressed: () {}),
                  // Updated IconButton
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: Colors.black54),
                    onPressed: _isRecognizing ? null : _pickAndRecognizeImage, // Disable button when recognizing
                  ),
                  IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.black54), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.near_me),
                    iconSize: 28,
                    color: _isAiSendEnabled ? Colors.blue : Colors.grey,
                    onPressed: _isAiSendEnabled ? () { /* AI submit logic */ } : null,
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualAddTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _manualTitleController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: '告诉小獭你的日程~',
                    border: InputBorder.none,
                  ),
                ),
                const TextField(
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  decoration: InputDecoration(
                    hintText: '地点',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, color: Colors.red),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.access_time_outlined, color: Colors.amber),
                onPressed: () {},
              ),
              const Spacer(), // Pushes the send button to the end
              IconButton(
                icon: const Icon(Icons.near_me), // Use the tilted paper plane icon
                iconSize: 28,
                color: _isManualSendEnabled ? Colors.blue : Colors.grey,
                onPressed: _isManualSendEnabled ? () { /* Manual submit logic */ } : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
