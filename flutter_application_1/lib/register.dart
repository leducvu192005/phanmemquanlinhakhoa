import 'package:flutter/material.dart';
import 'services/api.dart';
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await Api.register(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _nameCtrl.text.trim(),
    );
    setState(() => _loading = false);
    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công. Vui lòng đăng nhập.'),
        ),
      );
      Navigator.of(context).pop();
    } else {
      String msg = 'Lỗi: ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        msg = body['detail'] ?? body['message'] ?? msg;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
                validator: (v) => (v == null || v.isEmpty) ? 'Nhập tên' : null,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Email không hợp lệ'
                    : null,
              ),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mật khẩu >= 6 ký tự' : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Đăng ký'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
