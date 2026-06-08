import 'patient_model.dart';
import 'doctor_model.dart';
import 'service.dart';

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

  // New payment fields
  final String paymentStatus;
  final String? paymentMethod;
  final DateTime? paymentTime;
  final double discountAmount;
  final double totalAmount;

  // Indicated services list
  final List<Service> services;
  final String complexityLevel;

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
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.paymentTime,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.services = const [],
    this.complexityLevel = 'Thông thường',
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    Patient? parsedPatient;
    try {
      if (json['patient'] != null) {
        parsedPatient = Patient.fromJson(json['patient']);
      }
    } catch (e) {
      print("Error parsing patient in Booking: $e");
    }

    Doctor? parsedDoctor;
    try {
      if (json['doctor'] != null) {
        parsedDoctor = Doctor.fromJson(json['doctor']);
      }
    } catch (e) {
      print("Error parsing doctor in Booking: $e");
    }

    List<Service> parsedServices = [];
    try {
      if (json['services'] != null) {
        parsedServices = (json['services'] as List)
            .map((e) => Service.fromJson(e))
            .toList();
      }
    } catch (e) {
      print("Error parsing services in Booking: $e");
    }

    return Booking(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      bookingDate: json['booking_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      symptoms: json['symptoms'],
      status: json['status'] ?? 'pending',
      patient: parsedPatient,
      doctor: parsedDoctor,
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paymentMethod: json['payment_method'],
      paymentTime: json['payment_time'] != null ? DateTime.tryParse(json['payment_time']) : null,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      services: parsedServices,
      complexityLevel: json['complexity_level'] ?? 'Thông thường',
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
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'payment_time': paymentTime?.toIso8601String(),
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'services': services.map((e) => e.toJson()).toList(),
      'complexity_level': complexityLevel,
    };
  }
}
