import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';
import '../models/user_model.dart';

class UserService {
  static String get baseUrl => "${Api.baseUrl}/auth"; // Backend '/auth/me' endpoints
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers() async {
    String? token;
    try {
      token = await _storage.read(key: 'jwt');
    } catch (_) {}
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Lấy thông tin tài khoản hiện tại
  static Future<UserModel> getMyProfile() async {
    final url = Uri.parse("$baseUrl/me");
    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception("Không thể tải thông tin hồ sơ");
    }
  }

  // Cập nhật thông tin tài khoản hiện tại
  static Future<UserModel> updateMyProfile(Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/me");
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(decoded['detail'] ?? "Cập nhật hồ sơ thất bại");
    }
  }
}
