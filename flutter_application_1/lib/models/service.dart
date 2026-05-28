class Service {
  final int id;
  final String serviceName;
  final String? description;
  final int? duration;
  final double price;
  final bool status;
  final DateTime createdAt;

  Service({
    required this.id,
    required this.serviceName,
    this.description,
    this.duration,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'],
    serviceName: json['service_name'],
    description: json['description'],
    duration: json['duration'],
    price: (json['price'] as num).toDouble(),
    status: json['status'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
