import 'package:flutter/material.dart';
import 'package:otti_calendar/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    final phoneRegExp = RegExp(r'^1[3-9]\d{9}$');
    if (!phoneRegExp.hasMatch(value)) {
      return '手机号格式不正确';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final response = await _authService.register(
        _phoneController.text,
        _passwordController.text,
      );

      if (mounted) {
        if (response.code == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('注册成功，请登录')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注册出错: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '极 速 日 历',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '开启您的智能高效生活',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 50),
                    // 手机号输入框
                    _buildTextField(
                      controller: _phoneController,
                      hintText: '手机号',
                      icon: Icons.phone_android,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 20),
                    // 密码输入框
                    _buildTextField(
                      controller: _passwordController,
                      hintText: '设置密码',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) => (value == null || value.length < 6) ? '密码至少需要6位' : null,
                    ),
                    const SizedBox(height: 20),
                    // 确认密码输入框
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hintText: '确认密码',
                      icon: Icons.lock_reset,
                      obscureText: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    // 注册按钮
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                '立即注册',
                                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 返回登录
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '已有账号？ 去登录',
                        style: TextStyle(color: Colors.black38, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 自定义返回按钮
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: Icon(icon, color: Colors.black87, size: 28),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF2196F3)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
