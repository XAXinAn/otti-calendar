import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:otti_calendar/features/common/widgets/custom_date_picker.dart';
import 'package:otti_calendar/features/common/widgets/custom_time_picker.dart';
import 'package:otti_calendar/features/schedule/pages/category_picker_page.dart';
import 'package:otti_calendar/models/schedule.dart';
import 'package:otti_calendar/services/schedule_service.dart';

class ScheduleDetailPage extends StatefulWidget {
  final Schedule schedule;

  const ScheduleDetailPage({super.key, required this.schedule});

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late Schedule _currentSchedule;
  final ScheduleService _scheduleService = ScheduleService();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late bool _isImportant;
  
  bool _isSaving = false;

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

  static const Map<String, IconData> _categoryIcons = {
    '工作': Icons.work_outline,
    '学习': Icons.school_outlined,
    '个人': Icons.person_outline,
    '生活': Icons.home_outlined,
    '健康': Icons.favorite_border,
    '运动': Icons.directions_run,
    '社交': Icons.chat_bubble_outline,
    '家庭': Icons.family_restroom,
    '差旅': Icons.flight_takeoff,
    '其他': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _currentSchedule = widget.schedule;
    _titleController = TextEditingController(text: _currentSchedule.title);
    _locationController = TextEditingController(text: _currentSchedule.location ?? '');
    _isImportant = _currentSchedule.isImportant;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _getDisplayTime(String? timeStr) {
    if (_currentSchedule.isAllDay || timeStr == null || timeStr.isEmpty) return '全天';
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;
      final hour = int.parse(parts[0]);
      final minuteStr = parts[1].substring(0, 2);
      final period = hour < 12 ? '上午' : '下午';
      final hourOfPeriod = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$period $hourOfPeriod:$minuteStr';
    } catch (e) {
      return timeStr;
    }
  }

  Future<void> _handleUpdate() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorTip('标题不能为空');
      return;
    }
    setState(() => _isSaving = true);
    final updated = Schedule(
      scheduleId: _currentSchedule.scheduleId,
      title: _titleController.text.trim(),
      scheduleDate: _currentSchedule.scheduleDate,
      startTime: _currentSchedule.startTime,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      category: _currentSchedule.category,
      isAllDay: _currentSchedule.isAllDay,
      isImportant: _isImportant,
    );
    final success = await _scheduleService.updateSchedule(updated);
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) Navigator.pop(context, 'updated');
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日程'),
        content: const Text('确定要永久删除这个日程吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isSaving = true);
      final success = await _scheduleService.deleteSchedule(_currentSchedule.scheduleId!);
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) Navigator.pop(context, 'deleted');
      }
    }
  }

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
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 15, decoration: TextDecoration.none)),
            ),
          ),
        );
      },
    );
  }

  void _editDate() {
    DateTime initial = DateTime.tryParse(_currentSchedule.scheduleDate) ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            _buildPickerHeader('选择日期', () {
              final newDateStr = DateFormat('yyyy-MM-dd').format(initial);
              setState(() {
                _currentSchedule = Schedule(
                  scheduleId: _currentSchedule.scheduleId,
                  title: _currentSchedule.title,
                  scheduleDate: newDateStr,
                  startTime: _currentSchedule.startTime,
                  location: _currentSchedule.location,
                  category: _currentSchedule.category,
                  isAllDay: _currentSchedule.isAllDay,
                  isImportant: _isImportant,
                );
              });
              Navigator.pop(context);
            }),
            Expanded(child: CustomDatePicker(initialDate: initial, onDateChanged: (date) => initial = date)),
          ],
        ),
      ),
    );
  }

  void _editTime() {
    final timeStr = _currentSchedule.startTime ?? "09:00";
    final parts = timeStr.split(':');
    TimeOfDay initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            _buildPickerHeader('选择时间', () {
              final newTimeStr = "${initial.hour.toString().padLeft(2, '0')}:${initial.minute.toString().padLeft(2, '0')}";
              setState(() {
                _currentSchedule = Schedule(
                  scheduleId: _currentSchedule.scheduleId,
                  title: _currentSchedule.title,
                  scheduleDate: _currentSchedule.scheduleDate,
                  startTime: newTimeStr,
                  location: _currentSchedule.location,
                  category: _currentSchedule.category,
                  isAllDay: false,
                  isImportant: _isImportant,
                );
              });
              Navigator.pop(context);
            }),
            Expanded(child: CustomTimePicker(initialTime: initial, onTimeChanged: (time) => initial = time)),
          ],
        ),
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
    final Color brandColor = _categoryColors[_currentSchedule.category] ?? Colors.blue;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('日程详情', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 32), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline, size: 26, color: Colors.black54), onPressed: _handleDelete),
          IconButton(icon: const Icon(Icons.check, size: 28, color: Colors.black54), onPressed: _handleUpdate),
          const SizedBox(width: 8),
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(builder: (context) => CategoryPickerPage(selectedCategory: _currentSchedule.category)),
                        );
                        if (result != null) {
                          setState(() {
                            _currentSchedule = Schedule(
                              scheduleId: _currentSchedule.scheduleId,
                              title: _currentSchedule.title,
                              scheduleDate: _currentSchedule.scheduleDate,
                              startTime: _currentSchedule.startTime,
                              location: _currentSchedule.location,
                              category: result,
                              isAllDay: _currentSchedule.isAllDay,
                              isImportant: _isImportant,
                            );
                          });
                        }
                      },
                      child: Column(
                        children: [
                          Icon(_categoryIcons[_currentSchedule.category] ?? Icons.category_rounded, size: 100, color: brandColor),
                          const SizedBox(height: 16),
                          Text('${_currentSchedule.category} (点击切换分类)', style: TextStyle(fontSize: 16, color: brandColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildDetailRow(Icons.edit_note_rounded, '标题',
                      child: TextField(
                        controller: _titleController,
                        maxLines: null,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      )
                    ),
                    _buildDetailRow(Icons.calendar_today_rounded, '日期', value: _currentSchedule.scheduleDate, onTap: _editDate),
                    _buildDetailRow(Icons.access_time_rounded, '时间', value: _getDisplayTime(_currentSchedule.startTime), onTap: _editTime),
                    _buildDetailRow(Icons.location_on_rounded, '地点', 
                      child: TextField(
                        controller: _locationController,
                        maxLines: null,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        decoration: const InputDecoration(hintText: '未设置地点', hintStyle: TextStyle(color: Colors.black12), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      )
                    ),
                    // 重要性开关，关闭时黑边白底
                    _buildDetailRow(Icons.star_rounded, '重要', 
                      showDivider: false,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: _isImportant,
                          onChanged: (val) => setState(() => _isImportant = val),
                          activeColor: Colors.white, // 开启时滑块白色
                          activeTrackColor: brandColor, // 开启时背景颜色
                          inactiveThumbColor: Colors.black, // 关闭时滑块黑色
                          inactiveTrackColor: Colors.white, // 关闭时背景白色
                          trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.transparent;
                            }
                            return Colors.black; // 关闭时显示黑边
                          }),
                        ),
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, {String? value, Widget? child, VoidCallback? onTap, bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 90,
                child: Row(
                  children: [
                    Icon(icon, color: Colors.grey.shade400, size: 24),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: child ?? Text(value ?? '', style: const TextStyle(fontSize: 16, color: Colors.black87), textAlign: TextAlign.right),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.shade200, thickness: 1.2),
      ],
    );
  }
}
