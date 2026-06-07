import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/doctor_work_schedule.dart';
import 'api.dart';

class DoctorWorkScheduleService {
  String get baseUrl => Api.baseUrl;

  Future<List<DoctorWorkSchedule>> getScheduleByRange({
    String? doctorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    String url =
        "$baseUrl/doctor-work-schedules/range?start_date=$startStr&end_date=$endStr";
    if (doctorId != null && doctorId.isNotEmpty) {
      url += "&doctor_id=$doctorId";
    }

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => DoctorWorkSchedule.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load schedules by range");
    }
  }

  Future<Map<String, List<DoctorWorkSchedule>>> getMonthlyOverview({
    required int year,
    required int month,
    String? doctorId,
  }) async {
    String url =
        "$baseUrl/doctor-work-schedules/monthly?year=$year&month=$month";
    if (doctorId != null && doctorId.isNotEmpty) {
      url += "&doctor_id=$doctorId";
    }

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));

      return data.map((key, value) {
        List listJson = value;
        return MapEntry(
          key,
          listJson.map((e) => DoctorWorkSchedule.fromJson(e)).toList(),
        );
      });
    } else {
      throw Exception("Failed to load monthly overview");
    }
  }

  Future<List<DoctorWorkSchedule>> getAll() async {
    final res = await http.get(Uri.parse("$baseUrl/doctor-work-schedules/"));

    if (res.statusCode == 200) {
      List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => DoctorWorkSchedule.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load schedules");
    }
  }

  Future<List<DoctorWorkSchedule>> getOpen() async {
    final res = await http.get(
      Uri.parse("$baseUrl/doctor-work-schedules/status/open/list"),
    );

    if (res.statusCode == 200) {
      List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => DoctorWorkSchedule.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load open schedules");
    }
  }

  Future<DoctorWorkSchedule> getById(String id) async {
    final res = await http.get(Uri.parse("$baseUrl/doctor-work-schedules/$id"));

    if (res.statusCode == 200) {
      return DoctorWorkSchedule.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)),
      );
    } else {
      throw Exception("Not found");
    }
  }

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

  Future<void> update(String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse("$baseUrl/doctor-work-schedules/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception("Update failed");
    }
  }

  Future<void> delete(String id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/doctor-work-schedules/$id"),
    );

    if (res.statusCode != 200) {
      throw Exception("Delete failed");
    }
  }

  Future<void> register(String scheduleId, String doctorId) async {
    final res = await http.put(
      Uri.parse(
        "$baseUrl/doctor-work-schedules/$scheduleId/register?doctor_id=$doctorId",
      ),
    );

    if (res.statusCode != 200) {
      throw Exception("Register failed");
    }
  }

  Future<void> unregister(String scheduleId) async {
    final res = await http.put(
      Uri.parse("$baseUrl/doctor-work-schedules/$scheduleId/unregister"),
    );

    if (res.statusCode != 200) {
      throw Exception("Unregister failed");
    }
  }

  Future<List<DoctorWorkSchedule>> getByDoctor(String doctorId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/doctor-work-schedules/doctor/$doctorId"),
    );

    if (res.statusCode == 200) {
      List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => DoctorWorkSchedule.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load doctor schedules");
    }
  }
}
