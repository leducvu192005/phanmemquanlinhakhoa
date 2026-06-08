import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  static String get baseUrl => Api.baseUrl;
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

  // Lấy lịch hẹn trực ngày hôm nay của bác sĩ đăng nhập
  static Future<List<Appointment>> getDoctorTodayAppointments() async {
    final url = Uri.parse('$baseUrl/appointments/doctor/today');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => Appointment.fromJson(e)).toList();
      } else {
        throw Exception('Lỗi khi lấy lịch hẹn hôm nay của bác sĩ: ${response.statusCode}');
      }
    } catch (e) {
      print('AppointmentService Error: $e');
      rethrow;
    }
  }

  // Lấy danh sách lịch hẹn của chính bệnh nhân đang đăng nhập
  static Future<List<Appointment>> getPatientAppointments() async {
    final url = Uri.parse('$baseUrl/appointments/patient/me');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => Appointment.fromJson(e)).toList();
      } else {
        throw Exception('Lỗi khi lấy lịch hẹn bệnh nhân: ${response.statusCode}');
      }
    } catch (e) {
      print('AppointmentService Error: $e');
      rethrow;
    }
  }

  // Lấy toàn bộ lịch hẹn (hỗ trợ tìm kiếm, lọc cho nhân viên)
  static Future<List<Appointment>> getAllAppointments({
    String? doctorId,
    String? patientId,
    String? dateStr,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (doctorId != null && doctorId.isNotEmpty) queryParams['doctor_id'] = doctorId;
    if (patientId != null && patientId.isNotEmpty) queryParams['patient_id'] = patientId;
    if (dateStr != null && dateStr.isNotEmpty) queryParams['appointment_date'] = dateStr;
    if (status != null && status.isNotEmpty) queryParams['status_filter'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/appointments/').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => Appointment.fromJson(e)).toList();
      } else {
        throw Exception('Lỗi khi lấy danh sách lịch hẹn: ${response.statusCode}');
      }
    } catch (e) {
      print('AppointmentService Error: $e');
      rethrow;
    }
  }

  // Lấy thống kê lịch hẹn
  static Future<Map<String, dynamic>> getStatsSummary() async {
    final url = Uri.parse('$baseUrl/appointments/stats/summary');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Lỗi khi lấy thống kê: ${response.statusCode}');
      }
    } catch (e) {
      print('AppointmentService Error: $e');
      rethrow;
    }
  }

  // Lấy hàng chờ khám hôm nay
  static Future<List<Appointment>> getTodayQueue() async {
    final url = Uri.parse('$baseUrl/appointments/queue/today');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => Appointment.fromJson(e)).toList();
      } else {
        throw Exception('Lỗi khi lấy hàng chờ: ${response.statusCode}');
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
      throw Exception('Không thể cập nhật trạng thái lịch hẹn: ${response.body}');
    }
  }

  // Bệnh nhân/Nhân viên hủy lịch hẹn
  static Future<Appointment> cancelAppointment(String id, {String? reason}) async {
    final queryParams = reason != null && reason.isNotEmpty ? {'reason': reason} : null;
    final url = Uri.parse('$baseUrl/appointments/$id/cancel').replace(queryParameters: queryParams);
    
    final response = await http.put(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Appointment.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể hủy lịch khám: ${response.body}');
    }
  }

  // Đổi giờ khám/ngày khám (Nhân viên)
  static Future<Appointment> rescheduleAppointment(String id, DateTime newTime) async {
    final url = Uri.parse('$baseUrl/appointments/$id/reschedule?new_time=${newTime.toUtc().toIso8601String()}');
    final response = await http.patch(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Appointment.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể đổi giờ khám: ${response.body}');
    }
  }

  // Chuyển bác sĩ khám (Nhân viên)
  static Future<Appointment> reassignDoctor(String id, String newDoctorId) async {
    final url = Uri.parse('$baseUrl/appointments/$id/reassign?new_doctor_id=$newDoctorId');
    final response = await http.patch(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Appointment.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể chuyển đổi bác sĩ: ${response.body}');
    }
  }

  // Đặt lại lịch hẹn từ thông tin cũ (Bệnh nhân)
  static Future<Appointment> rebookAppointment(String id, DateTime newTime, {String? reason}) async {
    final queryParams = <String, String>{
      'appointment_time': newTime.toUtc().toIso8601String(),
    };
    if (reason != null && reason.isNotEmpty) {
      queryParams['reason'] = reason;
    }
    
    final url = Uri.parse('$baseUrl/appointments/$id/rebook').replace(queryParameters: queryParams);
    final response = await http.post(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 201) {
      return Appointment.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể đặt lại lịch khám: ${response.body}');
    }
  }

  // Xem chi tiết lịch khám bằng ID
  static Future<Appointment> getAppointmentById(String id) async {
    final url = Uri.parse('$baseUrl/appointments/$id');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      return Appointment.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không tìm thấy chi tiết lịch hẹn: ${response.statusCode}');
    }
  }

  // Đặt lịch khám mới (Bệnh nhân)
  static Future<Appointment> createAppointment({
    required String patientId,
    required String doctorId,
    required String serviceId,
    required DateTime appointmentTime,
    required String reason,
  }) async {
    final url = Uri.parse('$baseUrl/appointments/');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'patient_id': int.tryParse(patientId) ?? int.parse(patientId),
        'doctor_id': doctorId,
        'service_id': int.tryParse(serviceId) ?? int.parse(serviceId),
        'appointment_time': appointmentTime.toUtc().toIso8601String(),
        'reason': reason,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Appointment.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể đặt lịch khám: ${response.body}');
    }
  }
}
