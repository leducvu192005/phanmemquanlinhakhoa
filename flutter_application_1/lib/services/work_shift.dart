import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/work_shift.dart';

class WorkShiftApi {
  static const String baseUrl = 'http://127.0.0.1:8000/work-shifts';

  // GET ALL
  static Future<List<WorkShift>> getAllShifts() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));

      return data.map((e) => WorkShift.fromJson(e)).toList();
    }

    throw Exception('Failed to load shifts');
  }

  // GET DETAIL
  static Future<WorkShift> getShiftById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return WorkShift.fromJson(jsonDecode(response.body));
    }

    throw Exception('Shift not found');
  }

  // CREATE
  static Future<WorkShift> createShift({
    required String shiftCode,
    required String shiftName,
    required String startTime,
    required String endTime,
    required int maxPatients,
    required bool status,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'shift_code': shiftCode,
        'shift_name': shiftName,
        'start_time': startTime,
        'end_time': endTime,
        'max_patients': maxPatients,
        'status': status,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return WorkShift.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to create shift');
  }

  // UPDATE
  static Future<WorkShift> updateShift({
    required int id,
    required String shiftCode,
    required String shiftName,
    required String startTime,
    required String endTime,
    required int maxPatients,
    required bool status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'shift_code': shiftCode,
        'shift_name': shiftName,
        'start_time': startTime,
        'end_time': endTime,
        'max_patients': maxPatients,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return WorkShift.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to update shift');
  }

  // DELETE
  static Future<bool> deleteShift(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    return response.statusCode == 200;
  }

  // SEARCH LOCAL
  static List<WorkShift> searchShifts(List<WorkShift> shifts, String keyword) {
    if (keyword.isEmpty) {
      return shifts;
    }

    return shifts.where((shift) {
      return shift.shiftName.toLowerCase().contains(keyword.toLowerCase()) ||
          shift.shiftCode.toLowerCase().contains(keyword.toLowerCase());
    }).toList();
  }
}
