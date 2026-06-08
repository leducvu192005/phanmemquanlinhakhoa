import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';
import '../models/leave_request_model.dart';

class LeaveRequestService {
  static String get baseUrl => "${Api.baseUrl}/leave-requests";
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers() async {
    String? token;
    try {
      token = await _storage.read(key: 'jwt');
    } catch (e) {
      // Safely ignore secure storage read errors (e.g. on web or unsupported environments)
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Gửi yêu cầu nghỉ phép
  static Future<LeaveRequest> createRequest(Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/");
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return LeaveRequest.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(decoded['detail'] ?? "Không thể gửi yêu cầu nghỉ phép");
    }
  }

  // 2. Lấy danh sách yêu cầu nghỉ phép (có bộ lọc và tùy chọn lọc của riêng mình)
  static Future<List<LeaveRequest>> getRequests({String? status, bool own = false}) async {
    String query = "";
    if (status != null && status.isNotEmpty) {
      query += "status=$status";
    }
    if (own) {
      if (query.isNotEmpty) query += "&";
      query += "own=true";
    }
    
    Uri url = query.isNotEmpty
        ? Uri.parse("$baseUrl/?$query")
        : Uri.parse("$baseUrl/");
    
    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => LeaveRequest.fromJson(e)).toList();
    } else {
      throw Exception("Không thể tải danh sách yêu cầu nghỉ phép");
    }
  }

  // 3. Lấy thống kê
  static Future<Map<String, int>> getStats({bool own = false}) async {
    Uri url = own ? Uri.parse("$baseUrl/stats?own=true") : Uri.parse("$baseUrl/stats");
    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 0));
    } else {
      throw Exception("Không thể tải thống kê nghỉ phép");
    }
  }

  // 4. Bác sĩ hoặc Staff tự hủy yêu cầu của mình
  static Future<LeaveRequest> cancelRequest(int requestId) async {
    final url = Uri.parse("$baseUrl/$requestId/cancel");
    final response = await http.put(url, headers: await _headers());

    if (response.statusCode == 200) {
      return LeaveRequest.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(decoded['detail'] ?? "Hủy yêu cầu nghỉ phép thất bại");
    }
  }

  // 5. Staff duyệt yêu cầu của Bác sĩ / Staff khác
  static Future<LeaveRequest> approveRequest(int requestId) async {
    final url = Uri.parse("$baseUrl/$requestId/approve");
    final response = await http.put(url, headers: await _headers());

    if (response.statusCode == 200) {
      return LeaveRequest.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(decoded['detail'] ?? "Phê duyệt yêu cầu thất bại");
    }
  }

  // 6. Staff từ chối yêu cầu kèm lý do
  static Future<LeaveRequest> rejectRequest(int requestId, String reason) async {
    final url = Uri.parse("$baseUrl/$requestId/reject");
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode({'reject_reason': reason}),
    );

    if (response.statusCode == 200) {
      return LeaveRequest.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(decoded['detail'] ?? "Từ chối yêu cầu thất bại");
    }
  }
}
