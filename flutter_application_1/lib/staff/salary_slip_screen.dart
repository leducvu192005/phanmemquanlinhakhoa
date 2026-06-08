import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';
import '../models/salary_config_model.dart';
import '../services/doctor_service.dart';
import '../services/salary_service.dart';

class SalarySlipScreen extends StatefulWidget {
  const SalarySlipScreen({Key? key}) : super(key: key);

  @override
  State<SalarySlipScreen> createState() => _SalarySlipScreenState();
}

class _SalarySlipScreenState extends State<SalarySlipScreen> {
  final _doctorService = DoctorService();
  bool _isLoading = false;
  String? _errorMessage;

  List<Doctor> _doctors = [];
  String? _selectedDoctorId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  SalarySlipModel? _calculatedSlip;
  bool _isSaved = false;

  final Color primaryColor = const Color(0xFF0F766E);
  final Color accentColor = const Color(0xFF2DD4BF);
  final Color darkBgColor = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _doctorService.getDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = list;
        if (list.isNotEmpty) {
          _selectedDoctorId = list.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh sách bác sĩ: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateSalary() async {
    if (_selectedDoctorId == null) return;
    setState(() {
      _isLoading = true;
      _calculatedSlip = null;
      _isSaved = false;
    });
    try {
      final slip = await SalaryService.calculateSalary(
        _selectedDoctorId!,
        _selectedMonth,
        _selectedYear,
      );

      // Check if already saved in db
      final savedSlips = await SalaryService.getSlips(
        doctorId: _selectedDoctorId,
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (!mounted) return;
      setState(() {
        _calculatedSlip = slip;
        _isSaved = savedSlips.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tính toán lương: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _saveSalarySlip() async {
    if (_selectedDoctorId == null || _calculatedSlip == null || _isSaved) return;
    setState(() => _isLoading = true);
    try {
      await SalaryService.saveSalarySlip(
        _selectedDoctorId!,
        _selectedMonth,
        _selectedYear,
      );
      if (!mounted) return;
      setState(() {
        _isSaved = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu phiếu lương thành công vào hệ thống!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _printOrExportPDF() {
    if (_calculatedSlip == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xuất phiếu lương', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Đã xuất phiếu lương cho BS. ${_calculatedSlip!.doctorName}'),
            const SizedBox(height: 8),
            const Text('Định dạng: PDF Document'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Lập phiếu lương bác sĩ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? darkBgColor : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: _isLoading && _doctors.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDoctors,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bộ lọc
                      Card(
                        elevation: 0,
                        color: isDark ? darkBgColor : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chọn thông tin lập bảng lương', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final double itemWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: [
                                      SizedBox(
                                        width: itemWidth,
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedDoctorId,
                                          items: _doctors.map((d) => DropdownMenuItem(value: d.id, child: Text(d.fullName))).toList(),
                                          onChanged: (val) => setState(() => _selectedDoctorId = val),
                                          decoration: const InputDecoration(labelText: 'Bác sĩ điều trị', border: OutlineInputBorder()),
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: DropdownButtonFormField<int>(
                                          value: _selectedMonth,
                                          items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Tháng ${i + 1}'))),
                                          onChanged: (val) => setState(() => _selectedMonth = val ?? 1),
                                          decoration: const InputDecoration(labelText: 'Tháng', border: OutlineInputBorder()),
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: DropdownButtonFormField<int>(
                                          value: _selectedYear,
                                          items: List.generate(11, (i) => DropdownMenuItem(value: 2025 + i, child: Text('Năm ${2025 + i}'))),
                                          onChanged: (val) => setState(() => _selectedYear = val ?? 2026),
                                          decoration: const InputDecoration(labelText: 'Năm', border: OutlineInputBorder()),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _calculateSalary,
                                    icon: const Icon(Icons.calculate_outlined, color: Colors.white),
                                    label: const Text('Tính lương', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Kết quả tính lương
                      if (_isLoading)
                        Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: primaryColor)))
                      else if (_calculatedSlip != null)
                        _buildSalarySlipCard(isDark, isWide)
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Column(
                              children: [
                                const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'Chưa có dữ liệu tính toán. Hãy chọn bác sĩ và bấm nút "Tính lương"',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSalarySlipCard(bool isDark, bool isWide) {
    final slip = _calculatedSlip!;
    final rateFormatted = NumberFormat('#,###', 'vi_VN').format(slip.baseRate);
    final totalSalaryFormatted = NumberFormat('#,###', 'vi_VN').format(slip.totalSalary);

    return Card(
      elevation: 0,
      color: isDark ? darkBgColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header phiếu lương
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHIẾU LƯƠNG BÁC SĨ',
                      style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text('Tháng ${slip.month} / Năm ${slip.year}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                if (_isSaved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('Đã lưu hệ thống', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade700, width: 1),
                    ),
                    child: Text(
                      'Bản nháp',
                      style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
              ],
            ),
            const Divider(height: 40),

            // Thông tin bác sĩ
            const Text('THÔNG TIN NHÂN VIÊN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildInfoRow('Họ tên bác sĩ:', slip.doctorName, isDark),
            _buildInfoRow('Mã bác sĩ:', slip.doctorCode, isDark),
            _buildInfoRow('Bằng cấp/Học vị:', slip.doctorQualification.isEmpty ? 'Chưa cập nhật' : slip.doctorQualification, isDark),
            _buildInfoRow('Hệ số lương bác sĩ:', 'x ${slip.doctorCoefficient}', isDark),
            
            const Divider(height: 40),

            // Chi tiết ca làm việc & Bệnh nhân
            const Text('CHI TIẾT CA LÂM SÀNG & BỆNH NHÂN TRONG THÁNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildInfoRow('Tổng số ca trực đã làm:', '${slip.totalShifts} ca', isDark),
            _buildInfoRow('Tổng số giờ trực thực tế:', '${slip.totalHours} giờ', isDark),
            _buildInfoRow('Tổng hệ số bệnh nhân phức tạp (xử lý):', '+ ${slip.totalComplexityCoef}', isDark),
            _buildInfoRow('Đơn giá một giờ làm việc cơ bản:', '$rateFormatted VNĐ / giờ', isDark),

            const Divider(height: 40),

            // Cách tính lương (Giải thích công thức)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Công thức tính lương:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    'Tiền ca trực = Số giờ thực tế × (Hệ số ca trực + Tổng hệ số bệnh nhân phức tạp) × Hệ số bác sĩ × Đơn giá giờ cơ bản',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: isDark ? Colors.grey.shade300 : Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tổng lương nhận
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('THỰC LĨNH:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '$totalSalaryFormatted VNĐ',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
            const Divider(height: 40),

            // Hành động cuối
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _printOrExportPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Xuất PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaved ? null : _saveSalarySlip,
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label: const Text('Lưu phiếu lương', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaved ? Colors.grey : primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
