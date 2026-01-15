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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: groups.isEmpty
          ? const Center(child: Text('暂无群组', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: groups.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 24, endIndent: 24),
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: Text(group.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  subtitle: group.description != null ? Text(group.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                  trailing: const Icon(Icons.chevron_right, color: Colors.black12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GroupDetailPage(group: group)),
                    );
                  },
                );
              },
            ),
    );
  }
}
