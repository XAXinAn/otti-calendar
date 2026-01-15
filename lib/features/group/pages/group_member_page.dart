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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('${widget.groupName} 成员', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: _members.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 24),
              itemBuilder: (context, index) {
                final member = _members[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  title: Row(
                    children: [
                      Text(member.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      if (member.groupRole == 'owner') _buildRoleTag('群主', Colors.orange),
                      if (member.groupRole == 'admin') _buildRoleTag('管理员', Colors.blue),
                    ],
                  ),
                  subtitle: Text('加入时间: ${member.joinedAt != null ? DateTime.fromMillisecondsSinceEpoch(member.joinedAt!).toString().split(' ')[0] : "未知"}', style: const TextStyle(fontSize: 12)),
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
