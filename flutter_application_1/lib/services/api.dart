import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Api {
  // Determine baseUrl depending on platform:
  // - Web runs in browser and should call localhost
  // - Android emulator should use 10.0.2.2 to reach host machine
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000';
  }

  static Future<http.Response> register(
    String username,
    String email,
    String phone,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    return res;
  }

  // overload with phone
  static Future<http.Response> registerWithPhone(
    String email,
    String password,
    String username,
    String? phone,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final body = {
      'username': username,
      'email': email,
      'password': password,
      'phone': phone ?? '',
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return res;
  }

  static Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return res;
  }

  static Future<http.Response> getAdminUsers() async {
    final url = Uri.parse('$baseUrl/admin/users');
    final res = await http.get(url);
    return res;
  }

  static Future<http.Response> getAdminStats() async {
    final url = Uri.parse('$baseUrl/admin/stats');
    final res = await http.get(url);
    return res;
  }

  static Future<http.Response> getAdminUsersWithQuery([String? q]) async {
    final uri = Uri.parse('$baseUrl/admin/users');
    final url = q != null && q.isNotEmpty
        ? uri.replace(queryParameters: {'q': q})
        : uri;
    final res = await http.get(url);
    return res;
  }

  static Future<http.Response> createUser(Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/admin/users');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return res;
  }

  static Future<http.Response> updateUser(
    int id,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl/admin/users/$id');
    final res = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return res;
  }

  static Future<http.Response> deleteUser(int id) async {
    final url = Uri.parse('$baseUrl/admin/users/$id');
    final res = await http.delete(url);
    return res;
  }
}
