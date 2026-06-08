import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/doctor_model.dart';
import '../models/salary_config_model.dart';
import '../services/doctor_service.dart';
import '../services/salary_service.dart';

class SalaryReportScreen extends StatefulWidget {
  const SalaryReportScreen({Key? key}) : super(key: key);

  @override
  State<SalaryReportScreen> createState() => _SalaryReportScreenState();
}

class _SalaryReportScreenState extends State<SalaryReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _doctorService = DoctorService();
  bool _isLoading = false;
  String? _errorMessage;

  List<Doctor> _doctors = [];
  String? _selectedDoctorId;
  
  // Tab 1 state
  int _t1Month = DateTime.now().month;
  int _t1Year = DateTime.now().year;
  MonthlySalaryReportModel? _t1Report;

  // Tab 2 state
  int _t2Year = DateTime.now().year;
  YearlyDoctorSalaryReportModel? _t2Report;

  // Tab 3 state
  int _t3Year = DateTime.now().year;
  YearlyAllDoctorSalaryReportModel? _t3Report;

  final Color primaryColor = const Color(0xFF0F766E);
  final Color accentColor = const Color(0xFF2DD4BF);
  final Color darkBgColor = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _loadTabReport();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _doctorService.getDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = list;
        if (list.isNotEmpty) {
          _selectedDoctorId = list.first.id;
        }
      });
      await _loadTabReport();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Lỗi khởi tạo dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTabReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_tabController.index == 0) {
        final r1 = await SalaryService.getMonthlyReport(_t1Month, _t1Year);
        if (!mounted) return;
        setState(() {
          _t1Report = r1;
          _isLoading = false;
        });
      } else if (_tabController.index == 1) {
        if (_selectedDoctorId != null) {
          final r2 = await SalaryService.getYearlyDoctorReport(_selectedDoctorId!, _t2Year);
          if (!mounted) return;
          setState(() {
            _t2Report = r2;
            _isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() => _isLoading = false);
        }
      } else if (_tabController.index == 2) {
        final r3 = await SalaryService.getYearlyAllReport(_t3Year);
        if (!mounted) return;
        setState(() {
          _t3Report = r3;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Lỗi tải báo cáo: $e';
        _isLoading = false;
      });
    }
  }

  void _exportExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xuất báo cáo ra file Excel (lưu ở thư mục Downloads)'), backgroundColor: Colors.green),
    );
  }

  void _exportPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xuất báo cáo ra file PDF (lưu ở thư mục Downloads)'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Báo cáo tiền lương bác sĩ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? darkBgColor : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_view_month_outlined), text: 'Lương bác sĩ theo tháng'),
            Tab(icon: Icon(Icons.person_outline), text: 'Lương cá nhân theo năm'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Tổng quỹ lương theo năm'),
          ],
        ),
      ),
      body: _isLoading && _t1Report == null && _t2Report == null && _t3Report == null
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
                        onPressed: _loadTabReport,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text('Tải lại'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMonthlyTab(isDark),
                    _buildYearlyDoctorTab(isDark),
                    _buildYearlyAllTab(isDark),
                  ],
                ),
    );
  }

  // ==========================================
  // TAB 1: Monthly payroll report
  // ==========================================
  Widget _buildMonthlyTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter bar
          Card(
            elevation: 0,
            color: isDark ? darkBgColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _t1Month,
                      items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Tháng ${i + 1}'))),
                      onChanged: (val) {
                        setState(() => _t1Month = val ?? 1);
                        _loadTabReport();
                      },
                      decoration: const InputDecoration(labelText: 'Tháng', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _t1Year,
                      items: List.generate(11, (i) => DropdownMenuItem(value: 2025 + i, child: Text('Năm ${2025 + i}'))),
                      onChanged: (val) {
                        setState(() => _t1Year = val ?? 2026);
                        _loadTabReport();
                      },
                      decoration: const InputDecoration(labelText: 'Năm', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 24),
                  OutlinedButton.icon(
                    onPressed: _exportExcel,
                    icon: const Icon(Icons.table_view, color: Colors.green),
                    label: const Text('Xuất Excel', style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _exportPDF,
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    label: const Text('Xuất PDF', style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Table
          Expanded(
            child: Card(
              elevation: 0,
              color: isDark ? darkBgColor : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _t1Report == null || _t1Report!.items.isEmpty
                    ? _buildEmptyState('Không có dữ liệu tiền lương cho tháng này')
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(isDark ? Colors.grey.shade900 : const Color(0xFFF8FAFC)),
                            columns: const [
                              DataColumn(label: Text('Mã bác sĩ', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Họ tên bác sĩ', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Số ca làm việc', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Tổng giờ làm', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Tổng tiền lương', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _t1Report!.items.map((item) {
                              final salaryFormatted = NumberFormat('#,###', 'vi_VN').format(item.totalSalary);
                              return DataRow(
                                cells: [
                                  DataCell(Text(item.doctorCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w500))),
                                  DataCell(Text('${item.totalShifts} ca')),
                                  DataCell(Text('${item.totalHours} giờ')),
                                  DataCell(Text('$salaryFormatted VNĐ', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: Annual personal payroll report
  // ==========================================
  Widget _buildYearlyDoctorTab(bool isDark) {
    final report = _t2Report;
    final totalSalaryFormatted = report != null ? NumberFormat('#,###', 'vi_VN').format(report.totalSalaryYear) : '0';
    final avgSalaryFormatted = report != null ? NumberFormat('#,###', 'vi_VN').format(report.averageSalaryMonth) : '0';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter bar
          Card(
            elevation: 0,
            color: isDark ? darkBgColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDoctorId,
                      items: _doctors.map((d) => DropdownMenuItem(value: d.id, child: Text(d.fullName))).toList(),
                      onChanged: (val) {
                        setState(() => _selectedDoctorId = val);
                        _loadTabReport();
                      },
                      decoration: const InputDecoration(labelText: 'Chọn bác sĩ', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _t2Year,
                      items: List.generate(11, (i) => DropdownMenuItem(value: 2025 + i, child: Text('Năm ${2025 + i}'))),
                      onChanged: (val) {
                        setState(() => _t2Year = val ?? 2026);
                        _loadTabReport();
                      },
                      decoration: const InputDecoration(labelText: 'Năm', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (report != null) ...[
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Tổng tiền lương cả năm',
                    '$totalSalaryFormatted VNĐ',
                    Icons.payments_outlined,
                    primaryColor,
                    isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Lương trung bình tháng',
                    '$avgSalaryFormatted VNĐ',
                    Icons.equalizer_outlined,
                    accentColor,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Line chart & Table split
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line Chart (left side)
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 0,
                      color: isDark ? darkBgColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Biểu đồ xu hướng lương 12 tháng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 40),
                            Expanded(
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: 1,
                                        getTitlesWidget: (val, meta) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text('T${val.toInt()}'),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: report.months.map((m) {
                                        // divide by 1 million to keep chart clean
                                        return FlSpot(m.month.toDouble(), m.totalSalary / 1000000.0);
                                      }).toList(),
                                      isCurved: true,
                                      color: primaryColor,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: primaryColor.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Table (right side)
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 0,
                      color: isDark ? darkBgColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView.separated(
                          itemCount: report.months.length,
                          separatorBuilder: (_, __) => Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade100, height: 1),
                          itemBuilder: (context, idx) {
                            final monthItem = report.months[idx];
                            final salaryFormatted = NumberFormat('#,###', 'vi_VN').format(monthItem.totalSalary);
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              title: Text('Tháng ${monthItem.month}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${monthItem.totalShifts} ca | ${monthItem.totalHours} giờ'),
                              trailing: Text('$salaryFormatted đ', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: Yearly all doctors payroll report
  // ==========================================
  Widget _buildYearlyAllTab(bool isDark) {
    final report = _t3Report;
    final totalPoolFormatted = report != null ? NumberFormat('#,###', 'vi_VN').format(report.totalPool) : '0';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter bar
          Card(
            elevation: 0,
            color: isDark ? darkBgColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _t3Year,
                      items: List.generate(11, (i) => DropdownMenuItem(value: 2025 + i, child: Text('Năm ${2025 + i}'))),
                      onChanged: (val) {
                        setState(() => _t3Year = val ?? 2026);
                        _loadTabReport();
                      },
                      decoration: const InputDecoration(labelText: 'Chọn năm xem báo cáo', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (report != null) ...[
            // Quỹ lương
            Card(
              elevation: 0,
              color: primaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TỔNG QUỸ LƯƠNG BÁC SĨ CẢ NĂM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          '$totalPoolFormatted VNĐ',
                          style: TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Icon(Icons.account_balance_wallet_outlined, color: primaryColor, size: 48),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Charts split
            Expanded(
              child: Row(
                children: [
                  // Bar Chart
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: isDark ? darkBgColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Biểu đồ cột lương so sánh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 32),
                            Expanded(
                              child: BarChart(
                                BarChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          final idx = val.toInt();
                                          if (idx >= 0 && idx < report.items.length) {
                                            final name = report.items[idx].fullName;
                                            final shortName = name.split(' ').last;
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(shortName, style: const TextStyle(fontSize: 11)),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(report.items.length, (i) {
                                    final item = report.items[i];
                                    return BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: item.totalSalary / 1000000.0,
                                          color: primaryColor,
                                          width: 16,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Pie Chart
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: isDark ? darkBgColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tỷ lệ phân phối quỹ lương', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 24),
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                  sections: List.generate(report.items.length, (i) {
                                    final item = report.items[i];
                                    final percentage = report.totalPool > 0
                                        ? (item.totalSalary / report.totalPool) * 100.0
                                        : 0.0;
                                    // Generate different colors
                                    final colors = [
                                      primaryColor,
                                      accentColor,
                                      Colors.amber,
                                      Colors.indigo,
                                      Colors.orange,
                                      Colors.redAccent,
                                      Colors.purple,
                                    ];
                                    final col = colors[i % colors.length];

                                    return PieChartSectionData(
                                      color: col,
                                      value: item.totalSalary,
                                      title: '${percentage.toStringAsFixed(1)}%',
                                      radius: 50,
                                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Legend
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: List.generate(report.items.length, (i) {
                                final item = report.items[i];
                                final colors = [
                                  primaryColor,
                                  accentColor,
                                  Colors.amber,
                                  Colors.indigo,
                                  Colors.orange,
                                  Colors.redAccent,
                                  Colors.purple,
                                ];
                                final col = colors[i % colors.length];
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 12, height: 12, color: col),
                                    const SizedBox(width: 4),
                                    Text(item.fullName, style: const TextStyle(fontSize: 11)),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? darkBgColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
      ),
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
