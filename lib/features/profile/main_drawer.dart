import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF0F2F5), // Light grey background from the image
      child: ListView(
        padding: EdgeInsets.zero, // Remove top padding from ListView
        children: <Widget>[
          // 1. Custom User Profile Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.person, size: 45, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text(
                  '江杭羲',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 0),

          // 2. Common Functions Card
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
                      _buildFunctionItem(Icons.smart_toy_outlined, 'AI聊天'),
                      _buildFunctionItem(Icons.group_outlined, '群组管理'), // CORRECTED semicolon to comma
                      _buildFunctionItem(Icons.pie_chart_outline, '数据统计'),
                      _buildFunctionItem(Icons.layers_outlined, '更多'),
                    ],
                  ),
                  const SizedBox(height: 12), // Add some space at the bottom of the card
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Settings Card
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
                onTap: () { /* Navigate to settings page */ },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionItem(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: Colors.black87),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}
