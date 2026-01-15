import 'package:flutter/material.dart';

class EditNicknamePage extends StatefulWidget {
  final String initialNickname;

  const EditNicknamePage({super.key, required this.initialNickname});

  @override
  State<EditNicknamePage> createState() => _EditNicknamePageState();
}

class _EditNicknamePageState extends State<EditNicknamePage> {
  late TextEditingController _controller;
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
    _controller.addListener(() {
      setState(() {
        _canSave = _controller.text.isNotEmpty && _controller.text != widget.initialNickname;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '更改昵称',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black26, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
              color: _canSave ? Colors.blue : Colors.black12,
              size: 28,
            ),
            onPressed: _canSave ? () => Navigator.pop(context, _controller.text) : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 10),
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: '我的昵称', // hintText 设为“我的昵称”
                  hintStyle: TextStyle(color: Colors.black26),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '取一个好听的名字吧', // 下方的一行小字
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
