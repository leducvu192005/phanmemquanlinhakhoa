import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';
import '../models/medical_record_model.dart';

class MedicalRecordService {
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

  // Tạo bệnh án (hoàn thành ca khám, kê đơn, chỉ định dịch vụ)
  static Future<MedicalRecord> createMedicalRecord(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/medical-records/');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return MedicalRecord.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } else {
      String errMsg = 'Lỗi lưu bệnh án';
      try {
        final body = json.decode(utf8.decode(response.bodyBytes));
        errMsg = body['detail'] ?? errMsg;
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  // Lấy lịch sử bệnh án khám bệnh của bệnh nhân
  static Future<List<MedicalRecord>> getPatientMedicalHistory(
    String patientId,
  ) async {
    final url = Uri.parse('$baseUrl/medical-records/patient/$patientId');
    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => MedicalRecord.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải lịch sử bệnh án');
    }
  }

  // Xem chi tiết một bệnh án cụ thể
  static Future<MedicalRecord> getMedicalRecordDetail(String recordId) async {
    final url = Uri.parse('$baseUrl/medical-records/$recordId');
    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      return MedicalRecord.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Không tìm thấy bệnh án chi tiết');
    }
  }
}
