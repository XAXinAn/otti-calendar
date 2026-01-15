import 'package:flutter/material.dart';
import 'package:otti_calendar/models/group.dart';
import 'package:otti_calendar/models/group_member.dart';
import 'package:otti_calendar/services/group_service.dart';

class GroupMemberPage extends StatefulWidget {
  final Group group;

  const GroupMemberPage({super.key, required this.group});

  @override
  State<GroupMemberPage> createState() => _GroupMemberPageState();
}

class _GroupMemberPageState extends State<GroupMemberPage> {
  final GroupService _groupService = GroupService();
  List<GroupMember> _members = [];
  bool _isLoading = true;

  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    if (widget.group.groupId == null) return;
    final members = await _groupService.getGroupMembers(widget.group.groupId!);
    if (mounted) {
      setState(() {
        _members = members;
        _isLoading = false;
      });
    }
  }

  void _clearSelection() {
    setState(() => _selectedUserIds.clear());
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _handleDelete() async {
    final idsToRemove = _selectedUserIds.toList();
    final success = await _groupService.removeMembers(widget.group.groupId!, idsToRemove);
    if (mounted && success) {
      _showMiddleTip('已移除 ${idsToRemove.length} 位成员');
      _clearSelection();
      _fetchMembers();
    }
  }

  Future<void> _handleToggleAdmin() async {
    if (_selectedUserIds.length != 1) return;
    final userId = _selectedUserIds.first;
    final member = _members.firstWhere((m) => m.userId == userId);
    
    // 如果是管理员则降级为成员，如果是成员则升级为管理员
    final String newRole = member.groupRole == 'admin' ? 'member' : 'admin';
    
    final success = await _groupService.updateMemberRole(widget.group.groupId!, userId, newRole);
    if (mounted && success) {
      _showMiddleTip(newRole == 'admin' ? '已设为管理员' : '已解除管理员');
      _clearSelection();
      _fetchMembers();
    }
  }

  void _showMiddleTip(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 1), () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
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
    final bool isMultiSelectMode = _selectedUserIds.isNotEmpty;
    // 权限判断：当前用户是否为群主
    final bool isCurrentUserOwner = widget.group.currentUserRole == 'owner';
    // 权限判断：当前用户是否有管理权限（群主或管理员）
    final bool hasManagePrivilege = isCurrentUserOwner || widget.group.currentUserRole == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          isMultiSelectMode ? '已选择 ${_selectedUserIds.length} 人' : '${widget.group.name} 成员',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(isMultiSelectMode ? Icons.close : Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: isMultiSelectMode ? _clearSelection : () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchMembers,
                    backgroundColor: Colors.white,
                    color: Colors.blue,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                      itemCount: _members.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 56, endIndent: 0, color: Color(0xFFF0F2F5)),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final bool isSelected = _selectedUserIds.contains(member.userId);
                        final bool isTargetOwner = member.groupRole == 'owner';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          // 只有拥有管理权限的人才能触发选择，且群主不可被选
                          onTap: isMultiSelectMode ? () => _toggleSelection(member.userId) : null,
                          onLongPress: (hasManagePrivilege && !isTargetOwner) 
                              ? () => _toggleSelection(member.userId) 
                              : null,
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                            child: Icon(Icons.person, color: isSelected ? Colors.white : Colors.grey),
                          ),
                          title: Row(
                            children: [
                              Text(member.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 8),
                              if (isTargetOwner) _buildRoleTag('群主', Colors.orange),
                              if (member.groupRole == 'admin') _buildRoleTag('管理员', Colors.blue),
                            ],
                          ),
                          subtitle: Text('加入: ${member.joinedAt != null ? DateTime.fromMillisecondsSinceEpoch(member.joinedAt!).toString().split(' ')[0] : "未知"}', style: const TextStyle(fontSize: 12, color: Colors.black26)),
                          trailing: isMultiSelectMode && !isTargetOwner
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleSelection(member.userId),
                                  shape: const CircleBorder(),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
          ),
          
          // 底部固定选项栏
          if (isMultiSelectMode)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: Colors.black12),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPlainActionBtn(
                            label: '移除成员',
                            onPressed: _handleDelete,
                          ),
                          // 只有群主才有权设置/解除管理员
                          if (isCurrentUserOwner && _selectedUserIds.length == 1)
                            _buildPlainActionBtn(
                              label: _members.firstWhere((m) => m.userId == _selectedUserIds.first).groupRole == 'admin' ? '解除管理员' : '添加管理员',
                              onPressed: _handleToggleAdmin,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlainActionBtn({required String label, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildRoleTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
