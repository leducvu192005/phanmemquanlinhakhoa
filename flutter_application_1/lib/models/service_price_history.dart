class ServicePriceHistory {
  final int id;
  final int serviceId;
  final double oldPrice;
  final double newPrice;
  final int updatedBy;
  final DateTime updatedAt;

  ServicePriceHistory({
    required this.id,
    required this.serviceId,
    required this.oldPrice,
    required this.newPrice,
    required this.updatedBy,
    required this.updatedAt,
  });

  factory ServicePriceHistory.fromJson(Map<String, dynamic> json) =>
      ServicePriceHistory(
        id: json['id'],
        serviceId: json['service_id'],
        oldPrice: (json['old_price'] as num).toDouble(),
        newPrice: (json['new_price'] as num).toDouble(),
        updatedBy: json['updated_by'],
        updatedAt: DateTime.parse(json['updated_at']),
      );
}
