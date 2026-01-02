import 'package:flutter/material.dart';

class BottomInputBar extends StatelessWidget {
  const BottomInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA), // Match scaffold background
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Adjust padding for safe area
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.black87),
                  SizedBox(width: 8),
                  Text('点击添加日程', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.multitrack_audio_outlined, color: Color(0xFF606266)),
        ],
      ),
    );
  }
}
