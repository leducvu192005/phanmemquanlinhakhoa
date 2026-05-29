import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/api.dart';
import 'dart:convert';
import 'package:flutter_application_1/admin/layout_admin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _loginForm = GlobalKey<FormState>();
  final _regForm = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _loading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_loginForm.currentState!.validate()) return;

    setState(() => _loading = true);

    final res = await Api.login(_emailCtrl.text.trim(), _passwordCtrl.text);

    setState(() => _loading = false);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      final token = body['access_token'];
      final role = body['role'] ?? 'user';
      print("TOKEN LOGIN: $token");
      print("ROLE LOGIN: $role");
      await _storage.write(key: 'jwt', value: token);
      await _storage.write(key: 'role', value: role);

      if (role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminLayout()),
        );
      } else if (role == 'doctor') {
        Navigator.of(context).pushReplacementNamed('/doctor');
      } else {
        Navigator.of(context).pushReplacementNamed('/patient');
      }
    } else {
      String msg = 'Lỗi: ${res.statusCode}';

      try {
        final body = jsonDecode(res.body);
        msg = body['detail'] ?? body['message'] ?? msg;
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _doRegister() async {
    if (!_regForm.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await Api.registerWithPhone(
      _regEmailCtrl.text.trim(),
      _regPasswordCtrl.text,
      _nameCtrl.text.trim(),
      _phoneCtrl.text.trim(),
    );
    setState(() => _loading = false);
    if (res.statusCode == 201) {
      // auto-login after successful register
      final loginRes = await Api.login(
        _regEmailCtrl.text.trim(),
        _regPasswordCtrl.text,
      );
      if (loginRes.statusCode == 200) {
        final body = jsonDecode(loginRes.body);
        final token = body['access_token'];
        final role = body['role'] ?? 'user';
        await _storage.write(key: 'jwt', value: token);
        await _storage.write(key: 'role', value: role);
        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminLayout()),
          );
        } else if (role == 'doctor') {
          Navigator.of(context).pushReplacementNamed('/doctor');
        } else {
          Navigator.of(context).pushReplacementNamed('/patient');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công. Vui lòng đăng nhập.'),
          ),
        );
        _tabController.index = 0;
      }
    } else {
      String msg = 'Lỗi: ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        msg = body['detail'] ?? body['message'] ?? msg;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _leftPanel(BuildContext c) {
    return Container(
      color: const Color(0xFF0EA5E9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào mừng đến với',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nha Khoa Sáng Răng',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nơi nụ cười của bạn được chăm sóc với công nghệ hiện đại và đội ngũ bác sĩ giàu kinh nghiệm',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              _statItem('10+', 'Năm kinh nghiệm'),
              const SizedBox(width: 24),
              _statItem('5000+', 'Bệnh nhân hài lòng'),
              const SizedBox(width: 24),
              _statItem('15+', 'Bác sĩ chuyên nghiệp'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String v, String t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        v,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      Text(t, style: TextStyle(color: Colors.white.withOpacity(0.9))),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 720),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // LEFT PANEL 50%
                if (isWide) Expanded(flex: 1, child: _leftPanel(context)),

                // RIGHT PANEL 50%
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),

                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cut,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Nha Khoa Sáng Răng',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Hệ thống quản lý phòng khám nha khoa',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.black54,
                          tabs: const [
                            Tab(text: 'Đăng Nhập'),
                            Tab(text: 'Đăng Ký'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // LOGIN
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _loginForm,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _emailCtrl,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.email),
                                        labelText: 'Email',
                                        hintText: 'example@email.com',
                                      ),
                                      validator: (v) =>
                                          (v == null || !v.contains('@'))
                                          ? 'Email không hợp lệ'
                                          : null,
                                    ),

                                    const SizedBox(height: 12),

                                    TextFormField(
                                      controller: _passwordCtrl,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.lock),
                                        labelText: 'Mật khẩu',
                                      ),
                                      validator: (v) =>
                                          (v == null || v.length < 6)
                                          ? 'Mật khẩu >= 6 ký tự'
                                          : null,
                                    ),

                                    const Spacer(),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: _loading
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : ElevatedButton(
                                              onPressed: _doLogin,
                                              child: const Text('Đăng Nhập'),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // REGISTER
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Form(
                                  key: _regForm,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _nameCtrl,
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.person),
                                          labelText: 'Họ và tên',
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      TextFormField(
                                        controller: _regEmailCtrl,
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.email),
                                          labelText: 'Email',
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      TextFormField(
                                        controller: _phoneCtrl,
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.phone),
                                          labelText: 'Số điện thoại',
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      TextFormField(
                                        controller: _regPasswordCtrl,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.lock),
                                          labelText: 'Mật khẩu',
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: _loading
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : ElevatedButton(
                                                onPressed: _doRegister,
                                                child: const Text('Đăng Ký'),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
