import 'patient_model.dart';
import 'doctor_model.dart';

class Booking {
  final String id;
  final String patientId;
  final String doctorId;
  final String bookingDate;
  final String timeSlot;
  final String? symptoms;
  final String status;
  final Patient? patient;
  final Doctor? doctor;

  Booking({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.bookingDate,
    required this.timeSlot,
    this.symptoms,
    required this.status,
    this.patient,
    this.doctor,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      bookingDate: json['booking_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      symptoms: json['symptoms'],
      status: json['status'] ?? 'pending',
      patient: json['patient'] != null ? Patient.fromJson(json['patient']) : null,
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': int.tryParse(patientId) ?? patientId,
      'doctor_id': doctorId,
      'booking_date': bookingDate,
      'time_slot': timeSlot,
      'symptoms': symptoms,
      'status': status,
    };
  }
}
