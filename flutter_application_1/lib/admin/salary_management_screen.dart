import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/salary_config_model.dart';
import '../services/salary_service.dart';

class SalaryManagementScreen extends StatefulWidget {
  const SalaryManagementScreen({Key? key}) : super(key: key);

  @override
  State<SalaryManagementScreen> createState() => _SalaryManagementScreenState();
}

class _SalaryManagementScreenState extends State<SalaryManagementScreen> {
  int _activeTab = 0; // 0: Mức tiền cơ bản, 1: Hệ số ca làm việc, 2: Hệ số ca phức tạp
  bool _isLoading = true;
  String? _errorMessage;

  List<SalaryConfigModel> _configs = [];
  List<SalaryShiftCoefficientModel> _shifts = [];
  List<SalaryComplexityCoefficientModel> _complexities = [];

  final Color primaryColor = const Color(0xFF0F766E); // Deep Teal
  final Color accentColor = const Color(0xFF2DD4BF); // Light Teal
  final Color darkBgColor = const Color(0xFF1E293B); // Dark slate for Dark Mode support

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final configs = await SalaryService.getConfigs();
      final shifts = await SalaryService.getShifts();
      final complexities = await SalaryService.getComplexities();

      if (!mounted) return;
      setState(() {
        _configs = configs;
        _shifts = shifts;
        _complexities = complexities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu cấu hình lương: $e';
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // actions - config
  // ==========================================
  Future<void> _addBaseRate() async {
    final formKey = GlobalKey<FormState>();
    final rateController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thiết lập mức lương cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mức tiền cơ bản (VNĐ/giờ)',
                    border: OutlineInputBorder(),
                    prefixText: 'đ ',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Vui lòng nhập mức tiền';
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) return 'Mức tiền phải lớn hơn 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày áp dụng',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final rate = double.parse(rateController.text);
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      await SalaryService.createConfig(rate, dateStr);
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiết lập mức lương cơ bản thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ==========================================
  // actions - shifts
  // ==========================================
  Future<void> _addOrEditShift({SalaryShiftCoefficientModel? shift}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: shift?.shiftName);
    final coefController = TextEditingController(text: shift?.coefficient.toString() ?? '1.0');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(shift == null ? 'Thêm hệ số ca làm việc' : 'Sửa hệ số ca làm việc', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                enabled: shift == null, // Không cho sửa tên ca đã có để tránh trùng map
                decoration: const InputDecoration(
                  labelText: 'Tên ca / ngày',
                  hintText: 'VD: Ca tối, Thứ 7, Chủ nhật...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tên ca hoặc ngày';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: coefController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Hệ số lương',
                  hintText: 'VD: 1.2, 1.5...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Vui lòng nhập hệ số';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Hệ số phải là số dương lớn hơn 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final name = nameController.text.trim();
      final coef = double.parse(coefController.text);
      if (shift == null) {
        await SalaryService.createShift(name, coef);
      } else {
        await SalaryService.updateShift(shift.id, name, coef);
      }
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu hệ số ca làm việc thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteShift(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa hệ số ca làm việc này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Quay lại')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await SalaryService.deleteShift(id);
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa hệ số ca thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ==========================================
  // actions - complexities
  // ==========================================
  Future<void> _addOrEditComplexity({SalaryComplexityCoefficientModel? complexity}) async {
    final formKey = GlobalKey<FormState>();
    final levelController = TextEditingController(text: complexity?.complexityLevel);
    final coefController = TextEditingController(text: complexity?.coefficient.toString() ?? '0.0');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(complexity == null ? 'Thêm hệ số ca phức tạp' : 'Sửa hệ số ca phức tạp', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: levelController,
                enabled: complexity == null, // Không cho sửa tên để tránh mất map
                decoration: const InputDecoration(
                  labelText: 'Mức độ phức tạp',
                  hintText: 'VD: Khó, Khó vừa, Rất khó...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mức độ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: coefController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Hệ số tăng thêm',
                  hintText: 'VD: 0.1, 0.3...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Vui lòng nhập hệ số';
                  final num = double.tryParse(val);
                  if (num == null || num < 0) return 'Hệ số phải là số lớn hơn hoặc bằng 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final level = levelController.text.trim();
      final coef = double.parse(coefController.text);
      if (complexity == null) {
        await SalaryService.createComplexity(level, coef);
      } else {
        await SalaryService.updateComplexity(complexity.id, level, coef);
      }
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu hệ số thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteComplexity(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa hệ số ca phức tạp này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Quay lại')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await SalaryService.deleteComplexity(id);
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa hệ số thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Cấu hình tham số lương', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? darkBgColor : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAllData,
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                          child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : Row(
                  children: [
                    // Giao diện bên trái: Tab selector
                    Container(
                      width: isWide ? 260 : 76,
                      decoration: BoxDecoration(
                        color: isDark ? darkBgColor : Colors.white,
                        border: Border(
                          right: BorderSide(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        children: [
                          _buildSidebarItem(0, Icons.monetization_on_outlined, 'Mức tiền cơ bản', isWide),
                          _buildSidebarItem(1, Icons.schedule_outlined, 'Hệ số ca làm việc', isWide),
                          _buildSidebarItem(2, Icons.health_and_safety_outlined, 'Hệ số ca phức tạp', isWide),
                        ],
                      ),
                    ),

                    // Giao diện bên phải: Nội dung chi tiết
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Card(
                          elevation: 0,
                          color: isDark ? darkBgColor : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: _buildActiveTabContent(isDark),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, bool isWide) {
    final bool isSelected = _activeTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? primaryColor : Colors.grey, size: 24),
              if (isWide) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryColor : Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDark) {
    switch (_activeTab) {
      case 0:
        return _buildBaseRateTab(isDark);
      case 1:
        return _buildShiftTab(isDark);
      case 2:
        return _buildComplexityTab(isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBaseRateTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lịch sử áp dụng mức lương cơ bản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _addBaseRate,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thiết lập mới', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _configs.isEmpty
              ? _buildEmptyState('Không có lịch sử cấu hình lương cơ bản')
              : ListView.separated(
                  itemCount: _configs.length,
                  separatorBuilder: (_, __) => Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade100),
                  itemBuilder: (context, idx) {
                    final conf = _configs[idx];
                    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.parse(conf.effectiveDate));
                    final rateFormatted = NumberFormat('#,###', 'vi_VN').format(conf.baseSalaryPerHour);
                    final isFirst = idx == 0;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isFirst ? primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.payments_outlined, color: isFirst ? primaryColor : Colors.grey, size: 24),
                      ),
                      title: Text(
                        '$rateFormatted VNĐ / giờ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                          color: isFirst ? primaryColor : null,
                        ),
                      ),
                      subtitle: Text('Ngày hiệu lực: $dateStr'),
                      trailing: isFirst
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Đang áp dụng',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          : const Text('Hết hạn', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildShiftTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Danh sách hệ số ca làm việc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _addOrEditShift(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm hệ số', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _shifts.isEmpty
              ? _buildEmptyState('Không có dữ liệu hệ số ca làm việc')
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(isDark ? Colors.grey.shade800 : const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('Tên ca / ngày', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Hệ số lương', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _shifts.map((s) {
                        return DataRow(
                          cells: [
                            DataCell(Text(s.shiftName, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text('x ${s.coefficient}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _addOrEditShift(shift: s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _deleteShift(s.id),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildComplexityTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Danh sách hệ số xử lý ca phức tạp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _addOrEditComplexity(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm hệ số', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _complexities.isEmpty
              ? _buildEmptyState('Không có dữ liệu hệ số ca phức tạp')
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(isDark ? Colors.grey.shade800 : const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('Mức độ phức tạp', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Hệ số tăng thêm', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _complexities.map((c) {
                        return DataRow(
                          cells: [
                            DataCell(Text(c.complexityLevel, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text('+ ${c.coefficient}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _addOrEditComplexity(complexity: c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _deleteComplexity(c.id),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}
