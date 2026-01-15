import 'package:flutter/material.dart';
import 'package:otti_calendar/features/profile/profile_edit_page.dart';
import 'package:otti_calendar/features/group/pages/group_management_page.dart'; // 引入群组管理页
import 'package:otti_calendar/services/auth_service.dart';
import 'package:otti_calendar/models/auth_response.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final AuthService _authService = AuthService();
  String _displayName = '正在加载...';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await _authService.getUserInfo();
    if (mounted && userInfo != null) {
      setState(() {
        _displayName = userInfo.username;
      });
    } else if (mounted) {
      setState(() {
        _displayName = '未登录';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF0F2F5),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // 1. 用户信息头部
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileEditPage()),
              ).then((_) => _loadUserInfo());
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              color: Colors.transparent,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, size: 45, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _displayName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),

          // 2. 常用功能卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 0.0),
                    child: Text('常用功能', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  GridView.count(
                    padding: const EdgeInsets.all(0),
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // 修改：添加点击跳转逻辑
                      _buildFunctionItem(Icons.group_outlined, '群组管理', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupManagementPage()));
                      }),
                      _buildFunctionItem(Icons.pie_chart_outline, '数据统计', () {}),
                      _buildFunctionItem(Icons.layers_outlined, '更多', () {}),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. 设置
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.black87),
                title: const Text('设置', style: TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () { /* TODO */ },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}
