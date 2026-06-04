import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  static String get baseUrl => Api.baseUrl;

  static const _storage = FlutterSecureStorage();


  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'jwt');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Lấy lịch hẹn trực ngày hôm nay của bác sĩ đăng nhập
  static Future<List<Appointment>> getDoctorTodayAppointments() async {
    final url = Uri.parse('$baseUrl/appointments/doctor/today');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => Appointment.fromJson(e)).toList();
      } else {
        throw Exception('Lỗi khi lấy lịch hẹn: ${response.statusCode}');
      }
    } catch (e) {
      print('AppointmentService Error: $e');
      rethrow;
    }
  }

  // Cập nhật trạng thái ca khám
  static Future<Appointment> updateStatus(String id, String status) async {
    final url = Uri.parse('$baseUrl/appointments/$id/status?status_update=$status');
    final response = await http.patch(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Appointment.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể cập nhật trạng thái lịch hẹn');
    }
  }
}
