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
    // Khi tải xong, khởi tạo danh sách hiển thị ban đầu
    filteredServices = List.from(services);
    // Reset lại ô tìm kiếm nếu có dữ liệu cũ
    searchController.clear();
    setState(() => isLoading = false);
  }

  // Hàm xử lý logic tìm kiếm (Không phân biệt chữ hoa, chữ thường, dấu)
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
              decoration: InputDecoration(
                labelText: 'Giá mới (VNĐ)',
                labelStyle: TextStyle(color: primaryTeal),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryTeal, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.attach_money, color: primaryTeal),
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
              fetchServices(); // Tải lại dữ liệu mới từ API
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

  // Giao diện Dialog lịch sử giá dạng Timeline
  void showPriceHistory(Service service) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: primaryTeal)),
    );

    final history = await ServiceApi.getPriceHistory(service.id);
    Navigator.pop(context); // Tắt loading

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
      body: Column(
        children: [
          // THANH TÌM KIẾM HIỆN ĐẠI (SEARCH BAR)
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

          // DANH SÁCH DỊCH VỤ
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
                    padding: const EdgeInsets.all(16),
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
                                color: lightTeal,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.medical_services_outlined,
                                color: primaryTeal,
                              ),
                            ),
                            title: Text(
                              s.serviceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Text(
                                    'Giá hiện tại: ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${s.price} VNĐ',
                                    style: TextStyle(
                                      color: darkTeal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
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
