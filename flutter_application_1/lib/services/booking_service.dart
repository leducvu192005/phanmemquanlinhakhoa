import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/booking_model.dart';
import 'api.dart';

class BookingService {
  static String get baseUrl => '${Api.baseUrl}/bookings';
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers() async {
    String? token;
    try {
      token = await _storage.read(key: 'jwt');
    } catch (e) {
      // Safely ignore storage read issues
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token != 'null' && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // Đặt lịch khám mới
  static Future<Booking> createBooking({
    required String patientId,
    required String doctorId,
    required String bookingDate,
    required String timeSlot,
    required String symptoms,
    int? scheduleId,
  }) async {
    final url = Uri.parse('$baseUrl/');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'patient_id': int.tryParse(patientId) ?? int.parse(patientId),
        'doctor_id': doctorId,
        'booking_date': bookingDate,
        'time_slot': timeSlot,
        'symptoms': symptoms,
        if (scheduleId != null) 'schedule_id': scheduleId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Booking.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể đặt lịch khám: ${response.body}');
    }
  }

  // Lấy danh sách lịch đặt khám của bệnh nhân đang đăng nhập
  static Future<List<Booking>> getMyBookings() async {
    String? token;
    try {
      token = await _storage.read(key: 'jwt');
    } catch (_) {}
    if (token == null || token == 'null' || token.isEmpty) {
      print("BookingService: Token is null/empty. Skipping getMyBookings.");
      return [];
    }

    final url = Uri.parse('$baseUrl/patient/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => Booking.fromJson(e)).toList();
    } else {
      throw Exception(
        'Không thể lấy danh sách lịch đặt khám: ${response.statusCode}',
      );
    }
  }

  // Hủy đặt lịch khám
  static Future<Booking> cancelBooking(String bookingId) async {
    final url = Uri.parse('$baseUrl/$bookingId/cancel');
    final response = await http.put(url, headers: await _headers());

    if (response.statusCode == 200) {
      return Booking.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể hủy đặt lịch khám: ${response.body}');
    }
  }

  // Xem chi tiết đặt lịch khám bằng ID
  static Future<Booking> getBookingById(String id) async {
    final url = Uri.parse('$baseUrl/$id');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      return Booking.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(
        'Không tìm thấy chi tiết đặt khám: ${response.statusCode}',
      );
    }
  }

  // Lấy tất cả bookings (Staff/Admin)
  static Future<List<Booking>> getAllBookings({
    String? doctorId,
    String? patientId,
    String? dateStr,
    String? status,
    String? search,
  }) async {
    String? token;
    try {
      token = await _storage.read(key: 'jwt');
    } catch (_) {}
    if (token == null || token == 'null' || token.isEmpty) {
      print("BookingService: Token is null/empty. Skipping getAllBookings.");
      return [];
    }

    final queryParams = <String, String>{};
    if (doctorId != null && doctorId.isNotEmpty)
      queryParams['doctor_id'] = doctorId;
    if (patientId != null && patientId.isNotEmpty)
      queryParams['patient_id'] = patientId;
    if (dateStr != null && dateStr.isNotEmpty)
      queryParams['booking_date'] = dateStr;
    if (status != null && status.isNotEmpty)
      queryParams['status_filter'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => Booking.fromJson(e)).toList();
    } else {
      throw Exception(
        'Không thể lấy danh sách đặt khám: ${response.statusCode}',
      );
    }
  }

  // Lấy thống kê bookings
  static Future<Map<String, dynamic>> getStatsSummary() async {
    String? token;
    try {
      token = await _storage.read(key: 'jwt');
    } catch (_) {}
    if (token == null || token == 'null' || token.isEmpty) {
      print("BookingService: Token is null/empty. Skipping getStatsSummary.");
      return {};
    }

    final url = Uri.parse('$baseUrl/stats/summary');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception(
        'Không thể lấy thống kê đặt khám: ${response.statusCode}',
      );
    }
  }

  // Cập nhật trạng thái booking
  static Future<Booking> updateStatus(
    String bookingId,
    String statusUpdate,
  ) async {
    final url = Uri.parse(
      '$baseUrl/$bookingId/status?status_update=$statusUpdate',
    );
    final response = await http.put(url, headers: await _headers());

    if (response.statusCode == 200) {
      return Booking.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể cập nhật trạng thái: ${response.body}');
    }
  }

  // Cập nhật thông tin booking (Đổi lịch, chuyển bác sĩ)
  static Future<Booking> updateBooking(
    String bookingId, {
    String? bookingDate,
    String? timeSlot,
    String? symptoms,
    String? status,
    String? doctorId,
  }) async {
    final url = Uri.parse('$baseUrl/$bookingId');
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode({
        if (bookingDate != null) 'booking_date': bookingDate,
        if (timeSlot != null) 'time_slot': timeSlot,
        if (symptoms != null) 'symptoms': symptoms,
        if (status != null) 'status': status,
        if (doctorId != null) 'doctor_id': doctorId,
      }),
    );

    if (response.statusCode == 200) {
      return Booking.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể cập nhật lịch đặt: ${response.body}');
    }
  }

  // Lấy danh sách ca khám hôm nay của bác sĩ đang đăng nhập
  static Future<List<Booking>> getDoctorTodayBookings() async {
    String? token;
    try {
      token = await _storage.read(key: 'jwt');
    } catch (_) {}
    if (token == null || token == 'null' || token.isEmpty) {
      print(
        "BookingService: Token is null/empty. Skipping getDoctorTodayBookings.",
      );
      return [];
    }

    final url = Uri.parse('$baseUrl/doctor/today');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => Booking.fromJson(e)).toList();
    } else {
      throw Exception(
        'Không thể lấy lịch khám hôm nay của bác sĩ: ${response.statusCode}',
      );
    }
  }
}
