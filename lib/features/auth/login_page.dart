import 'dart:async';

import 'package:flutter/material.dart';
import 'package:otti_calendar/models/auth_session.dart';
import 'package:otti_calendar/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authService, required this.onLogin});

  final AuthService authService;
  final Future<void> Function(AuthSession) onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _phoneCtrl = TextEditingController(text: '13800138000');
  final TextEditingController _passwordCtrl = TextEditingController(text: '123456');
  final TextEditingController _codeCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _setError(String? message) {
    if (mounted) {
      setState(() {
        _error = message;
      });
    }
  }

  Future<void> _loginWithPassword() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.authService.loginWithPassword(_phoneCtrl.text.trim(), _passwordCtrl.text.trim());
      await widget.onLogin(session);
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loginWithCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.authService.loginWithCode(_phoneCtrl.text.trim(), _codeCtrl.text.trim());
      await widget.onLogin(session);
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendCode() async {
    if (_secondsLeft > 0) return;
    setState(() {
      _error = null;
      _secondsLeft = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _secondsLeft = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _secondsLeft -= 1;
          });
        }
      }
    });
    try {
      await widget.authService.sendCode(_phoneCtrl.text.trim());
    } catch (e) {
      _setError(e.toString());
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _secondsLeft = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: '密码登录'), Tab(text: '验证码登录')],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPasswordForm(),
                  _buildCodeForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return _FormContainer(
      loading: _loading,
      children: [
        _phoneField(),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordCtrl,
          decoration: const InputDecoration(labelText: '密码'),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _loginWithPassword,
          child: _loading ? const CircularProgressIndicator() : const Text('登录'),
        ),
      ],
    );
  }

  Widget _buildCodeForm() {
    return _FormContainer(
      loading: _loading,
      children: [
        _phoneField(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeCtrl,
                decoration: const InputDecoration(labelText: '验证码'),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: (_loading || _secondsLeft > 0) ? null : _sendCode,
              child: Text(_secondsLeft > 0 ? '重试(${_secondsLeft}s)' : '获取验证码'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _loginWithCode,
          child: _loading ? const CircularProgressIndicator() : const Text('登录'),
        ),
      ],
    );
  }

  Widget _phoneField() {
    return TextField(
      controller: _phoneCtrl,
      decoration: const InputDecoration(labelText: '手机号'),
      keyboardType: TextInputType.phone,
    );
  }
}

class _FormContainer extends StatelessWidget {
  const _FormContainer({required this.children, required this.loading});

  final List<Widget> children;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AbsorbPointer(
        absorbing: loading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
