import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/patient_model.dart';

class UserService {
  Future<List<Patient>> getPatients() async {
    final response = await http.get(Uri.parse("http://10.0.2.2:8000/patients"));

    final data = jsonDecode(response.body);

    return data.map<Patient>((item) {
      return Patient.fromJson(item);
    }).toList();
  }
}
