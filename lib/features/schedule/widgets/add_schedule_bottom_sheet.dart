import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:otti_calendar/features/common/widgets/custom_date_picker.dart';
import 'package:otti_calendar/features/common/widgets/custom_time_picker.dart';
import 'package:otti_calendar/features/schedule/pages/category_picker_page.dart';
import 'package:otti_calendar/models/group.dart';
import 'package:otti_calendar/models/schedule.dart';
import 'package:otti_calendar/services/group_service.dart';
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

  final ScheduleService _scheduleService = ScheduleService();
  final GroupService _groupService = GroupService();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategory;
  bool _isImportant = false;
  
  String? _selectedGroupId;
  String? _selectedGroupName;

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
      if (isEnabled != _isAiSendEnabled) setState(() => _isAiSendEnabled = isEnabled);
    });
  }

  void _updateManualSendState() {
    final bool isEnabled = _manualTitleController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedCategory != null;
    if (isEnabled != _isManualSendEnabled) setState(() => _isManualSendEnabled = isEnabled);
  }

  @override
  void dispose() {
    _manualTitleController.dispose();
    _manualLocationController.dispose();
    _aiTextController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? '上午' : '下午';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
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
              if (mounted) setState(() => _selectedDate = tempDate);
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
              if (mounted) setState(() => _selectedTime = tempTime);
              _updateManualSendState();
              Navigator.pop(context);
            }),
            Expanded(child: CustomTimePicker(initialTime: tempTime, onTimeChanged: (time) => tempTime = time)),
          ],
        ),
      ),
    );
  }

  void _showGroupPicker() async {
    // 异步拉取数据
    final createdGroups = await _groupService.getCreatedGroups();
    final joinedGroups = await _groupService.getJoinedGroups();
    final allGroups = [...createdGroups, ...joinedGroups];

    // 关键修复：await 之后必须判断 mounted
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('选择日程归属', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                    title: const Text('个人'),
                    trailing: (_selectedGroupName == '个人' || _selectedGroupName == null) ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () {
                      if (mounted) {
                        setState(() { _selectedGroupId = null; _selectedGroupName = '个人'; });
                      }
                      Navigator.pop(context);
                    },
                  ),
                  ...allGroups.map((group) => ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.group, color: Colors.white)),
                    title: Text(group.name),
                    trailing: _selectedGroupId == group.groupId ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () {
                      if (mounted) {
                        setState(() { _selectedGroupId = group.groupId; _selectedGroupName = group.name; });
                      }
                      Navigator.pop(context);
                    },
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => CategoryPickerPage(selectedCategory: _selectedCategory)),
    );
    if (result != null && mounted) {
      setState(() => _selectedCategory = result);
      _updateManualSendState();
    }
  }

  Future<void> _handleSubmit() async {
    if (!_isManualSendEnabled || _isLoading) return;
    setState(() => _isLoading = true);

    final schedule = Schedule(
      title: _manualTitleController.text.trim(),
      scheduleDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      startTime: "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
      location: _manualLocationController.text.trim().isEmpty ? null : _manualLocationController.text.trim(),
      category: _selectedCategory!,
      isAllDay: false,
      isImportant: _isImportant,
      groupId: _selectedGroupId,
    );

    final success = await _scheduleService.createSchedule(schedule);

    // 关键修复：await 之后判断 mounted
    if (!mounted) return;
    
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('日程添加失败')));
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

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
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
            Expanded(child: TabBarView(controller: _tabController, children: [_buildManualAddTab(), _buildAiAssistantTab()])),
          ],
        ),
      ),
    );
  }

  Widget _buildManualAddTab() {
    final bool hasTags = _selectedDate != null || _selectedTime != null || _selectedCategory != null || _selectedGroupName != null;

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
                  if (_selectedGroupName != null) ...[
                    _buildTag('# $_selectedGroupName', Colors.indigoAccent, () { 
                      if (mounted) {
                        setState(() { _selectedGroupId = null; _selectedGroupName = null; }); 
                      }
                    }),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedDate != null) ...[
                    _buildTag('# ${DateFormat('yyyy年M月d日', 'zh_CN').format(_selectedDate!)}', const Color(0xFFEF5350), () { if (mounted) setState(() => _selectedDate = null); _updateManualSendState(); }),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedTime != null) ...[
                    _buildTag('# ${_formatTime(_selectedTime!)}', const Color(0xFFFFC107), () { if (mounted) setState(() => _selectedTime = null); _updateManualSendState(); }),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedCategory != null)
                    _buildTag('# $_selectedCategory', _categoryColors[_selectedCategory] ?? Colors.grey, () { if (mounted) setState(() => _selectedCategory = null); _updateManualSendState(); }),
                ],
              ),
            ),
            const SizedBox(height: 8), 
          ],
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActionItem(Icons.calendar_today_outlined, '日期', const Color(0xFFEF5350), _showDatePicker),
                      const SizedBox(width: 8),
                      _buildActionItem(Icons.access_time_outlined, '时间', const Color(0xFFFFC107), _showTimePicker),
                      const SizedBox(width: 8),
                      _buildActionItem(Icons.label_outline, '分类', Colors.blue, _pickCategory),
                      const SizedBox(width: 8),
                      _buildActionItem(Icons.groups_outlined, '归属', Colors.indigoAccent, _showGroupPicker),
                      const SizedBox(width: 8),
                      _buildActionItem(
                        _isImportant ? Icons.star_rounded : Icons.star_outline_rounded, 
                        '重要', 
                        _isImportant ? Colors.orange : Colors.black26, 
                        () { if (mounted) setState(() => _isImportant = !_isImportant); _updateManualSendState(); }
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 4),
          const Text('左滑添加更多标签', style: TextStyle(color: Colors.black26, fontSize: 11)),
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
