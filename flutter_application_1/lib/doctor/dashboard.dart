import 'package:flutter/material.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Dashboard')),
      body: const Center(child: Text('Giao diện bác sĩ')),
    );
  }
}
