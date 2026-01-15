import 'package:flutter/material.dart';
import 'package:otti_calendar/features/common/widgets/custom_gender_picker.dart';
import 'package:otti_calendar/features/profile/pages/edit_nickname_page.dart';
import 'package:otti_calendar/services/auth_service.dart';
import 'package:otti_calendar/models/auth_response.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final AuthService _authService = AuthService();
  
  String _username = '正在加载...';
  String _gender = '保密';
  String _phone = '';
  UserInfo? _user;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userInfo = await _authService.getUserInfo();
    if (mounted && userInfo != null) {
      setState(() {
        _user = userInfo;
        _username = userInfo.username;
        _phone = userInfo.phone;
        _gender = userInfo.gender ?? '保密';
      });
    }
  }

  Future<void> _saveChanges(String field, String newValue) async {
    if (_user == null) return;

    final newUser = UserInfo(
      userId: _user!.userId,
      username: field == '昵称' ? newValue : _username,
      phone: _phone, // 手机号保持不变
      gender: field == '性别' ? newValue : _gender,
      role: _user!.role,
      avatar: _user!.avatar,
    );

    final success = await _authService.updateProfile(newUser);
    if (success && mounted) {
      setState(() {
        if (field == '昵称') _username = newValue;
        if (field == '性别') _gender = newValue;
      });
    }
  }

  void _editNickname() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => EditNicknamePage(initialNickname: _username),
      ),
    );
    if (result != null) {
      _saveChanges('昵称', result);
    }
  }

  void _editGender() {
    String tempGender = _gender;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.grey, fontSize: 16))),
                  const Text('选择性别', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      _saveChanges('性别', tempGender);
                      Navigator.pop(context);
                    },
                    child: const Text('完成', style: TextStyle(color: Colors.blue, fontSize: 16)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: CustomGenderPicker(initialGender: _gender, onGenderChanged: (val) => tempGender = val)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBFD),
      appBar: AppBar(
        title: const Text('个人中心', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32, color: Colors.black26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.coffee_rounded, size: 120, color: Colors.grey.shade300),
                    const SizedBox(height: 40),
                    _buildInfoRow('昵称', _username, _editNickname),
                    _buildInfoRow('性别', _gender, _editGender),
                    _buildInfoRow('手机号', _phone, null, isLast: true), // 禁用修改：onTap 传 null
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
                    onPressed: () async {
                      await _authService.logout();
                      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBCC8ED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('退出登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildInfoRow(String label, String value, VoidCallback? onTap, {bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87)),
                const Spacer(),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.black54)),
              ],
            ),
          ),
          if (!isLast) Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
        ],
      ),
    );
  }
}
