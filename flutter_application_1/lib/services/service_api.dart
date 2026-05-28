import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service.dart';
import '../models/service_price_history.dart';

class ServiceApi {
  static const String baseUrl = 'http://<YOUR_BACKEND_URL>/admin';

  static Future<List<Service>> getServices({String? search}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/services${search != null ? '?search=$search' : ''}'),
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
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
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
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return Service.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update service');
  }

  static Future<void> deleteService(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/services/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete service');
    }
  }

  static Future<Service> updatePrice(int id, double newPrice) async {
    final response = await http.put(
      Uri.parse('$baseUrl/services/$id/price?new_price=$newPrice'),
    );
    if (response.statusCode == 200) {
      return Service.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update price');
  }

  static Future<List<ServicePriceHistory>> getPriceHistory(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/services/$id/price-history'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => ServicePriceHistory.fromJson(e)).toList();
    }
    throw Exception('Failed to load price history');
  }
}
