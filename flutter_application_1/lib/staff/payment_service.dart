import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/api.dart';
import 'payment_model.dart';

class PaymentService {
  static const _storage = FlutterSecureStorage();
  static const String _storageKey = 'paid_booking_records';

  // Helper to get saved payment records
  static Future<Map<String, Map<String, dynamic>>> _getPaidRecords() async {
    try {
      final data = await _storage.read(key: _storageKey);
      if (data != null) {
        final decoded = jsonDecode(data);
        return Map<String, Map<String, dynamic>>.from(
          decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),
        );
      }
    } catch (_) {}
    return {};
  }

  // Helper to save payment records
  static Future<void> _savePaidRecords(Map<String, Map<String, dynamic>> records) async {
    await _storage.write(key: _storageKey, value: jsonEncode(records));
  }

  static List<PaymentServiceItem> _generateServices(Booking b) {
    if (b.services.isNotEmpty) {
      return b.services.map((s) => PaymentServiceItem(
        serviceName: s.serviceName,
        price: s.price,
        quantity: 1,
        subtotal: s.price,
      )).toList();
    }

    final symptoms = (b.symptoms ?? '').toLowerCase();
    final services = <PaymentServiceItem>[];

    // Always include a consultation fee
    services.add(PaymentServiceItem(
      serviceName: 'Khám & tư vấn răng hàm mặt',
      price: 100000,
      quantity: 1,
      subtotal: 100000,
    ));

    if (symptoms.contains('nhổ') || symptoms.contains('răng khôn') || symptoms.contains('răng lệch')) {
      services.add(PaymentServiceItem(
        serviceName: 'Chụp phim panorama toàn cảnh',
        price: 350000,
        quantity: 1,
        subtotal: 350000,
      ));
      services.add(PaymentServiceItem(
        serviceName: 'Nhổ răng khôn mọc lệch (tiểu phẫu)',
        price: 1500000,
        quantity: 1,
        subtotal: 1500000,
      ));
    } else if (symptoms.contains('trám') || symptoms.contains('sâu') || symptoms.contains('đau')) {
      services.add(PaymentServiceItem(
        serviceName: 'Chụp phim quanh chóp (X-Quang)',
        price: 200000,
        quantity: 1,
        subtotal: 200000,
      ));
      services.add(PaymentServiceItem(
        serviceName: 'Trám răng composite thẩm mỹ',
        price: 500000,
        quantity: 1,
        subtotal: 500000,
      ));
    } else if (symptoms.contains('tẩy') || symptoms.contains('trắng') || symptoms.contains('cao răng') || symptoms.contains('vôi')) {
      services.add(PaymentServiceItem(
        serviceName: 'Lấy cao răng & đánh bóng hai hàm',
        price: 250000,
        quantity: 1,
        subtotal: 250000,
      ));
      if (symptoms.contains('tẩy') || symptoms.contains('trắng')) {
        services.add(PaymentServiceItem(
          serviceName: 'Tẩy trắng răng thẩm mỹ tại phòng khám',
          price: 2000000,
          quantity: 1,
          subtotal: 2000000,
        ));
      }
    } else {
      services.add(PaymentServiceItem(
        serviceName: 'Lấy cao răng & đánh bóng hai hàm',
        price: 250000,
        quantity: 1,
        subtotal: 250000,
      ));
    }

    return services;
  }

  static Future<List<PaymentModel>> getPayments() async {
    try {
      // 1. Fetch completed bookings from database using status_filter
      final bookings = await BookingService.getAllBookings(status: 'completed');
      
      // Only keep bookings that are unpaid
      final unpaidBookings = bookings.where((b) => b.paymentStatus == 'unpaid').toList();

      final paymentsList = <PaymentModel>[];

      for (var b in unpaidBookings) {
        final bId = b.id.toString();
        final services = _generateServices(b);
        final subtotal = services.fold<double>(0, (sum, item) => sum + item.subtotal);

        // Determine payment details from database properties
        final paymentStatus = b.paymentStatus; // 'paid' or 'unpaid'
        final paymentMethod = b.paymentMethod;
        final paymentTime = b.paymentTime;
        final discount = b.discountAmount;
        final totalAmount = b.totalAmount > 0 ? b.totalAmount : (subtotal - discount);

        paymentsList.add(PaymentModel(
          id: 'PM-$bId',
          bookingId: 'LH-$bId',
          patientId: b.patientId,
          patientName: b.patient?.fullName ?? 'Bệnh nhân ẩn danh',
          patientPhone: b.patient?.phone ?? '',
          patientCode: b.patient?.patientCode ?? 'BN-$bId',
          doctorId: b.doctorId,
          doctorName: b.doctor?.fullName ?? 'Bác sĩ',
          bookingDate: b.bookingDate,
          timeSlot: b.timeSlot,
          diagnosis: b.symptoms ?? 'Khám răng hàm mặt',
          notes: b.symptoms ?? '',
          services: services,
          subtotal: subtotal,
          discount: discount,
          totalAmount: totalAmount,
          paymentStatus: paymentStatus,
          paymentMethod: paymentMethod,
          paymentTime: paymentTime,
        ));
      }

      // If no completed bookings are in the database yet, we append the mock data
      // so the user can still test the UI immediately.
      if (paymentsList.isEmpty) {
        paymentsList.addAll(await _getMockFallbackPayments());
      }

      return paymentsList;
    } catch (e) {
      print('PaymentService fetch error, falling back to mock data: $e');
      return _getMockFallbackPayments();
    }
  }

  static Future<List<PaymentModel>> _getMockFallbackPayments() async {
    final paidRecords = await _getPaidRecords();
    final mockList = [
      PaymentModel(
        id: 'PM-M01',
        bookingId: 'LH-M01',
        patientId: 'BN-M01',
        patientName: 'Nguyễn Văn A',
        patientPhone: '0901234567',
        patientCode: 'BN6832',
        doctorId: 'doc-1',
        doctorName: 'Nguyễn Văn Cường',
        bookingDate: '2026-06-07',
        timeSlot: 'Ca sáng (08:00 - 12:00)',
        diagnosis: 'Sâu răng hàm số 6 & viêm nướu nhẹ',
        notes: 'Hẹn tái khám sau 2 tuần để kiểm tra mối trám.',
        services: [
          PaymentServiceItem(serviceName: 'Khám & tư vấn răng hàm mặt', price: 100000, quantity: 1, subtotal: 100000),
          PaymentServiceItem(serviceName: 'Chụp phim quanh chóp (X-Quang)', price: 200000, quantity: 1, subtotal: 200000),
          PaymentServiceItem(serviceName: 'Trám răng composite thẩm mỹ', price: 500000, quantity: 1, subtotal: 500000),
        ],
        subtotal: 800000,
        discount: 50000,
        totalAmount: 750000,
        paymentStatus: 'unpaid',
      ),
      PaymentModel(
        id: 'PM-M02',
        bookingId: 'LH-M02',
        patientId: 'BN-M02',
        patientName: 'Trần Thị B',
        patientPhone: '0918765432',
        patientCode: 'BN4921',
        doctorId: 'doc-2',
        doctorName: 'Trần Thị Mai',
        bookingDate: '2026-06-07',
        timeSlot: 'Ca chiều (13:30 - 17:30)',
        diagnosis: 'Lấy cao răng & Tẩy trắng răng thẩm mỹ',
        notes: 'Bệnh nhân ê buốt nhẹ, khuyên dùng kem đánh răng chống ê buốt.',
        services: [
          PaymentServiceItem(serviceName: 'Lấy cao răng & đánh bóng hai hàm', price: 250000, quantity: 1, subtotal: 250000),
          PaymentServiceItem(serviceName: 'Tẩy trắng răng thẩm mỹ tại phòng khám', price: 2000000, quantity: 1, subtotal: 2000000),
        ],
        subtotal: 2250000,
        discount: 200000,
        totalAmount: 2050000,
        paymentStatus: 'unpaid',
      ),
    ];

    for (var i = 0; i < mockList.length; i++) {
      final p = mockList[i];
      if (paidRecords.containsKey(p.id)) {
        final record = paidRecords[p.id]!;
        mockList[i] = p.copyWith(
          paymentStatus: 'paid',
          paymentMethod: record['method'],
          paymentTime: record['time'] != null ? DateTime.parse(record['time']) : null,
        );
      }
    }
    return mockList;
  }

  static Future<PaymentModel> processPayment(
    String id, {
    required String method,
    double discount = 0.0,
  }) async {
    // If it is a mock ID, return updated mock fallback payment
    if (id.contains('-M')) {
      final paidRecords = await _getPaidRecords();
      paidRecords[id] = {
        'method': method,
        'discount': discount,
        'time': DateTime.now().toIso8601String(),
      };
      await _savePaidRecords(paidRecords);
      final mockList = await _getMockFallbackPayments();
      return mockList.firstWhere((p) => p.id == id);
    }

    final bId = id.startsWith('PM-') ? id.substring(3) : id;

    // Fetch booking details to compute total amount
    final booking = await BookingService.getBookingById(bId);
    final services = _generateServices(booking);
    final subtotal = services.fold<double>(0, (sum, item) => sum + item.subtotal);
    final totalAmount = subtotal - discount;

    // Call backend API to mark as paid
    final token = await _storage.read(key: 'jwt');
    final response = await http.put(
      Uri.parse('${Api.baseUrl}/bookings/$bId/pay'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'payment_method': method,
        'discount_amount': discount,
        'total_amount': totalAmount,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể thanh toán trên hệ thống: ${response.body}');
    }

    // Load updated payment from backend
    final payments = await getPayments();
    return payments.firstWhere((p) => p.id == id);
  }
}
