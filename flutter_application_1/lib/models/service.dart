class Service {
  final String id;
  final String serviceCode;
  final String serviceName;
  final String category;
  final String? description;
  final int? duration_minutes;
  final double price;
  final bool status;
  final DateTime createdAt;

  Service({
    required this.id,
    required this.serviceCode,
    required this.serviceName,
    required this.category,
    this.description,
    this.duration_minutes,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id']?.toString() ?? '',
      serviceCode: json['service_code'],
      serviceName: json['service_name'],
      category: json['category'],
      description: json['description'],
      duration_minutes: json['duration_minutes'],
      price: (json['price'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_code': serviceCode,
      'service_name': serviceName,

      'category': category,
      'description': description,
      'duration_minutes': duration_minutes,
      'price': price,
      'status': status,
    };
  }
}
