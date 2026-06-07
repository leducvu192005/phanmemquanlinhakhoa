class RevenueReport {
  final double totalRevenue;
  final double todayRevenue;
  final double monthRevenue;
  final int totalPaidBookings;
  final List<DailyRevenue> dailyRevenue;
  final List<DoctorRevenue> doctorRevenue;
  final List<ServiceRevenue> serviceRevenue;
  final List<RevenueTransaction> transactions;

  RevenueReport({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.monthRevenue,
    required this.totalPaidBookings,
    required this.dailyRevenue,
    required this.doctorRevenue,
    required this.serviceRevenue,
    required this.transactions,
  });

  factory RevenueReport.fromJson(Map<String, dynamic> json) {
    return RevenueReport(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      monthRevenue: (json['monthRevenue'] as num?)?.toDouble() ?? 0.0,
      totalPaidBookings: json['totalPaidBookings'] as int? ?? 0,
      dailyRevenue: (json['dailyRevenue'] as List? ?? [])
          .map((e) => DailyRevenue.fromJson(e))
          .toList(),
      doctorRevenue: (json['doctorRevenue'] as List? ?? [])
          .map((e) => DoctorRevenue.fromJson(e))
          .toList(),
      serviceRevenue: (json['serviceRevenue'] as List? ?? [])
          .map((e) => ServiceRevenue.fromJson(e))
          .toList(),
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => RevenueTransaction.fromJson(e))
          .toList(),
    );
  }
}

class DailyRevenue {
  final String date;
  final double revenue;

  DailyRevenue({
    required this.date,
    required this.revenue,
  });

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: json['date'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DoctorRevenue {
  final String doctorName;
  final int bookingCount;
  final double revenue;

  DoctorRevenue({
    required this.doctorName,
    required this.bookingCount,
    required this.revenue,
  });

  factory DoctorRevenue.fromJson(Map<String, dynamic> json) {
    return DoctorRevenue(
      doctorName: json['doctorName'] ?? '',
      bookingCount: json['bookingCount'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ServiceRevenue {
  final String serviceName;
  final int count;
  final double revenue;

  ServiceRevenue({
    required this.serviceName,
    required this.count,
    required this.revenue,
  });

  factory ServiceRevenue.fromJson(Map<String, dynamic> json) {
    return ServiceRevenue(
      serviceName: json['serviceName'] ?? '',
      count: json['count'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RevenueTransaction {
  final String bookingId;
  final String patientName;
  final String doctorName;
  final DateTime paymentTime;
  final String paymentMethod;
  final double discountAmount;
  final double totalAmount;

  RevenueTransaction({
    required this.bookingId,
    required this.patientName,
    required this.doctorName,
    required this.paymentTime,
    required this.paymentMethod,
    required this.discountAmount,
    required this.totalAmount,
  });

  factory RevenueTransaction.fromJson(Map<String, dynamic> json) {
    return RevenueTransaction(
      bookingId: json['bookingId'] ?? '',
      patientName: json['patientName'] ?? '',
      doctorName: json['doctorName'] ?? '',
      paymentTime: json['paymentTime'] != null
          ? DateTime.parse(json['paymentTime'])
          : DateTime.now(),
      paymentMethod: json['paymentMethod'] ?? '',
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
