import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service.dart';
import '../services/service_api.dart';

class PatientServiceListScreen extends StatefulWidget {
  const PatientServiceListScreen({super.key});

  @override
  State<PatientServiceListScreen> createState() => _PatientServiceListScreenState();
}

class _PatientServiceListScreenState extends State<PatientServiceListScreen> {
  final Color primaryColor = const Color(0xFF0D9488);
  final Color accentColor = const Color(0xFF2DD4BF);
  final Color bgLight = const Color(0xFFF0FDFA);

  List<Service> _services = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final list = await ServiceApi.getServices();
      if (mounted) {
        setState(() {
          _services = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _categories {
    final set = <String>{};
    for (var s in _services) {
      if (s.category.isNotEmpty) {
        set.add(s.category);
      }
    }
    return ['Tất cả', ...set.toList()];
  }

  List<Service> get _filteredServices {
    return _services.where((s) {
      final matchesSearch = s.serviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.description != null && s.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesCategory = _selectedCategory == 'Tất cả' || s.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredServices;
    final cats = _categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Dịch vụ của chúng tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: primaryColor.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // Thanh tìm kiếm
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm dịch vụ nha khoa...',
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Lọc theo danh mục (chọn nhanh bằng chip)
                if (cats.length > 1)
                  Container(
                    height: 52,
                    color: Colors.white,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: cats.length,
                      itemBuilder: (ctx, idx) {
                        final catName = cats[idx];
                        final isSelected = _selectedCategory == catName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              catName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                _selectedCategory = catName;
                              });
                            },
                            selectedColor: primaryColor,
                            checkmarkColor: Colors.white,
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? primaryColor : Colors.grey.shade300,
                                width: 0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Không tìm thấy dịch vụ nào phù hợp',
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadServices,
                          color: primaryColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, idx) {
                              final s = filtered[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: bgLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.check_circle_outline, color: primaryColor, size: 24),
                                      ),
                                      title: Text(
                                        s.serviceName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        s.category,
                                        style: const TextStyle(fontSize: 12, color: Colors.black45),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${NumberFormat('#,###', 'vi_VN').format(s.price)}đ',
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (s.duration_minutes != null)
                                            Text(
                                              '~${s.duration_minutes} phút',
                                              style: const TextStyle(fontSize: 11, color: Colors.black38),
                                            ),
                                        ],
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Divider(height: 16),
                                              Text(
                                                s.description ?? 'Không có mô tả chi tiết cho dịch vụ này. Vui lòng liên hệ hotline phòng khám để được tư vấn thêm.',
                                                style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Mã dịch vụ: ${s.serviceCode}',
                                                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      // Quay về màn đặt lịch
                                                      Navigator.pop(context, true);
                                                    },
                                                    icon: const Icon(Icons.calendar_month, size: 16),
                                                    label: const Text('Đặt lịch ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: primaryColor,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
