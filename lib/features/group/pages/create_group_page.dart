import 'package:flutter/material.dart';
import 'package:otti_calendar/services/group_service.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final GroupService _groupService = GroupService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_nameController.text.trim().isEmpty) {
      _showTip('请输入群组名称');
      return;
    }

    setState(() => _isLoading = true);
    final response = await _groupService.createGroup(
      _nameController.text.trim(),
      _descController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (mounted) {
      if (response['code'] == 200) {
        // 创建成功直接返回，不需要弹窗显示邀请码
        Navigator.pop(context, true);
      } else {
        _showTip(response['message'] ?? '创建失败');
      }
    }
  }

  void _showTip(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('创建群组', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : IconButton(
                  icon: const Icon(Icons.check, size: 28, color: Colors.black54),
                  onPressed: _handleCreate,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: '群组名称',
                      hintStyle: TextStyle(color: Colors.black26),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: '群组简介 (可选)',
                      hintStyle: TextStyle(color: Colors.black26),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '创建群组后 归属设置为该群组的日程都会同步到群组成员的日历中',
                    style: TextStyle(color: Colors.black26, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
