import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'admin/dashboard.dart';
import 'login.dart';
import 'doctor/dashboard.dart';
import 'patient/dashboard.dart';

void main() {
  runApp(const DentalApp());
}

class DentalApp extends StatelessWidget {
  const DentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dental Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      routes: {
        '/admin': (_) => const AdminDashboard(),
        '/doctor': (_) => const DoctorDashboard(),
        '/patient': (_) => const PatientDashboard(),
        '/login': (_) => const LoginPage(),
      },
      home: const LoginPage(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _storage = const FlutterSecureStorage();
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await _storage.read(key: 'jwt');
    final role = await _storage.read(key: 'role');
    setState(() {
      _role = token == null ? null : (role ?? 'user');
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_role == null) return const LoginPage();
    if (_role == 'admin') return const AdminDashboard();
    if (_role == 'doctor') return const DoctorDashboard();
    return const PatientDashboard();
  }
}
