import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/patient_model.dart';

class PatientService {
  static const String baseUrl = "http://127.0.0.1:8000/admin/patients";

  // =========================
  // GET ALL + SEARCH
  // =========================
  Future<List<Patient>> getPatients({String? query}) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: query == null || query.isEmpty ? null : {"q": query},
    );

    final response = await http.get(uri);

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
    final response = await http.get(Uri.parse("$baseUrl/$id"));

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
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
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
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
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
    final response = await http.delete(Uri.parse("$baseUrl/$id"));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete patient");
    }
  }
}
