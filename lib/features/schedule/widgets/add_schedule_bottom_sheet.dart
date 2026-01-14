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
  bool _isImportant = false;

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

  @override
  void dispose() {
    // 修正：使用正确的变量名
    _manualTitleController.dispose();
    _manualLocationController.dispose();
    _aiTextController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    DateTime tempDate = _selectedDate ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            _buildPickerHeader('选择日期', () {
              setState(() => _selectedDate = tempDate);
              _updateManualSendState();
              Navigator.pop(context);
            }),
            Expanded(child: CustomDatePicker(initialDate: tempDate, onDateChanged: (date) => tempDate = date)),
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
        height: 300,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            _buildPickerHeader('选择时间', () {
              setState(() => _selectedTime = tempTime);
              _updateManualSendState();
              Navigator.pop(context);
            }),
            Expanded(child: CustomTimePicker(initialTime: tempTime, onTimeChanged: (time) => tempTime = time)),
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
      title: _manualTitleController.text.trim(),
      scheduleDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      startTime: "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
      location: _manualLocationController.text.trim().isEmpty ? null : _manualLocationController.text.trim(),
      category: _selectedCategory!,
      isAllDay: false,
      isImportant: _isImportant,
    );

    final success = await _scheduleService.createSchedule(schedule);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('日程添加失败')));
      }
    }
  }

  Widget _buildTag(String label, Color color, VoidCallback onCancel) {
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(onTap: onCancel, child: const Icon(Icons.close, color: Colors.white, size: 14)),
        ],
      ),
    );
  }

  Widget _buildPickerHeader(String title, VoidCallback onDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextButton(onPressed: onDone, child: const Text('完成', style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.38,
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
            decoration: const InputDecoration(hintText: '告诉小獭你的日程~', hintStyle: TextStyle(color: Colors.black26), border: InputBorder.none, contentPadding: EdgeInsets.zero),
          ),
          TextField(
            controller: _manualLocationController,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            decoration: const InputDecoration(hintText: '地点', hintStyle: TextStyle(color: Colors.black26, fontSize: 16), border: InputBorder.none, contentPadding: EdgeInsets.zero),
          ),
          const Spacer(),
          if (hasTags) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedDate != null) ...[
                    _buildTag('# ${DateFormat('yyyy年M月d日', 'zh_CN').format(_selectedDate!)}', const Color(0xFFEF5350), () { setState(() => _selectedDate = null); _updateManualSendState(); }),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedTime != null) ...[
                    _buildTag('# ${_formatTime(_selectedTime!)}', const Color(0xFFFFC107), () { setState(() => _selectedTime = null); _updateManualSendState(); }),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedCategory != null)
                    _buildTag('# $_selectedCategory', _categoryColors[_selectedCategory] ?? Colors.grey, () { setState(() => _selectedCategory = null); _updateManualSendState(); }),
                ],
              ),
            ),
            const SizedBox(height: 8), 
          ],
          Row(
            children: [
              IconButton(icon: const Icon(Icons.calendar_today_outlined, color: Color(0xFFEF5350), size: 24), onPressed: _showDatePicker, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12), 
              IconButton(icon: const Icon(Icons.access_time_outlined, color: Color(0xFFFFC107), size: 24), onPressed: _showTimePicker, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12), 
              IconButton(icon: const Icon(Icons.label_outline, color: Colors.blue, size: 24), onPressed: _pickCategory, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() => _isImportant = !_isImportant);
                  _updateManualSendState();
                },
                child: Icon(
                  _isImportant ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _isImportant ? Colors.orange : Colors.black12,
                  size: 26,
                ),
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
                  IconButton(icon: const Icon(Icons.near_me, size: 28), color: _isAiSendEnabled ? Colors.blue : Colors.grey, onPressed: _isAiSendEnabled ? () {} : null),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
