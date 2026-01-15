import 'package:flutter/material.dart';
import 'package:otti_calendar/features/group/pages/create_group_page.dart';
import 'package:otti_calendar/features/group/pages/join_group_page.dart';
import 'package:otti_calendar/features/group/pages/group_detail_page.dart';
import 'package:otti_calendar/features/group/pages/group_list_page.dart';
import 'package:otti_calendar/models/group.dart';
import 'package:otti_calendar/services/group_service.dart';

class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({super.key});

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  final GroupService _groupService = GroupService();
  List<Group> _createdGroups = [];
  List<Group> _joinedGroups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() => _isLoading = true);
    try {
      final created = await _groupService.getCreatedGroups();
      final joined = await _groupService.getJoinedGroups();
      
      created.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
      joined.sort((a, b) => (b.joinedAt ?? 0).compareTo(a.joinedAt ?? 0));

      if (mounted) {
        setState(() {
          _createdGroups = created;
          _joinedGroups = joined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 统一的中间提示框
  void _showMiddleTip(String message) {
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
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('群组管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchGroups,
            backgroundColor: Colors.white,
            color: Colors.blue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActionItem('创建群组', () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupPage()));
                          if (result == true) {
                            _showMiddleTip('创建群组成功');
                            _fetchGroups();
                          }
                        }),
                        _buildActionItem('加入群组', () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinGroupPage()));
                          if (result == true) {
                            _showMiddleTip('成功加入群组');
                            _fetchGroups();
                          }
                        }),
                        
                        const Padding(
                          padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                          child: Text('开启你的日程分享', style: TextStyle(color: Colors.black26, fontSize: 14)),
                        ),
                        
                        _buildSectionHeader('我创建的群组'),
                        _buildGroupList(_createdGroups, '我创建的群组'),
                        
                        const SizedBox(height: 20),
                        
                        _buildSectionHeader('我加入的群组'),
                        _buildGroupList(_joinedGroups, '我加入的群组', isLastSection: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildGroupList(List<Group> groups, String title, {bool isLastSection = false}) {
    if (groups.isEmpty) {
      return _buildEmptyPlaceholder();
    }
    final displayGroups = groups.length > 5 ? groups.take(5).toList() : groups;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayGroups.map((g) => _buildGroupItem(g.name, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => GroupDetailPage(group: g)));
        })),
        if (groups.length > 5)
          _buildGroupItem('更多', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => GroupListPage(title: title, groups: groups)));
          }, isLast: isLastSection),
      ],
    );
  }

  Widget _buildEmptyPlaceholder() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text('暂无群组', style: TextStyle(color: Colors.black12, fontSize: 14)),
    );
  }

  Widget _buildActionItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(children: [Text(title, style: const TextStyle(fontSize: 17, color: Colors.black87))]),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24, color: Color(0xFFF0F2F5)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
    );
  }

  Widget _buildGroupItem(String name, VoidCallback onTap, {bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(children: [Text(name, style: const TextStyle(fontSize: 16, color: Colors.black87))]),
          ),
          if (!isLast) const Divider(height: 1, indent: 24, endIndent: 24, color: Color(0xFFF0F2F5)),
        ],
      ),
    );
  }
}
