import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api.dart';
import 'user_role_model.dart';

class RoleManagementService {
  static const _storage = FlutterSecureStorage();

  static Future<List<UserRoleModel>> fetchUsers() async {
    final token = await _storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('${Api.baseUrl}/users/'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded.map((e) => UserRoleModel.fromJson(e)).toList();
    } else {
      throw Exception('Không thể lấy danh sách tài khoản: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<UserRoleModel> updateUserRole(int userId, String role) async {
    final token = await _storage.read(key: 'jwt');
    final response = await http.put(
      Uri.parse('${Api.baseUrl}/users/$userId/role'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'role': role.toLowerCase(),
      }),
    );

    if (response.statusCode == 200) {
      return UserRoleModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      // Decode error details to show user-friendly messages
      String msg = 'Cập nhật phân quyền thất bại';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        msg = body['detail'] ?? body['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
