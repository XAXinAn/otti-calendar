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
  
  bool _isSaving = false;

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
      final hour = int.tryParse(parts[0]) ?? 0;
      final minuteStr = parts[1].substring(0, parts[1].length >= 2 ? 2 : parts[1].length);
      final period = hour < 12 ? '上午' : '下午';
      final hourOfPeriod = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$period $hourOfPeriod:${minuteStr.padLeft(2, '0')}';
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

    final updatedSchedule = Schedule(
      scheduleId: _currentSchedule.scheduleId,
      title: _titleController.text.trim(),
      scheduleDate: _currentSchedule.scheduleDate,
      startTime: _currentSchedule.startTime,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      category: _currentSchedule.category,
      isAllDay: _currentSchedule.isAllDay,
    );

    final success = await _scheduleService.updateSchedule(updatedSchedule);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        // 成功后直接退出，并传递 'updated' 字符串
        Navigator.pop(context, 'updated');
      } else {
        _showErrorTip('修改失败，请重试');
      }
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
        if (success) {
          // 成功后直接退出，并传递 'deleted' 字符串
          Navigator.pop(context, 'deleted');
        } else {
          _showErrorTip('删除失败');
        }
      }
    }
  }

  // 仅用于错误提示（页面不退出时使用）
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
    TimeOfDay initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
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

  Future<void> _editCategory() async {
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
        );
      });
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('日程详情', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 32), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline, size: 26, color: Colors.black54), onPressed: _isSaving ? null : _handleDelete),
          IconButton(icon: const Icon(Icons.check, size: 28, color: Colors.blue), onPressed: _isSaving ? null : _handleUpdate),
          const SizedBox(width: 8),
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _editCategory,
                      child: Column(
                        children: [
                          Icon(_categoryIcons[_currentSchedule.category] ?? Icons.event, size: 80, color: Colors.blue),
                          const SizedBox(height: 12),
                          Text('${_currentSchedule.category} (点击切换分类)', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildEditableItem(Icons.title, '标题', _titleController),
                          _buildDivider(),
                          _buildDetailItem(Icons.calendar_today_outlined, '日期', _currentSchedule.scheduleDate, _editDate),
                          _buildDivider(),
                          _buildDetailItem(Icons.access_time, '时间', _getDisplayTime(_currentSchedule.startTime), _editTime),
                          _buildDivider(),
                          _buildEditableItem(Icons.location_on_outlined, '地点', _locationController, hint: '未设置地点'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildEditableItem(IconData icon, String label, TextEditingController controller, {String hint = ''}) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              maxLines: null,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.black12), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey, size: 24),
            const SizedBox(width: 16),
            SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87), textAlign: TextAlign.right)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black12, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 56, endIndent: 20, color: Colors.grey[100]);
}
