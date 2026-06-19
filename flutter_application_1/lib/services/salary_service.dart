import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';
import '../models/salary_config_model.dart';

class SalaryService {
  static String get baseUrl => '${Api.baseUrl}/salary';
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers({bool withJson = false}) async {
    String? token;
    try {
      token = await _storage.read(key: 'jwt');
    } catch (_) {
      // Safely ignore storage issues
    }
    return {
      if (withJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // 1. ADMIN - CONFIGS
  // ==========================================
  static Future<List<SalaryConfigModel>> getConfigs() async {
    final response = await http.get(Uri.parse('$baseUrl/configs'), headers: await _headers());
    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => SalaryConfigModel.fromJson(e)).toList();
    }
    throw Exception('Không thể lấy cấu hình mức lương: ${response.statusCode}');
  }

  static Future<SalaryConfigModel> createConfig(double baseRate, String effectiveDate) async {
    final response = await http.post(
      Uri.parse('$baseUrl/configs'),
      headers: await _headers(withJson: true),
      body: jsonEncode({
        'base_salary_per_hour': baseRate,
        'effective_date': effectiveDate,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SalaryConfigModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    final error = json.decode(utf8.decode(response.bodyBytes));
    throw Exception(error['detail'] ?? 'Thiết lập mức lương cơ bản thất bại');
  }

  static Future<SalaryConfigModel> updateConfig(int id, double baseRate, String effectiveDate) async {
    final response = await http.put(
      Uri.parse('$baseUrl/configs/$id'),
      headers: await _headers(withJson: true),
      body: jsonEncode({
        'base_salary_per_hour': baseRate,
        'effective_date': effectiveDate,
      }),
    );
    if (response.statusCode == 200) {
      return SalaryConfigModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    final error = json.decode(utf8.decode(response.bodyBytes));
    throw Exception(error['detail'] ?? 'Cập nhật mức lương cơ bản thất bại');
  }

  static Future<void> deleteConfig(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/configs/$id'), headers: await _headers());
    if (response.statusCode != 200) {
      final error = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? 'Xóa mức lương cơ bản thất bại');
    }
  }

  // ==========================================
  // 2. ADMIN - SHIFT COEFFICIENTS
  // ==========================================
  static Future<List<SalaryShiftCoefficientModel>> getShifts() async {
    final response = await http.get(Uri.parse('$baseUrl/shifts'), headers: await _headers());
    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => SalaryShiftCoefficientModel.fromJson(e)).toList();
    }
    throw Exception('Không thể lấy hệ số ca làm việc: ${response.statusCode}');
  }

  static Future<SalaryShiftCoefficientModel> createShift(String name, double coef) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shifts'),
      headers: await _headers(withJson: true),
      body: jsonEncode({
        'shift_name': name,
        'coefficient': coef,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SalaryShiftCoefficientModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    final error = json.decode(utf8.decode(response.bodyBytes));
    throw Exception(error['detail'] ?? 'Thêm hệ số ca làm việc thất bại');
  }

  static Future<SalaryShiftCoefficientModel> updateShift(int id, String name, double coef) async {
    final response = await http.put(
      Uri.parse('$baseUrl/shifts/$id'),
      headers: await _headers(withJson: true),
      body: jsonEncode({
        'shift_name': name,
        'coefficient': coef,
      }),
    );
    if (response.statusCode == 200) {
      return SalaryShiftCoefficientModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    final error = json.decode(utf8.decode(response.bodyBytes));
    throw Exception(error['detail'] ?? 'Cập nhật hệ số thất bại');
  }

  static Future<void> deleteShift(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/shifts/$id'), headers: await _headers());
    if (response.statusCode != 200) {
      final error = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? 'Xóa hệ số thất bại');
    }
  }

  // ==========================================
  // 3. ADMIN - COMPLEXITY COEFFICIENTS
  // ==========================================
  static Future<List<SalaryComplexityCoefficientModel>> getComplexities() async {
    final response = await http.get(Uri.parse('$baseUrl/complexities'), headers: await _headers());
    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => SalaryComplexityCoefficientModel.fromJson(e)).toList();
    }
    throw Exception('Không thể lấy hệ số ca phức tạp: ${response.statusCode}');
  }

  static Future<SalaryComplexityCoefficientModel> createComplexity(String level, double coef) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complexities'),
      headers: await _headers(withJson: true),
      body: jsonEncode({
        'complexity_level': level,
        'coefficient': coef,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SalaryComplexityCoefficientModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    final error = json.decode(utf8.decode(response.bodyBytes));
    throw Exception(error['detail'] ?? 'Thêm hệ số ca phức tạp thất bại');
  }

  static Future<SalaryComplexityCoefficientModel> updateComplexity(int id, String level, double coef) async {
    final response = await http.put(
      Uri.parse('$baseUrl/complexities/$id'),
      headers: await _headers(withJson: true),
      body: jsonEncode({
        'complexity_level': level,
        'coefficient': coef,
      }),
    );
    if (response.statusCode == 200) {
      return SalaryComplexityCoefficientModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    final error = json.decode(utf8.decode(response.bodyBytes));
    throw Exception(error['detail'] ?? 'Cập nhật hệ số thất bại');
  }

  static Future<void> deleteComplexity(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/complexities/$id'), headers: await _headers());
    if (response.statusCode != 200) {
      final error = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? 'Xóa hệ số thất bại');
    }
  }

  // ==========================================
  // 4. STAFF - SLIPS
  // ==========================================
  static Future<SalarySlipModel> calculateSalary(String doctorId, int month, int year) async {
    final response = await http.get(
      Uri.parse('$baseUrl/calculate?doctor_id=$doctorId&month=$month&year=$year'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return SalarySlipModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    final error = json.decode(utf8.decode(response.bodyBytes));
    throw Exception(error['detail'] ?? 'Tính toán lương bác sĩ thất bại');
  }

  static Future<SalarySlipModel> saveSalarySlip(String doctorId, int month, int year) async {
    final response = await http.post(
      Uri.parse('$baseUrl/slips'),
      headers: await _headers(withJson: true),
      body: jsonEncode({
        'doctor_id': doctorId,
        'month': month,
        'year': year,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SalarySlipModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    final error = json.decode(utf8.decode(response.bodyBytes));
    throw Exception(error['detail'] ?? 'Lưu phiếu lương thất bại');
  }

  static Future<List<SalarySlipModel>> getSlips({String? doctorId, int? month, int? year}) async {
    final queryParams = <String, String>{};
    if (doctorId != null) queryParams['doctor_id'] = doctorId;
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse('$baseUrl/slips').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => SalarySlipModel.fromJson(e)).toList();
    }
    throw Exception('Không thể lấy danh sách phiếu lương: ${response.statusCode}');
  }

  // ==========================================
  // 5. ADMIN - REPORTS
  // ==========================================
  static Future<MonthlySalaryReportModel> getMonthlyReport(int month, int year) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/monthly?month=$month&year=$year'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return MonthlySalaryReportModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Không thể tải báo cáo tháng: ${response.statusCode}');
  }

  static Future<YearlyDoctorSalaryReportModel> getYearlyDoctorReport(String doctorId, int year) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/yearly-doctor?doctor_id=$doctorId&year=$year'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return YearlyDoctorSalaryReportModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Không thể tải báo cáo năm bác sĩ: ${response.statusCode}');
  }

  static Future<YearlyAllDoctorSalaryReportModel> getYearlyAllReport(int year) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/yearly-all?year=$year'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return YearlyAllDoctorSalaryReportModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Không thể tải báo cáo năm tổng thể: ${response.statusCode}');
  }
}
