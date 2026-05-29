import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/patient_model.dart';

class UserService {
  Future<List<Patient>> getPatients() async {
    final response = await http.get(
      Uri.parse("http://127.0.0.1:8000/patients/"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data as List).map<Patient>((item) {
        return Patient.fromJson(item);
      }).toList();
    } else {
      throw Exception("Failed to load patients");
    }
  }
}
