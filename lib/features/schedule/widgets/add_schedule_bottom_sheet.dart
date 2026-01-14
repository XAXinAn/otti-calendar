import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:otti_calendar/features/common/widgets/custom_date_picker.dart';
import 'package:otti_calendar/features/common/widgets/custom_time_picker.dart';
import 'package:otti_calendar/features/schedule/pages/category_picker_page.dart';
import 'package:otti_calendar/models/schedule.dart';
import 'package:otti_calendar/services/ocr_service.dart';
import 'package:otti_calendar/services/schedule_service.dart';

class AddScheduleBottomSheet extends StatefulWidget {
  const AddScheduleBottomSheet({super.key});

  @override
  State<AddScheduleBottomSheet> createState() => _AddScheduleBottomSheetState();
}

class _AddScheduleBottomSheetState extends State<AddScheduleBottomSheet> with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _manualTitleController;
  late TextEditingController _manualLocationController;
  late TextEditingController _aiTextController;

  bool _isManualSendEnabled = false;
  bool _isAiSendEnabled = false;
  bool _isLoading = false;

  final OcrService _ocrService = const OcrService();
  final ScheduleService _scheduleService = ScheduleService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isRecognizing = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategory;

  static const Map<String, Color> _categoryColors = {
    '工作': Color(0xFF2196F3),
    '学习': Color(0xFF4CAF50),
    '个人': Color(0xFFFF9800),
    '生活': Color(0xFF9C27B0),
    '健康': Color(0xFFF44336),
    '运动': Color(0xFF009688),
    '社交': Color(0xFFE91E63),
    '家庭': Color(0xFF3F51B5),
    '差旅': Color(0xFFFFC107),
    '其他': Color(0xFF9E9E9E),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _manualTitleController = TextEditingController();
    _manualLocationController = TextEditingController();
    _aiTextController = TextEditingController();

    _manualTitleController.addListener(_updateManualSendState);

    _aiTextController.addListener(() {
      final isEnabled = _aiTextController.text.isNotEmpty;
      if (isEnabled != _isAiSendEnabled) {
        setState(() => _isAiSendEnabled = isEnabled);
      }
    });
  }

  void _updateManualSendState() {
    final bool isEnabled = _manualTitleController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedCategory != null;
    
    if (isEnabled != _isManualSendEnabled) {
      setState(() => _isManualSendEnabled = isEnabled);
    }
  }

  // 显示屏幕中间的半透明提示
  void _showMiddleTip(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // 保持背景透明
      builder: (BuildContext context) {
        // 2秒后自动关闭
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7), // 半透明黑色背景
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualTitleController.dispose();
    _manualLocationController.dispose();
    _aiTextController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    DateTime tempDate = _selectedDate ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height / 3,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.grey))),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedDate = tempDate);
                      _updateManualSendState();
                      Navigator.pop(context);
                    },
                    child: const Text('完成', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomDatePicker(
                initialDate: _selectedDate ?? DateTime.now(),
                onDateChanged: (newDate) => tempDate = newDate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker() {
    TimeOfDay tempTime = _selectedTime ?? TimeOfDay.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height / 3,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.grey))),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedTime = tempTime);
                      _updateManualSendState();
                      Navigator.pop(context);
                    },
                    child: const Text('完成', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomTimePicker(
                initialTime: _selectedTime ?? TimeOfDay.now(),
                onTimeChanged: (newTime) => tempTime = newTime,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? '上午' : '下午';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  Future<void> _pickCategory() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => CategoryPickerPage(selectedCategory: _selectedCategory)),
    );
    if (result != null) {
      setState(() => _selectedCategory = result);
      _updateManualSendState();
    }
  }

  Future<void> _handleSubmit() async {
    if (!_isManualSendEnabled) return;

    setState(() => _isLoading = true);

    final schedule = Schedule(
      title: _manualTitleController.text,
      scheduleDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      startTime: "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
      location: _manualLocationController.text.isNotEmpty ? _manualLocationController.text : null,
      category: _selectedCategory!,
      isAllDay: false,
    );

    final success = await _scheduleService.createSchedule(schedule);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true); // 返回成功状态
      } else {
        _showMiddleTip('日程添加失败，请重试'); // 失败显示中间提示
      }
    }
  }

  Future<void> _processImage(ImageSource source) async {
    if (_isRecognizing) return;
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null || !mounted) return;

    setState(() {
      _isRecognizing = true;
      _aiTextController.text = '正在识别...';
    });

    try {
      final text = await _ocrService.recognize(image.path);
      if (mounted) {
        final currentText = _aiTextController.text == '正在识别...' ? '' : _aiTextController.text;
        _aiTextController.text = (currentText + ' ' + (text.isEmpty ? '未识别到文字' : text)).trim();
      }
    } catch (e) {
      if (mounted) _showMiddleTip('识别出错');
    } finally {
      if (mounted) setState(() => _isRecognizing = false);
    }
  }

  Widget _buildTag(String label, Color color, VoidCallback onCancel) {
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 6),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label, 
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: '手动添加'), Tab(text: '一键记录')],
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black26,
              labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              indicatorColor: Colors.black,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.5,
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

  Widget _buildManualAddTab() {
    final bool hasTags = _selectedDate != null || _selectedTime != null || _selectedCategory != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _manualTitleController,
            autofocus: true,
            minLines: 1,
            maxLines: 2,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: '告诉小獭你的日程~',
              hintStyle: TextStyle(color: Colors.black26),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          TextField(
            controller: _manualLocationController,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            decoration: const InputDecoration(
              hintText: '地点',
              hintStyle: TextStyle(color: Colors.black26, fontSize: 16),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          
          const Spacer(),
          
          if (hasTags) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedDate != null) ...[
                    _buildTag(
                      '# ${DateFormat('yyyy年M月d日', 'zh_CN').format(_selectedDate!)}',
                      const Color(0xFFEF5350),
                      () {
                        setState(() => _selectedDate = null);
                        _updateManualSendState();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedTime != null) ...[
                    _buildTag(
                      '# ${_formatTime(_selectedTime!)}',
                      const Color(0xFFFFC107),
                      () {
                        setState(() => _selectedTime = null);
                        _updateManualSendState();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedCategory != null)
                    _buildTag(
                      '# $_selectedCategory',
                      _categoryColors[_selectedCategory] ?? Colors.grey,
                      () {
                        setState(() => _selectedCategory = null);
                        _updateManualSendState();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8), 
          ],
          
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, color: Color(0xFFEF5350), size: 24),
                onPressed: _showDatePicker,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12), 
              IconButton(
                icon: const Icon(Icons.access_time_outlined, color: Color(0xFFFFC107), size: 24),
                onPressed: _showTimePicker,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12), 
              if (_selectedCategory == null)
                IconButton(
                  icon: const Icon(Icons.label_outline, color: Colors.blue, size: 24),
                  onPressed: _pickCategory,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const Spacer(),
              _isLoading 
                ? const SizedBox(height: 20, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.near_me, size: 28),
                    color: _isManualSendEnabled ? Colors.blue : Colors.black12,
                    onPressed: _isManualSendEnabled ? _handleSubmit : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
            ],
          ),
        ],
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
              maxLines: null,
              decoration: const InputDecoration(
                hintText: '用一句话，快速添加日程、提醒或待办',
                hintStyle: TextStyle(color: Colors.black26),
                border: InputBorder.none,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_in_picture_alt_outlined, size: 18, color: Colors.black54),
                label: const Text('悬浮窗', style: TextStyle(fontSize: 13, color: Colors.black54)),
                style: TextButton.styleFrom(backgroundColor: Colors.orange.shade50, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.mic_none_outlined, size: 22, color: Colors.black54), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.image_outlined, size: 22, color: Colors.black54), onPressed: () => _processImage(ImageSource.gallery)),
                  IconButton(icon: const Icon(Icons.camera_alt_outlined, size: 22, color: Colors.black54), onPressed: () => _processImage(ImageSource.camera)),
                  IconButton(
                    icon: const Icon(Icons.near_me, size: 28),
                    color: _isAiSendEnabled ? Colors.blue : Colors.grey,
                    onPressed: _isAiSendEnabled ? () {} : null,
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
