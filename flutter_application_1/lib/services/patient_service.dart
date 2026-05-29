import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/patient_model.dart';

class PatientService {
  static const String baseUrl = "http://127.0.0.1:8000/admin/patients";

  // =========================
  // GET ALL + SEARCH
  // =========================
  Future<List<Patient>> getPatients({String? query}) async {
    final uri = Uri.parse(
      query == null || query.isEmpty ? baseUrl : "$baseUrl?q=$query",
    );

    final response = await http.get(uri);

    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      return (data as List).map((item) => Patient.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load patients");
    }
  }

  // =========================
  // GET DETAIL
  // =========================
  Future<Patient> getPatientById(int id) async {
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
  Future<Patient> updatePatient(int id, Map<String, dynamic> payload) async {
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
  Future<void> deletePatient(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete patient");
    }
  }
}
