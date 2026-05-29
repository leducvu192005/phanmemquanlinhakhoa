import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/doctor_model.dart';

class DoctorService {
  // =========================
  // BASE URL
  // =========================
  static const String baseUrl = "http://127.0.0.1:8000/doctors";

  // Android emulator:
  // 10.0.2.2 = localhost

  final headers = {"Content-Type": "application/json"};

  // =========================
  // GET ALL DOCTORS
  // =========================
  Future<List<Doctor>> getDoctors({String? query}) async {
    Uri url;

    if (query != null && query.isNotEmpty) {
      url = Uri.parse("$baseUrl/?q=$query");
    } else {
      url = Uri.parse(baseUrl);
    }

    final response = await http.get(url, headers: headers);

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
      headers: headers,
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
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Create failed: ${utf8.decode(response.bodyBytes)}");
    }
  }

  // =========================
  // UPDATE DOCTOR
  // =========================
  Future<void> updateDoctor(String id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
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
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("Delete failed: ${response.body}");
    }
  }
}
