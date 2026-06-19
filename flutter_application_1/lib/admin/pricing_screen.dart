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
  List<Service> filteredServices = []; // Danh sách sau khi lọc tìm kiếm
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  // Hệ màu Xanh Ngọc chủ đạo Nha Khoa
  final Color primaryTeal = const Color(0xFF00A896);
  final Color lightTeal = const Color(0xFFE8F5E9);
  final Color darkTeal = const Color(0xFF028090);

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchServices() async {
    setState(() => isLoading = true);
    services = await ServiceApi.getServices();
    filteredServices = List.from(services);
    searchController.clear();
    setState(() => isLoading = false);
  }

  void filterServices(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredServices = List.from(services);
      } else {
        filteredServices = services.where((service) {
          final serviceName = service.serviceName.toLowerCase();
          final searchLower = query.toLowerCase();
          return serviceName.contains(searchLower);
        }).toList();
      }
    });
  }

  // --- FORM THÊM MỚI DỊCH VỤ ĐẦY ĐỦ CÁC TRƯỜNG ---
  void showAddServiceDialog() {
    final _formKey = GlobalKey<FormState>();

    // Các Controller quản lý nhập liệu
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController();
    final priceController = TextEditingController();
    bool statusValue = true; // Mặc định là Hoạt động (true)

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.add_business_rounded,
                    color: primaryTeal,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Thêm dịch vụ mới',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Mã dịch vụ & Tên dịch vụ
                        TextFormField(
                          controller: codeController,
                          decoration: _buildInputDecoration(
                            'Mã dịch vụ *',
                            Icons.qr_code_rounded,
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Vui lòng nhập mã dịch vụ'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: nameController,
                          decoration: _buildInputDecoration(
                            'Tên dịch vụ *',
                            Icons.medical_services_rounded,
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Vui lòng nhập tên dịch vụ'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // 2. Danh mục dịch vụ
                        TextFormField(
                          controller: categoryController,
                          decoration: _buildInputDecoration(
                            'Danh mục (vd: Nhổ răng, Thẩm mỹ) *',
                            Icons.category_rounded,
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Vui lòng nhập danh mục'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // 3. Thời gian thực hiện & Giá cả
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: durationController,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration(
                                  'Thời gian (Phút)',
                                  Icons.hourglass_top_rounded,
                                ),
                                validator: (val) {
                                  if (val != null &&
                                      val.isNotEmpty &&
                                      int.tryParse(val) == null) {
                                    return 'Phải là số nguyên';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration(
                                  'Giá (VNĐ) *',
                                  Icons.attach_money_rounded,
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty)
                                    return 'Vui lòng nhập giá';
                                  if (double.tryParse(val) == null)
                                    return 'Giá không hợp lệ';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 4. Mô tả chi tiết
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: _buildInputDecoration(
                            'Mô tả chi tiết',
                            Icons.description_rounded,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 5. Trạng thái hoạt động (Switch)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.toggle_on_rounded,
                                    color: primaryTeal,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Trạng thái hoạt động',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: statusValue,
                                activeColor: primaryTeal,
                                onChanged: (value) {
                                  setDialogState(() {
                                    statusValue = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Hiển thị vòng xoay Loading chờ gọi API
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Center(
                          child: CircularProgressIndicator(color: primaryTeal),
                        ),
                      );

                      try {
                        // 1. Khởi tạo Object Service từ Form nhập liệu
                        final newService = Service(
                          id: '', // id truyền trống vì backend tự tạo khi POST
                          serviceCode: codeController.text.trim(),
                          serviceName: nameController.text.trim(),
                          category: categoryController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          duration_minutes: durationController.text.isEmpty
                              ? null
                              : int.parse(durationController.text),
                          price: double.parse(priceController.text),
                          status: statusValue,
                          createdAt: DateTime.now(),
                        );

                        // 2. Chuyển Object sang Map thông qua hàm toJson() và gọi chuẩn API createService
                        await ServiceApi.createService(newService.toJson());

                        Navigator.pop(context); // Tắt loading spinner
                        Navigator.pop(context); // Đóng Dialog Form

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thêm dịch vụ mới thành công!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        fetchServices(); // Tải lại danh sách mới
                      } catch (e) {
                        Navigator.pop(context); // Tắt loading spinner
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Có lỗi xảy ra: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Thêm mới',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hàm tiện ích tạo style đồng bộ cho Input Fields
  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: primaryTeal, fontSize: 14),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryTeal, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIcon: Icon(icon, color: primaryTeal, size: 22),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  // Giao diện Dialog chỉnh sửa giá hiện đại
  void showEditPrice(Service service) {
    final priceController = TextEditingController(
      text: service.price.toString(),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: primaryTeal, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Cập nhật giá dịch vụ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.serviceName,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: _buildInputDecoration(
                'Giá mới (VNĐ)',
                Icons.attach_money_rounded,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text) ?? 0;
              await ServiceApi.updatePrice(service.id, newPrice);
              Navigator.pop(context);
              fetchServices();
            },
            child: const Text(
              'Lưu thay đổi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Giao diện Dialog lịch sử giá
  void showPriceHistory(Service service) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: primaryTeal)),
    );

    final history = await ServiceApi.getPriceHistory(service.id);
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Lịch sử giá: ${service.serviceName}',
          style: TextStyle(
            color: darkTeal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: 360,
          child: history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Chưa có lịch sử thay đổi giá.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey[200], height: 1),
                  itemBuilder: (_, index) {
                    final h = history[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: primaryTeal, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${h.oldPrice} ',
                                        style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const TextSpan(text: ' → '),
                                      TextSpan(
                                        text: '${h.newPrice} VNĐ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: darkTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cập nhật: ${h.updatedAt}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Giao diện Dialog xác nhận xóa dịch vụ
  void confirmDeleteService(Service service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text(
              'Xác nhận xóa dịch vụ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa dịch vụ "${service.serviceName}" khỏi bảng giá?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              // Hiển thị vòng xoay loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => Center(
                  child: CircularProgressIndicator(color: primaryTeal),
                ),
              );

              try {
                await ServiceApi.deleteService(service.id);
                Navigator.pop(context); // Tắt loading spinner
                Navigator.pop(context); // Đóng Dialog xác nhận
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa dịch vụ "${service.serviceName}" thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                fetchServices(); // Tải lại danh sách mới
              } catch (e) {
                Navigator.pop(context); // Tắt loading spinner
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Có lỗi xảy ra khi xóa: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Xóa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thiết lập giá dịch vụ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryTeal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchServices,
          ),
        ],
      ),

      // NÚT THÊM DỊCH VỤ NỔI BẬT (FLOATING ACTION BUTTON)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddServiceDialog,
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm dịch vụ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      body: Column(
        children: [
          // THANH TÌM KIẾM
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: TextField(
              controller: searchController,
              onChanged: filterServices,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên dịch vụ nha khoa...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                prefixIcon: Icon(Icons.search_rounded, color: primaryTeal),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          searchController.clear();
                          filterServices('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: primaryTeal.withOpacity(0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // DANH SÁCH HIỂN THỊ DỊCH VỤ
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryTeal))
                : filteredServices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy dịch vụ phù hợp',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: filteredServices.length,
                    itemBuilder: (_, i) {
                      final s = filteredServices[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[100]!, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: s.status ? lightTeal : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.medical_services_outlined,
                                color: s.status
                                    ? primaryTeal
                                    : Colors.grey[500],
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.serviceName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: s.status
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                if (!s.status)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Tắt',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mã: ${s.serviceCode}  |  Mục: ${s.category}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Giá: '),
                                        TextSpan(
                                          text: '${s.price} VNĐ',
                                          style: TextStyle(
                                            color: darkTeal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: primaryTeal,
                                  ),
                                  tooltip: 'Chỉnh sửa giá',
                                  onPressed: () => showEditPrice(s),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.history_toggle_off_rounded,
                                    color: Colors.blueGrey[400],
                                  ),
                                  tooltip: 'Xem lịch sử',
                                  onPressed: () => showPriceHistory(s),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Xóa dịch vụ',
                                  onPressed: () => confirmDeleteService(s),
                                ),
                              ],
                            ),
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
