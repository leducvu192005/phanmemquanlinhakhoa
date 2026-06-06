import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';
import '../models/patient_model.dart';

class PatientService {
  static String get baseUrl => "${Api.baseUrl}/patients";
  static String get adminBaseUrl => "${Api.baseUrl}/admin/patients";
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'jwt');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =========================
  // GET MY PROFILE (Patient /me)
  // =========================
  static Future<Patient> getMyProfile() async {
    final url = Uri.parse("$baseUrl/me");
    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Patient.fromJson(data);
    } else {
      throw Exception("Không thể tải hồ sơ bệnh án cá nhân: ${response.statusCode}");
    }
  }

  // =========================
  // UPDATE MY PROFILE
  // =========================
  static Future<Patient> updateMyProfile(Map<String, dynamic> payload) async {
    final url = Uri.parse("$baseUrl/me");
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Patient.fromJson(data);
    } else {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(decoded['detail'] ?? "Không thể cập nhật hồ sơ cá nhân");
    }
  }

  // =========================
  // GET ALL + SEARCH
  // =========================
  Future<List<Patient>> getPatients({String? query}) async {
    final uri = Uri.parse(adminBaseUrl).replace(
      queryParameters: query == null || query.isEmpty ? null : {"q": query},
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data as List).map((item) => Patient.fromJson(item)).toList();
    }

    throw Exception("Error ${response.statusCode}: ${response.body}");
  }

  // =========================
  // GET DETAIL
  // =========================
  Future<Patient> getPatientById(String id) async {
    final response = await http.get(Uri.parse("$adminBaseUrl/$id"), headers: await _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Patient.fromJson(data);
    } else {
      throw Exception("Patient not found");
    }
  }

  // =========================
  // CREATE
  // =========================
  Future<Patient> createPatient(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(adminBaseUrl),
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Patient.fromJson(data);
    } else {
      throw Exception("Failed to create patient: ${response.body}");
    }
  }

  // =========================
  // UPDATE
  // =========================
  Future<Patient> updatePatient(String id, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse("$adminBaseUrl/$id"),
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Patient.fromJson(data);
    } else {
      throw Exception("Failed to update patient");
    }
  }

  // =========================
  // DELETE
  // =========================
  Future<void> deletePatient(String id) async {
    final response = await http.delete(Uri.parse("$adminBaseUrl/$id"), headers: await _headers());

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete patient");
    }
  }
}
