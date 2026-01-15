import 'package:flutter/material.dart';
import 'package:otti_calendar/models/group.dart';
import 'package:otti_calendar/features/group/pages/group_member_page.dart';
import 'package:otti_calendar/services/group_service.dart';

class GroupDetailPage extends StatefulWidget {
  final Group group;

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final GroupService _groupService = GroupService();
  bool _isSaving = false;

  Future<void> _handleAction() async {
    final bool isOwner = widget.group.currentUserRole == 'owner';
    final String groupId = widget.group.groupId ?? '';
    if (groupId.isEmpty) return;

    setState(() => _isSaving = true);
    
    final bool success = isOwner 
        ? await _groupService.disbandGroup(groupId) 
        : await _groupService.quitGroup(groupId);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _showMiddleTip(isOwner ? '群组已解散' : '已成功退出群组');
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, true); // 返回并刷新
        });
      } else {
        _showMiddleTip('操作失败，请重试');
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
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = widget.group.currentUserRole == 'owner';
    final bool isAdmin = widget.group.currentUserRole == 'admin';
    final bool hasManagePrivilege = isOwner || isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EBFD),
      appBar: AppBar(
        title: const Text('群组详情', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_rounded, size: 100, color: Colors.blueAccent),
                        const SizedBox(height: 20),
                        Text(
                          widget.group.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 40),
                        
                        if (hasManagePrivilege)
                          _buildInfoRow('邀请码', widget.group.inviteCode ?? '暂无邀请码'),
                        
                        _buildInfoRow(
                          '群简介', 
                          widget.group.description ?? '暂无介绍',
                          isLast: !hasManagePrivilege,
                        ),
                        
                        if (hasManagePrivilege)
                          _buildInfoRow(
                            '成员数', 
                            '${widget.group.memberCount ?? 1} 人', 
                            isLast: true,
                            onTap: () {
                              if (widget.group.groupId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupMemberPage(
                                      group: widget.group,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _handleAction, // 绑定逻辑
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOwner ? Colors.redAccent.withOpacity(0.1) : const Color(0xFFBCC8ED),
                          foregroundColor: isOwner ? Colors.redAccent : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          isOwner ? '解散该群' : '退出群组',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black87)),
                const Spacer(),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                      if (onTap != null) const Icon(Icons.chevron_right, size: 18, color: Colors.black12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
        ],
      ),
    );
  }
}
