import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';

import 'api.dart';
import '../models/doctor_model.dart';

class DoctorService {
  static String get baseUrl => "${Api.baseUrl}/doctors";
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers() async {
    String? token;
    try {
      token = await _storage.read(key: 'jwt');
    } catch (_) {
      // Safely ignore storage issues
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =========================
  // GET CURRENT DOCTOR PROFILE
  // =========================
  Future<Doctor> getMyProfile() async {
    final url = Uri.parse("$baseUrl/me");
    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      return Doctor.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception("Không thể tải hồ sơ bác sĩ: ${response.statusCode}");
    }
  }

  // =========================
  // UPDATE CURRENT DOCTOR PROFILE
  // =========================
  Future<Doctor> updateMyProfile(Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/me");
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Doctor.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(
        "Cập nhật hồ sơ thất bại: ${utf8.decode(response.bodyBytes)}",
      );
    }
  }

  // =========================
  // UPLOAD AVATAR (Hỗ trợ đa nền tảng)
  // =========================
  Future<String> uploadAvatar(List<int> bytes, String filename) async {
    final url = Uri.parse("$baseUrl/me/avatar");
    final token = await _storage.read(key: 'jwt');

    final request = http.MultipartRequest('POST', url);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Xác định content type dựa trên đuôi file
    String ext = filename.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (ext == 'png') mimeType = 'image/png';
    if (ext == 'webp') mimeType = 'image/webp';
    if (ext == 'gif') mimeType = 'image/gif';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final resBody = jsonDecode(utf8.decode(response.bodyBytes));
      return resBody['avatar_url']; // Trả về link ảnh tương đối
    } else {
      String msg = 'Tải ảnh lên thất bại';
      try {
        final resBody = jsonDecode(utf8.decode(response.bodyBytes));
        msg = resBody['detail'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // =========================
  // GET ALL DOCTORS
  // =========================
  Future<List<Doctor>> getDoctors({String? query}) async {
    Uri url = query != null && query.isNotEmpty
        ? Uri.parse("$baseUrl/?q=$query")
        : Uri.parse(baseUrl);

    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Doctor.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load doctors");
    }
  }

  // =========================
  // GET DOCTOR DETAIL
  // =========================
  Future<Doctor> getDoctorDetail(String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Doctor.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception("Doctor not found");
    }
  }

  // =========================
  // CREATE DOCTOR
  // =========================
  Future<void> createDoctor(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Create failed: ${utf8.decode(response.bodyBytes)}");
    }
  }

  // =========================
  // UPDATE DOCTOR (Admin API)
  // =========================
  Future<void> updateDoctor(String id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("Update failed: ${utf8.decode(response.bodyBytes)}");
    }
  }

  // =========================
  // DELETE DOCTOR
  // =========================
  Future<void> deleteDoctor(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception("Delete failed: ${response.body}");
    }
  }
}
