import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/doctor_work_schedule.dart';

class DoctorWorkScheduleService {
  final String baseUrl = "http://127.0.0.1:8000";

  // =========================
  // GET ALL
  // =========================
  Future<List<DoctorWorkSchedule>> getAll() async {
    final res = await http.get(Uri.parse("$baseUrl/doctor-work-schedules/"));

    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      return data.map((e) => DoctorWorkSchedule.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load schedules");
    }
  }

  // =========================
  // GET OPEN (ca trống)
  // =========================
  Future<List<DoctorWorkSchedule>> getOpen() async {
    final res = await http.get(
      Uri.parse("$baseUrl/doctor-work-schedules/status/open/list"),
    );

    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      return data.map((e) => DoctorWorkSchedule.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load open schedules");
    }
  }

  // =========================
  // GET BY ID
  // =========================
  Future<DoctorWorkSchedule> getById(int id) async {
    final res = await http.get(Uri.parse("$baseUrl/doctor-work-schedules/$id"));

    if (res.statusCode == 200) {
      return DoctorWorkSchedule.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("Not found");
    }
  }

  // =========================
  // CREATE (Admin tạo ca)
  // =========================
  Future<void> create(DoctorWorkSchedule schedule) async {
    final res = await http.post(
      Uri.parse("$baseUrl/doctor-work-schedules/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(schedule.toJson()),
    );

    if (res.statusCode != 200) {
      throw Exception("Create failed");
    }
  }

  // =========================
  // UPDATE
  // =========================
  Future<void> update(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse("$baseUrl/doctor-work-schedules/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception("Update failed");
    }
  }

  // =========================
  // DELETE
  // =========================
  Future<void> delete(int id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/doctor-work-schedules/$id"),
    );

    if (res.statusCode != 200) {
      throw Exception("Delete failed");
    }
  }

  // =========================
  // REGISTER (bác sĩ đăng ký)
  // =========================
  Future<void> register(int scheduleId, int doctorId) async {
    final res = await http.put(
      Uri.parse(
        "$baseUrl/doctor-work-schedules/$scheduleId/register?doctor_id=$doctorId",
      ),
    );

    if (res.statusCode != 200) {
      throw Exception("Register failed");
    }
  }

  // =========================
  // GET BY DOCTOR
  // =========================
  Future<List<DoctorWorkSchedule>> getByDoctor(int doctorId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/doctor-work-schedules/doctor/$doctorId"),
    );

    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      return data.map((e) => DoctorWorkSchedule.fromJson(e)).toList();
    } else {
      throw Exception("Failed");
    }
  }
}
