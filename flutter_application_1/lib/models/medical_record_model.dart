import 'patient_model.dart';
import 'doctor_model.dart';
import 'service.dart';

class MedicalRecord {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String diagnosis;
  final String treatment;
  final String? prescription;
  final String? notes;
  final DateTime? followUpDate;
  final DateTime createdAt;

  // Nested relationships
  final Patient? patient;
  final Doctor? doctor;
  final List<Service> indicatedServices;

  MedicalRecord({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.diagnosis,
    required this.treatment,
    this.prescription,
    this.notes,
    this.followUpDate,
    required this.createdAt,
    this.patient,
    this.doctor,
    required this.indicatedServices,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    var servicesList = json['indicated_services'] as List?;
    List<Service> services = servicesList != null
        ? servicesList.map((s) => Service.fromJson(s)).toList()
        : [];

    return MedicalRecord(
      id: json['id']?.toString() ?? '',
      appointmentId: json['appointment_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      diagnosis: json['diagnosis'] ?? '',
      treatment: json['treatment'] ?? '',
      prescription: json['prescription'],
      notes: json['notes'],
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      patient: json['patient'] != null ? Patient.fromJson(json['patient']) : null,
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      indicatedServices: services,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': int.tryParse(appointmentId) ?? appointmentId,
      'patient_id': int.tryParse(patientId) ?? patientId,
      'doctor_id': int.tryParse(doctorId) ?? doctorId,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'notes': notes,
      'follow_up_date': followUpDate?.toIso8601String().substring(0, 10), // YYYY-MM-DD
    };
  }
}
