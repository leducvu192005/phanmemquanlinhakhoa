import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/service_api.dart';

class ServiceManagementScreen extends StatefulWidget {
  @override
  _ServiceManagementScreenState createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  List<Service> services = [];
  String search = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    setState(() => isLoading = true);
    services = await ServiceApi.getServices(
      search: search.isNotEmpty ? search : null,
    );
    setState(() => isLoading = false);
  }

  void showServiceForm({Service? service}) {
    final nameController = TextEditingController(
      text: service?.serviceName ?? '',
    );
    final descController = TextEditingController(
      text: service?.description ?? '',
    );
    final durationController = TextEditingController(
      text: service?.duration?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: service?.price.toString() ?? '',
    );
    bool status = service?.status ?? true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(service == null ? 'Thêm dịch vụ' : 'Sửa dịch vụ'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Tên dịch vụ'),
                ),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: 'Mô tả'),
                ),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(labelText: 'Thời lượng'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Giá'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: Text('Trạng thái'),
                  value: status,
                  onChanged: (val) => setState(() => status = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'service_name': nameController.text,
                  'description': descController.text,
                  'duration': int.tryParse(durationController.text),
                  'price': double.tryParse(priceController.text) ?? 0,
                  'status': status,
                };
                if (service == null) {
                  await ServiceApi.createService(data);
                } else {
                  await ServiceApi.updateService(service.id, data);
                }
                Navigator.pop(context);
                fetchServices();
              },
              child: Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void confirmDelete(Service service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text('Bạn có chắc muốn xoá dịch vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ServiceApi.deleteService(service.id);
              Navigator.pop(context);
              fetchServices();
            },
            child: Text('Xoá'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý dịch vụ'),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: () => showServiceForm()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(labelText: 'Tìm kiếm dịch vụ'),
              onChanged: (val) {
                search = val;
                fetchServices();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (_, i) {
                      final s = services[i];
                      return ListTile(
                        title: Text(s.serviceName),
                        subtitle: Text(
                          'Giá: ${s.price} - Thời lượng: ${s.duration ?? '-'} phút',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => showServiceForm(service: s),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => confirmDelete(s),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
