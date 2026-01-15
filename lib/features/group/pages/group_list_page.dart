import 'package:flutter/material.dart';
import 'package:otti_calendar/models/group.dart';
import 'package:otti_calendar/features/group/pages/group_detail_page.dart';

class GroupListPage extends StatelessWidget {
  final String title;
  final List<Group> groups;

  const GroupListPage({super.key, required this.title, required this.groups});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // 白色大圆角容器
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: groups.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Text('暂无群组', style: TextStyle(color: Colors.black12, fontSize: 16)),
                      ),
                    )
                  : Column(
                      children: List.generate(groups.length, (index) {
                        final group = groups[index];
                        final isLast = index == groups.length - 1;
                        return _buildGroupItem(context, group, isLast: isLast);
                      }),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupItem(BuildContext context, Group group, {bool isLast = false}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GroupDetailPage(group: group)),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(fontSize: 17, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                      if (group.description != null && group.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          group.description!,
                          style: const TextStyle(fontSize: 13, color: Colors.black26),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black12, size: 20),
              ],
            ),
          ),
          if (!isLast)
            const Divider(height: 1, indent: 24, endIndent: 24, color: Color(0xFFF0F2F5)),
        ],
      ),
    );
  }
}
