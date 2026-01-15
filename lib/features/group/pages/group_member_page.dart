import 'package:flutter/material.dart';
import 'package:otti_calendar/models/group_member.dart';
import 'package:otti_calendar/services/group_service.dart';

class GroupMemberPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupMemberPage({super.key, required this.groupId, required this.groupName});

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
    final members = await _groupService.getGroupMembers(widget.groupId);
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

  // 1. 发起真实删除请求
  Future<void> _handleDelete() async {
    final idsToRemove = _selectedUserIds.toList();
    final success = await _groupService.removeMembers(widget.groupId, idsToRemove);
    
    if (mounted) {
      if (success) {
        _showMiddleTip('已成功移除 ${idsToRemove.length} 位成员');
        _clearSelection();
        _fetchMembers();
      } else {
        _showMiddleTip('移除失败，请检查权限');
      }
    }
  }

  // 2. 发起真实角色切换请求
  Future<void> _handleToggleAdmin() async {
    if (_selectedUserIds.length != 1) return;
    
    final userId = _selectedUserIds.first;
    final member = _members.firstWhere((m) => m.userId == userId);
    final String newRole = member.groupRole == 'admin' ? 'member' : 'admin';

    final success = await _groupService.updateMemberRole(widget.groupId, userId, newRole);
    
    if (mounted) {
      if (success) {
        _showMiddleTip(newRole == 'admin' ? '已设为管理员' : '已解除管理员权限');
        _clearSelection();
        _fetchMembers();
      } else {
        _showMiddleTip('权限更新失败，仅群主可操作');
      }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          isMultiSelectMode ? '已选择 ${_selectedUserIds.length} 人' : '${widget.groupName} 成员',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(isMultiSelectMode ? Icons.close : Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: isMultiSelectMode ? _clearSelection : () => Navigator.pop(context),
        ),
        actions: [
          if (isMultiSelectMode) ...[
            if (_selectedUserIds.length == 1)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.blue),
                onPressed: _handleToggleAdmin,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _handleDelete,
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: _members.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 24),
              itemBuilder: (context, index) {
                final member = _members[index];
                final bool isSelected = _selectedUserIds.contains(member.userId);
                final bool isOwner = member.groupRole == 'owner';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  tileColor: isSelected ? Colors.blue.withOpacity(0.05) : null,
                  onTap: isMultiSelectMode ? () => _toggleSelection(member.userId) : null,
                  onLongPress: isOwner ? null : () => _toggleSelection(member.userId),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                        child: Icon(Icons.person, color: isSelected ? Colors.white : Colors.grey),
                      ),
                      if (isSelected)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(member.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      if (isOwner) _buildRoleTag('群主', Colors.orange),
                      if (member.groupRole == 'admin') _buildRoleTag('管理员', Colors.blue),
                    ],
                  ),
                  subtitle: Text('加入时间: ${member.joinedAt != null ? DateTime.fromMillisecondsSinceEpoch(member.joinedAt!).toString().split(' ')[0] : "未知"}'),
                  trailing: isMultiSelectMode && !isOwner
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(member.userId),
                          shape: const CircleBorder(),
                        )
                      : null,
                );
              },
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
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
