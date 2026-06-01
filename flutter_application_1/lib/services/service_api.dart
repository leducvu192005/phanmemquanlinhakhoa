import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/service.dart';
import '../models/service_price_history.dart';

class ServiceApi {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const _storage = FlutterSecureStorage();
  static Future<Map<String, String>> _headers() async {
    return {'Content-Type': 'application/json'};
  }

  static Future<List<Service>> getServices({String? search}) async {
    final url = search != null && search.isNotEmpty
        ? '$baseUrl/services/search/?keyword=$search'
        : '$baseUrl/services';

    final response = await http.get(Uri.parse(url), headers: await _headers());

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
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
      return Service.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }

    throw Exception('Failed to create service');
  }

  static Future<Service> updateService(
    String id,
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

  static Future<void> deleteService(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/services/$id'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete service');
    }
  }

  static Future<Service> updatePrice(String id, double newPrice) async {
    final response = await http.put(
      Uri.parse('$baseUrl/services/$id/price?new_price=$newPrice'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Service.fromJson(json.decode(response.body));
    }

    throw Exception('Failed to update price');
  }

  static Future<List<ServicePriceHistory>> getPriceHistory(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/services/$id/price-history'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));

      return data.map((e) => ServicePriceHistory.fromJson(e)).toList();
    }

    throw Exception('Failed to load price history');
  }
}
