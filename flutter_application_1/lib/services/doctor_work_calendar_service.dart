import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/doctor_work_calendar_model.dart';
import 'api.dart';

class DoctorWorkCalendarService {
  static String get baseUrl => '${Api.baseUrl}/doctor-work-schedules';
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'jwt');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Lấy lịch làm việc cho Calendar bác sĩ
  static Future<List<DoctorCalendarItem>> getDoctorCalendar() async {
    final url = Uri.parse('$baseUrl/calendar');
    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => DoctorCalendarItem.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải lịch làm việc của bác sĩ: ${response.statusCode}');
    }
  }
}
