class PaymentServiceItem {
  final String serviceName;
  final double price;
  final int quantity;
  final double subtotal;

  PaymentServiceItem({
    required this.serviceName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory PaymentServiceItem.fromJson(Map<String, dynamic> json) {
    return PaymentServiceItem(
      serviceName: json['service_name'] ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] ?? 1,
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}

class PaymentModel {
  final String id;
  final String bookingId;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String patientCode;
  final String doctorId;
  final String doctorName;
  final String bookingDate;
  final String timeSlot;
  final String diagnosis;
  final String notes;
  final List<PaymentServiceItem> services;
  final double subtotal;
  final double discount;
  final double totalAmount;
  String paymentStatus; // unpaid, paid, partially_paid
  String? paymentMethod; // cash, transfer, qr
  DateTime? paymentTime;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.patientCode,
    required this.doctorId,
    required this.doctorName,
    required this.bookingDate,
    required this.timeSlot,
    required this.diagnosis,
    required this.notes,
    required this.services,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentTime,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    var servicesList = json['services'] as List? ?? [];
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name'] ?? '',
      patientPhone: json['patient_phone'] ?? '',
      patientCode: json['patient_code'] ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      diagnosis: json['diagnosis'] ?? 'Khám tổng quát',
      notes: json['notes'] ?? '',
      services: servicesList.map((e) => PaymentServiceItem.fromJson(e)).toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paymentMethod: json['payment_method'],
      paymentTime: json['payment_time'] != null ? DateTime.parse(json['payment_time']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'patient_id': patientId,
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'patient_code': patientCode,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'booking_date': bookingDate,
      'time_slot': timeSlot,
      'diagnosis': diagnosis,
      'notes': notes,
      'services': services.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'payment_time': paymentTime?.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? paymentStatus,
    String? paymentMethod,
    DateTime? paymentTime,
  }) {
    return PaymentModel(
      id: id,
      bookingId: bookingId,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      patientCode: patientCode,
      doctorId: doctorId,
      doctorName: doctorName,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
      diagnosis: diagnosis,
      notes: notes,
      services: services,
      subtotal: subtotal,
      discount: discount,
      totalAmount: totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTime: paymentTime ?? this.paymentTime,
    );
  }
}
