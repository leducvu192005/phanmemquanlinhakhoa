import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/service_price_history.dart';
import '../services/service_api.dart';

class PricingScreen extends StatefulWidget {
  @override
  _PricingScreenState createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  List<Service> services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    setState(() => isLoading = true);
    services = await ServiceApi.getServices();
    setState(() => isLoading = false);
  }

  void showEditPrice(Service service) {
    final priceController = TextEditingController(
      text: service.price.toString(),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chỉnh sửa giá dịch vụ'),
        content: TextField(
          controller: priceController,
          decoration: InputDecoration(labelText: 'Giá mới'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text) ?? 0;
              await ServiceApi.updatePrice(service.id, newPrice);
              Navigator.pop(context);
              fetchServices();
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void showPriceHistory(Service service) async {
    final history = await ServiceApi.getPriceHistory(service.id);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Lịch sử giá: ${service.serviceName}'),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: history
                .map(
                  (h) => ListTile(
                    title: Text('Từ ${h.oldPrice} → ${h.newPrice}'),
                    subtitle: Text('Cập nhật: ${h.updatedAt}'),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thiết lập giá dịch vụ')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: services.length,
              itemBuilder: (_, i) {
                final s = services[i];
                return ListTile(
                  title: Text(s.serviceName),
                  subtitle: Text('Giá hiện tại: ${s.price}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => showEditPrice(s),
                      ),
                      IconButton(
                        icon: Icon(Icons.history),
                        onPressed: () => showPriceHistory(s),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
