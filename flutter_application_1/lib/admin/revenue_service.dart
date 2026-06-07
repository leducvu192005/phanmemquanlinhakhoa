import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api.dart';
import 'revenue_model.dart';

class RevenueService {
  static const _storage = FlutterSecureStorage();

  static Future<RevenueReport> fetchRevenueReport({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }

    final uri = Uri.parse('${Api.baseUrl}/reports/revenue').replace(
      queryParameters: queryParams,
    );

    final token = await _storage.read(key: 'jwt');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return RevenueReport.fromJson(decoded);
    } else {
      throw Exception('Không thể lấy báo cáo doanh thu: ${response.statusCode} - ${response.body}');
    }
  }
}
