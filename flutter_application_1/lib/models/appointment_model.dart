import 'patient_model.dart';
import 'doctor_model.dart';
import 'service.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String serviceId;
  final DateTime appointmentTime;
  final String status; // pending, confirmed, completed, cancelled, no_show
  final String? reason;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested relationships
  final Patient? patient;
  final Doctor? doctor;
  final Service? service;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.serviceId,
    required this.appointmentTime,
    required this.status,
    this.reason,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.patient,
    this.doctor,
    this.service,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      appointmentTime: DateTime.parse(json['appointment_time']),
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      createdBy: json['created_by']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      patient: json['patient'] != null ? Patient.fromJson(json['patient']) : null,
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      service: json['service'] != null ? Service.fromJson(json['service']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': int.tryParse(patientId) ?? patientId,
      'doctor_id': int.tryParse(doctorId) ?? doctorId,
      'service_id': int.tryParse(serviceId) ?? serviceId,
      'appointment_time': appointmentTime.toIso8601String(),
      'reason': reason,
    };
  }
}
