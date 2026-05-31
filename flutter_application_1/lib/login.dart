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
  bool _obscureLoginPass = true;
  bool _obscureRegPass = true;
  late TabController _tabController;

  // Theme màu sắc chủ đạo của phòng khám hiện đại
  final Color primaryColor = const Color(
    0xFF0F766E,
  ); // Deep Teal sạch sẽ, chuyên nghiệp
  final Color accentColor = const Color(
    0xFF2DD4BF,
  ); // Light Teal tạo điểm nhấn tươi sáng

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
      await _storage.write(key: 'jwt', value: token);
      await _storage.write(key: 'role', value: role);

      if (!mounted) return;
      if (role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminLayout()),
        );
      } else if (role == 'doctor') {
        Navigator.of(context).pushReplacementNamed('/doctor');
      } else if (role == 'staff') {
        Navigator.of(context).pushReplacementNamed('/staff');
      } else {
        Navigator.of(context).pushReplacementNamed('/staff');
      }
    } else {
      String msg = 'Lỗi: ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        msg = body['detail'] ?? body['message'] ?? msg;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

        if (!mounted) return;
        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminLayout()),
          );
        } else if (role == 'doctor') {
          Navigator.of(context).pushReplacementNamed('/doctor');
        } else if (role == 'staff') {
          Navigator.of(context).pushReplacementNamed('/staff');
        } else {
          Navigator.of(context).pushReplacementNamed('/patient');
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công. Vui lòng đăng nhập.'),
            behavior: SnackBarBehavior.floating,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _leftPanel(BuildContext c) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.85)],
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chào mừng đến với',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nha Khoa Sáng Răng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nơi nụ cười của bạn được chăm sóc với công nghệ hiện đại và đội ngũ bác sĩ giàu kinh nghiệm.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem('10+', 'Năm kinh nghiệm'),
              _statItem('5000+', 'Bệnh nhân tin tưởng'),
              _statItem('15+', 'Bác sĩ chuyên khoa'),
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
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        t,
        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Nền xám nhạt tinh tế xu hướng hiện đại
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 700),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  if (isWide) Expanded(flex: 1, child: _leftPanel(context)),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand Identity
                          // Thay thế đoạn hiển thị Brand Identity cũ bằng đoạn này:
                          Center(
                            child: Column(
                              children: [
                                // LOGO MỚI TỪ ASSETS
                                Container(
                                  width:
                                      170, // Tăng nhẹ kích thước để ảnh minh họa rõ ràng hơn
                                  height: 170,
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .transparent, // Giữ trong suốt hoặc đổi thành màu bạn thích
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ), // Bo tròn nhẹ cho ảnh
                                    child: Image.asset(
                                      'assets/images/bubble-gum-online-doctor-consultation 2.png',
                                      fit: Alignment.center == null
                                          ? BoxFit.cover
                                          : BoxFit
                                                .contain, // Giữ trọn vẹn tỷ lệ ảnh minh họa
                                      errorBuilder: (context, error, stackTrace) {
                                        // Trường hợp load ảnh lỗi (sai đường dẫn), hiển thị icon dự phòng
                                        return Icon(
                                          Icons.medical_services,
                                          color: primaryColor,
                                          size: 32,
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  'Nha Khoa Sáng Răng',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Hệ thống quản lý phòng khám chuyên nghiệp',
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Custom TabBar Decoration
                          Container(
                            height: 66,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              labelColor: primaryColor,
                              unselectedLabelColor: Colors.black45,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              tabs: const [
                                Tab(text: 'Đăng Nhập'),
                                Tab(text: 'Đăng Ký'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Form Tab Views
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // LOGIN FORM
                                Form(
                                  key: _loginForm,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _emailCtrl,
                                        decoration: _buildInputDecoration(
                                          label: 'Email của bạn',
                                          icon: Icons.email_outlined,
                                        ),
                                        validator: (v) =>
                                            (v == null || !v.contains('@'))
                                            ? 'Email không hợp lệ'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passwordCtrl,
                                        obscureText: _obscureLoginPass,
                                        decoration: _buildInputDecoration(
                                          label: 'Mật khẩu',
                                          icon: Icons.lock_outline,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureLoginPass
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.black54,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureLoginPass =
                                                  !_obscureLoginPass,
                                            ),
                                          ),
                                        ),
                                        validator: (v) =>
                                            (v == null || v.length < 6)
                                            ? 'Mật khẩu phải từ 6 ký tự trở lên'
                                            : null,
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: _loading
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: primaryColor,
                                                    ),
                                              )
                                            : ElevatedButton(
                                                onPressed: _doLogin,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: const Text(
                                                  'Đăng Nhập',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                // REGISTER FORM
                                SingleChildScrollView(
                                  child: Form(
                                    key: _regForm,
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _nameCtrl,
                                          decoration: _buildInputDecoration(
                                            label: 'Họ và tên',
                                            icon: Icons.person_outline,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _regEmailCtrl,
                                          decoration: _buildInputDecoration(
                                            label: 'Email',
                                            icon: Icons.email_outlined,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _phoneCtrl,
                                          decoration: _buildInputDecoration(
                                            label: 'Số điện thoại',
                                            icon: Icons.phone_android_outlined,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _regPasswordCtrl,
                                          obscureText: _obscureRegPass,
                                          decoration: _buildInputDecoration(
                                            label: 'Mật khẩu',
                                            icon: Icons.lock_outline,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureRegPass
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.black54,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscureRegPass =
                                                    !_obscureRegPass,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: _loading
                                              ? Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: primaryColor,
                                                      ),
                                                )
                                              : ElevatedButton(
                                                  onPressed: _doRegister,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        primaryColor,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: const Text(
                                                    'Tạo tài khoản',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
