import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String selectedCategory = 'Tất cả';
  bool isLoading = true;

  final List<String> categories = [
    'Tất cả',
    'Khám & Chẩn đoán',
    'Vệ sinh răng miệng',
    'Trám răng',
    'Nhổ răng',
    'Điều trị tủy',
    'Thẩm mỹ',
    'Răng sứ',
    'Niềng răng',
    'Implant',
  ];

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

  List<Service> get filteredServices {
    if (selectedCategory == 'Tất cả') return services;
    return services.where((s) => s.category == selectedCategory).toList();
  }

  String formatPrice(double price) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(price);
  }

  void showServiceForm({Service? service}) {
    final codeController = TextEditingController(
      text: service?.serviceCode ?? '',
    );
    final nameController = TextEditingController(
      text: service?.serviceName ?? '',
    );
    final descController = TextEditingController(
      text: service?.description ?? '',
    );
    final durationController = TextEditingController(
      text: service?.duration_minutes?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: service?.price.toString() ?? '',
    );

    String currentCategory = service?.category ?? categories[1];
    bool status = service?.status ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                service == null ? Icons.add_box : Icons.edit_note,
                color: Colors.teal,
              ),
              SizedBox(width: 8),
              Text(
                service == null ? 'Thêm dịch vụ mới' : 'Cập nhật dịch vụ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Mã dịch vụ (Ví dụ: DV001)',
                      prefixIcon: Icon(Icons.qr_code),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên dịch vụ',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: currentCategory,
                    decoration: InputDecoration(
                      labelText: 'Danh mục nhóm',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: categories
                        .where((cat) => cat != 'Tất cả')
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => currentCategory = val!),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: durationController,
                    decoration: InputDecoration(
                      labelText: 'Thời lượng (phút)',
                      prefixIcon: Icon(Icons.timer_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Giá dịch vụ (VND)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Mô tả ngắn dịch vụ',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(
                      'Kích hoạt dịch vụ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    value: status,
                    activeColor: Colors.teal,
                    onChanged: (val) => setDialogState(() => status = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final data = {
                  'service_code': codeController.text,
                  'service_name': nameController.text,
                  'category': currentCategory,
                  'description': descController.text,
                  'duration_minutes': int.tryParse(durationController.text),
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
              child: Text(
                'Lưu thông tin',
                style: TextStyle(color: Colors.white),
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xoá dịch vụ [${service.serviceName}] khỏi danh mục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ServiceApi.deleteService(service.id);
              Navigator.pop(context);
              fetchServices();
            },
            child: Text('Xoá ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = filteredServices;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản Lý Dịch Vụ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              'Hệ thống quản trị nha khoa',
              style: TextStyle(fontSize: 12, color: Colors.teal[100]),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.teal[400],
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: () => showServiceForm(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.teal,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm nhanh mã, tên dịch vụ nha khoa...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.teal),
                ),
                onChanged: (val) {
                  search = val;
                  fetchServices();
                },
              ),
            ),
          ),
          Container(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(
                top: 16,
                bottom: 16,
                left: 12,
                right: 20,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.teal[100],
                    checkmarkColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.teal[800] : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kết quả: ${displayList.length} dịch vụ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  selectedCategory,
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                  )
                : displayList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_information_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Không tìm thấy dịch vụ nào phù hợp!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: displayList.length,
                    itemBuilder: (_, i) {
                      final s = displayList[i];
                      return Card(
                        elevation: 1,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.healing_outlined,
                                  color: Colors.teal,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.teal[800],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            s.serviceCode ?? 'DV',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            s.serviceName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.grey[800],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      s.description ?? 'Không có mô tả',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          s.duration_minutes != null
                                              ? '${s.duration_minutes} phút'
                                              : 'Theo ca',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          size: 14,
                                          color: Colors.orange[700],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          formatPrice(s.price),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.orange[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    constraints: BoxConstraints(),
                                    padding: EdgeInsets.all(4),
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue[600],
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        showServiceForm(service: s),
                                  ),
                                  SizedBox(height: 8),
                                  IconButton(
                                    constraints: BoxConstraints(),
                                    padding: EdgeInsets.all(4),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[400],
                                      size: 20,
                                    ),
                                    onPressed: () => confirmDelete(s),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
