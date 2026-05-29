import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/service.dart';
import '../models/service_price_history.dart';

class ServiceApi {
  static const String baseUrl = 'http://127.0.0.1:8000/admin';

  static const _storage = FlutterSecureStorage();
  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'jwt');

    print("JWT STORED: $token");

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Service>> getServices({String? search}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/services${search != null ? '?search=$search' : ''}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Service.fromJson(e)).toList();
    }

    throw Exception('Failed to load services');
  }

  static Future<Service> createService(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services'),
      headers: await _headers(),
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Service.fromJson(json.decode(response.body));
    }

    throw Exception('Failed to create service');
  }

  static Future<Service> updateService(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/services/$id'),
      headers: await _headers(),
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return Service.fromJson(json.decode(response.body));
    }

    throw Exception('Failed to update service');
  }

  static Future<void> deleteService(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/services/$id'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete service');
    }
  }

  static Future<Service> updatePrice(int id, double newPrice) async {
    final response = await http.put(
      Uri.parse('$baseUrl/services/$id/price?new_price=$newPrice'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Service.fromJson(json.decode(response.body));
    }

    throw Exception('Failed to update price');
  }

  static Future<List<ServicePriceHistory>> getPriceHistory(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/services/$id/price-history'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      return data.map((e) => ServicePriceHistory.fromJson(e)).toList();
    }

    throw Exception('Failed to load price history');
  }
}
