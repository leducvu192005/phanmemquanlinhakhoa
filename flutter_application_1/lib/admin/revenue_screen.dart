import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'revenue_controller.dart';
import 'revenue_model.dart';

// Conditional imports for platform-independent file saving
import '../utils/exporter_stub.dart'
    if (dart.library.html) '../utils/exporter_web.dart'
    if (dart.library.io) '../utils/exporter_non_web.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  final RevenueController _controller = RevenueController();

  final Color primaryTeal = const Color(0xFF00A896);
  final Color darkTeal = const Color(0xFF028090);
  final Color lightTeal = const Color(0xFFF0FDFA);
  final Color accentOrange = const Color(0xFFF59E0B);
  final Color bgGrey = const Color(0xFFF8FAFC);

  // Sorting columns locally for Doctors and Services tables
  String _doctorSortCol = 'revenue';
  bool _doctorAscending = false;
  String _serviceSortCol = 'revenue';
  bool _serviceAscending = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _controller.startDate != null && _controller.endDate != null
          ? DateTimeRange(
              start: _controller.startDate!,
              end: _controller.endDate!,
            )
          : null,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _controller.setDateRange(picked.start, picked.end);
    }
  }

  void _exportExcel(RevenueReport report, String rangeText) {
    final buffer = StringBuffer();
    // UTF-8 BOM so MS Excel reads diacritics correctly
    buffer.write('\uFEFF');

    buffer.writeln('BÁO CÁO DOANH THU PHÒNG KHÁM NHA KHOA');
    buffer.writeln('Khoảng thời gian: $rangeText');
    buffer.writeln();

    buffer.writeln('TỔNG QUAN CHỈ SỐ');
    buffer.writeln('Chỉ số,Giá trị (VNĐ)');
    buffer.writeln('Tổng doanh thu,${report.totalRevenue}');
    buffer.writeln('Doanh thu hôm nay,${report.todayRevenue}');
    buffer.writeln('Doanh thu tháng này,${report.monthRevenue}');
    buffer.writeln('Tổng số lượt thanh toán,${report.totalPaidBookings}');
    buffer.writeln();

    buffer.writeln('DOANH THU THEO BÁC SĨ');
    buffer.writeln('Tên bác sĩ,Số ca khám,Doanh thu (VNĐ)');
    for (var doc in report.doctorRevenue) {
      buffer.writeln('"${doc.doctorName}",${doc.bookingCount},${doc.revenue}');
    }
    buffer.writeln();

    buffer.writeln('DOANH THU THEO DỊCH VỤ');
    buffer.writeln('Tên dịch vụ,Số lượt sử dụng,Doanh thu (VNĐ)');
    for (var svc in report.serviceRevenue) {
      buffer.writeln('"${svc.serviceName}",${svc.count},${svc.revenue}');
    }
    buffer.writeln();

    buffer.writeln('DANH SÁCH CHI TIẾT GIAO DỊCH');
    buffer.writeln(
      'Mã lịch khám,Bệnh nhân,Bác sĩ,Ngày thanh toán,Phương thức thanh toán,Giảm giá (VNĐ),Tổng tiền (VNĐ)',
    );
    for (var tx in report.transactions) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(tx.paymentTime);
      buffer.writeln(
        '${tx.bookingId},"${tx.patientName}","${tx.doctorName}",$dateStr,${tx.paymentMethod},${tx.discountAmount},${tx.totalAmount}',
      );
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    FileExporter.exportFile(
      'Bao_cao_doanh_thu_$dateStr.csv',
      buffer.toString(),
      mimeType: 'text/csv;charset=utf-8',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xuất Excel (CSV) thành công!'),
        backgroundColor: darkTeal,
      ),
    );
  }

  void _exportHtmlPdf(RevenueReport report, String rangeText) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="utf-8">');
    buffer.writeln('<title>Báo cáo doanh thu phòng khám Nha Khoa</title>');
    buffer.writeln('<style>');
    buffer.writeln(
      'body { font-family: sans-serif; margin: 40px; color: #333; }',
    );
    buffer.writeln('h1, h2 { color: #0f766e; }');
    buffer.writeln('.meta { margin-bottom: 20px; font-style: italic; }');
    buffer.writeln(
      '.kpi-container { display: flex; gap: 20px; margin-bottom: 30px; }',
    );
    buffer.writeln(
      '.kpi-card { flex: 1; padding: 15px; border: 1px solid #ddd; border-radius: 8px; background-color: #f0fdfa; text-align: center; }',
    );
    buffer.writeln(
      '.kpi-val { font-size: 20px; font-weight: bold; color: #0d9488; margin-top: 5px; }',
    );
    buffer.writeln(
      'table { width: 100%; border-collapse: collapse; margin-bottom: 35px; }',
    );
    buffer.writeln(
      'th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }',
    );
    buffer.writeln('th { background-color: #0f766e; color: white; }');
    buffer.writeln('tr:nth-child(even) { background-color: #f9f9f9; }');
    buffer.writeln('@media print { button { display: none; } }');
    buffer.writeln('</style>');
    buffer.writeln('<script>');
    buffer.writeln('window.onload = function() { window.print(); }');
    buffer.writeln('</script>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<h1>BÁO CÁO DOANH THU PHÒNG KHÁM NHA KHOA</h1>');
    buffer.writeln(
      '<div class="meta">Khoảng thời gian báo cáo: $rangeText</div>',
    );
    buffer.writeln(
      '<button onclick="window.print()" style="padding: 10px 20px; background-color: #0d9488; color: white; border: none; border-radius: 5px; cursor: pointer; margin-bottom: 20px; font-weight: bold;">In báo cáo / Lưu PDF</button>',
    );

    buffer.writeln('<div class="kpi-container">');
    buffer.writeln(
      '<div class="kpi-card"><div>Tổng doanh thu</div><div class="kpi-val">${_formatCurrency(report.totalRevenue)}</div></div>',
    );
    buffer.writeln(
      '<div class="kpi-card"><div>Doanh thu hôm nay</div><div class="kpi-val">${_formatCurrency(report.todayRevenue)}</div></div>',
    );
    buffer.writeln(
      '<div class="kpi-card"><div>Doanh thu tháng này</div><div class="kpi-val">${_formatCurrency(report.monthRevenue)}</div></div>',
    );
    buffer.writeln(
      '<div class="kpi-card"><div>Lượt thanh toán</div><div class="kpi-val">${report.totalPaidBookings}</div></div>',
    );
    buffer.writeln('</div>');

    buffer.writeln('<h2>1. Doanh thu theo bác sĩ</h2>');
    buffer.writeln('<table>');
    buffer.writeln(
      '<tr><th>Tên bác sĩ</th><th>Số ca khám</th><th>Doanh thu</th></tr>',
    );
    for (var doc in report.doctorRevenue) {
      buffer.writeln(
        '<tr><td>${doc.doctorName}</td><td>${doc.bookingCount}</td><td>${_formatCurrency(doc.revenue)}</td></tr>',
      );
    }
    buffer.writeln('</table>');

    buffer.writeln('<h2>2. Doanh thu theo dịch vụ</h2>');
    buffer.writeln('<table>');
    buffer.writeln(
      '<tr><th>Tên dịch vụ</th><th>Số lượt sử dụng</th><th>Doanh thu</th></tr>',
    );
    for (var svc in report.serviceRevenue) {
      buffer.writeln(
        '<tr><td>${svc.serviceName}</td><td>${svc.count}</td><td>${_formatCurrency(svc.revenue)}</td></tr>',
      );
    }
    buffer.writeln('</table>');

    buffer.writeln('<h2>3. Danh sách giao dịch chi tiết</h2>');
    buffer.writeln('<table>');
    buffer.writeln(
      '<tr><th>Mã lịch khám</th><th>Bệnh nhân</th><th>Bác sĩ</th><th>Ngày thanh toán</th><th>Phương thức</th><th>Giảm giá</th><th>Tổng tiền</th></tr>',
    );
    for (var tx in report.transactions) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(tx.paymentTime);
      buffer.writeln(
        '<tr><td>${tx.bookingId}</td><td>${tx.patientName}</td><td>${tx.doctorName}</td><td>$dateStr</td><td>${tx.paymentMethod}</td><td>${_formatCurrency(tx.discountAmount)}</td><td>${_formatCurrency(tx.totalAmount)}</td></tr>',
      );
    }
    buffer.writeln('</table>');

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    FileExporter.exportFile(
      'Bao_cao_doanh_thu_$dateStr.html',
      buffer.toString(),
      mimeType: 'text/html;charset=utf-8',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xuất file HTML PDF thành công!'),
        backgroundColor: darkTeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;
    final rangeText =
        _controller.startDate != null && _controller.endDate != null
        ? '${DateFormat('dd/MM/yyyy').format(_controller.startDate!)} - ${DateFormat('dd/MM/yyyy').format(_controller.endDate!)}'
        : 'Chọn khoảng thời gian';

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          'Thống kê doanh thu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Date Filter Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: darkTeal,
              side: BorderSide(color: primaryTeal.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(Icons.date_range_rounded, color: primaryTeal, size: 18),
            label: Text(
              rangeText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _selectDateRange,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Lọc',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _controller.loadReport(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _controller.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : _controller.errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${_controller.errorMessage}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _controller.loadReport(),
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            )
          : _controller.report == null
          ? const Center(child: Text('Không có dữ liệu báo cáo.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. STATS OVERVIEW CARDS
                  _buildSummaryCards(_controller.report!),
                  const SizedBox(height: 24),

                  // 2. CHARTS SECTION
                  _buildChartsSection(_controller.report!, isWide),
                  const SizedBox(height: 24),

                  // 3. DOCTORS & SERVICES BREAKDOWN
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildDoctorRevenueTable(
                                _controller.report!,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildServiceRevenueTable(
                                _controller.report!,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildDoctorRevenueTable(_controller.report!),
                            const SizedBox(height: 16),
                            _buildServiceRevenueTable(_controller.report!),
                          ],
                        ),
                  const SizedBox(height: 24),

                  // 4. TRANSACTIONS LIST LEDGER
                  _buildTransactionsTable(_controller.report!, rangeText),
                ],
              ),
            ),
    );
  }

  // 1. KPI Summary Cards Widget
  Widget _buildSummaryCards(RevenueReport report) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 1100 ? 4 : (width > 600 ? 2 : 1);
        final double childAspectRatio = width > 1100 ? 2.5 : 2.0;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildKpiCard(
              title: 'TỔNG DOANH THU',
              value: _formatCurrency(report.totalRevenue),
              icon: Icons.monetization_on_rounded,
              color: primaryTeal,
              subtitle: 'Doanh thu tích lũy toàn hệ thống',
            ),
            _buildKpiCard(
              title: 'DOANH THU HÔM NAY',
              value: _formatCurrency(report.todayRevenue),
              icon: Icons.today_rounded,
              color: darkTeal,
              subtitle:
                  'Hôm nay: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            ),
            _buildKpiCard(
              title: 'DOANH THU THÁNG NÀY',
              value: _formatCurrency(report.monthRevenue),
              icon: Icons.calendar_month_rounded,
              color: accentOrange,
              subtitle:
                  'Tháng hiện tại: ${DateFormat('MM/yyyy').format(DateTime.now())}',
            ),
            _buildKpiCard(
              title: 'LƯỢT THANH TOÁN',
              value: report.totalPaidBookings.toString(),
              icon: Icons.receipt_long_rounded,
              color: Colors.blue,
              subtitle: 'Tổng số hóa đơn đã thanh toán',
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Charts Section Widget (Line & Bar)
  Widget _buildChartsSection(RevenueReport report, bool isWide) {
    if (report.dailyRevenue.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Không có dữ liệu biểu đồ trong khoảng thời gian này.'),
        ),
      );
    }

    final dailyList = report.dailyRevenue;
    final List<FlSpot> lineSpots = [];
    final List<BarChartGroupData> barGroups = [];
    double maxVal = 1000000; // default minimum ceiling

    for (int i = 0; i < dailyList.length; i++) {
      final rev = dailyList[i].revenue;
      if (rev > maxVal) maxVal = rev;

      lineSpots.add(FlSpot(i.toDouble(), rev));
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: rev,
              color: primaryTeal,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal,
                color: primaryTeal.withOpacity(0.05),
              ),
            ),
          ],
        ),
      );
    }

    // Y Axis interval logic
    final double yInterval = maxVal / 5 == 0 ? 1 : maxVal / 5;

    Widget getBottomTitles(double value, TitleMeta meta) {
      final int idx = value.toInt();
      if (idx >= 0 && idx < dailyList.length) {
        final parsedDate = DateTime.tryParse(dailyList[idx].date);
        if (parsedDate != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              DateFormat('dd/MM').format(parsedDate),
              style: TextStyle(color: Colors.grey[500], fontSize: 9),
            ),
          );
        }
      }
      return const Text('');
    }

    Widget getLeftTitles(double value, TitleMeta meta) {
      if (value == 0) return const Text('0');
      if (value >= 1000000) {
        return Text('${(value / 1000000).toStringAsFixed(1)}M');
      }
      return Text('${(value / 1000).toStringAsFixed(0)}k');
    }

    final chartView = isWide
        ? Row(
            children: [
              // Line Chart
              Expanded(
                child: _buildChartContainer(
                  title: 'Xu hướng doanh thu (Line Chart)',
                  chart: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getBottomTitles,
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getLeftTitles,
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineSpots,
                          isCurved: true,
                          color: darkTeal,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeColor: darkTeal,
                                  strokeWidth: 2,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: darkTeal.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Bar Chart
              Expanded(
                child: _buildChartContainer(
                  title: 'Doanh thu theo ngày (Bar Chart)',
                  chart: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getBottomTitles,
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getLeftTitles,
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ),
            ],
          )
        : Column(
            children: [
              _buildChartContainer(
                title: 'Xu hướng doanh thu (Line Chart)',
                chart: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getBottomTitles,
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getLeftTitles,
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineSpots,
                          isCurved: true,
                          color: darkTeal,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: darkTeal.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildChartContainer(
                title: 'Doanh thu theo ngày (Bar Chart)',
                chart: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getBottomTitles,
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getLeftTitles,
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ),
            ],
          );

    return chartView;
  }

  Widget _buildChartContainer({required String title, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: chart),
        ],
      ),
    );
  }

  // 3. Doctor Table Widget
  Widget _buildDoctorRevenueTable(RevenueReport report) {
    // Sort logic
    final docs = List<DoctorRevenue>.from(report.doctorRevenue);
    docs.sort((a, b) {
      int cmp = 0;
      if (_doctorSortCol == 'name') {
        cmp = a.doctorName.compareTo(b.doctorName);
      } else if (_doctorSortCol == 'count') {
        cmp = a.bookingCount.compareTo(b.bookingCount);
      } else {
        cmp = a.revenue.compareTo(b.revenue);
      }
      return _doctorAscending ? cmp : -cmp;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu theo bác sĩ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey[100]!, width: 1),
            ),
            children: [
              // Header
              TableRow(
                children: [
                  _buildTableHeader(
                    'Bác sĩ',
                    'name',
                    _doctorSortCol,
                    _doctorAscending,
                    (col) {
                      setState(() {
                        if (_doctorSortCol == col) {
                          _doctorAscending = !_doctorAscending;
                        } else {
                          _doctorSortCol = col;
                          _doctorAscending = true;
                        }
                      });
                    },
                  ),
                  _buildTableHeader(
                    'Số ca',
                    'count',
                    _doctorSortCol,
                    _doctorAscending,
                    (col) {
                      setState(() {
                        if (_doctorSortCol == col) {
                          _doctorAscending = !_doctorAscending;
                        } else {
                          _doctorSortCol = col;
                          _doctorAscending = false;
                        }
                      });
                    },
                  ),
                  _buildTableHeader(
                    'Doanh thu',
                    'revenue',
                    _doctorSortCol,
                    _doctorAscending,
                    (col) {
                      setState(() {
                        if (_doctorSortCol == col) {
                          _doctorAscending = !_doctorAscending;
                        } else {
                          _doctorSortCol = col;
                          _doctorAscending = false;
                        }
                      });
                    },
                  ),
                ],
              ),
              // Data Rows
              if (docs.isEmpty)
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Không có dữ liệu'),
                    ),
                    const SizedBox(),
                    const SizedBox(),
                  ],
                )
              else
                ...docs.map((d) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          d.doctorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          d.bookingCount.toString(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          _formatCurrency(d.revenue),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkTeal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Service Table Widget
  Widget _buildServiceRevenueTable(RevenueReport report) {
    final svcs = List<ServiceRevenue>.from(report.serviceRevenue);
    svcs.sort((a, b) {
      int cmp = 0;
      if (_serviceSortCol == 'name') {
        cmp = a.serviceName.compareTo(b.serviceName);
      } else if (_serviceSortCol == 'count') {
        cmp = a.count.compareTo(b.count);
      } else {
        cmp = a.revenue.compareTo(b.revenue);
      }
      return _serviceAscending ? cmp : -cmp;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu theo dịch vụ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey[100]!, width: 1),
            ),
            children: [
              TableRow(
                children: [
                  _buildTableHeader(
                    'Dịch vụ',
                    'name',
                    _serviceSortCol,
                    _serviceAscending,
                    (col) {
                      setState(() {
                        if (_serviceSortCol == col) {
                          _serviceAscending = !_serviceAscending;
                        } else {
                          _serviceSortCol = col;
                          _serviceAscending = true;
                        }
                      });
                    },
                  ),
                  _buildTableHeader(
                    'Lượt sử dụng',
                    'count',
                    _serviceSortCol,
                    _serviceAscending,
                    (col) {
                      setState(() {
                        if (_serviceSortCol == col) {
                          _serviceAscending = !_serviceAscending;
                        } else {
                          _serviceSortCol = col;
                          _serviceAscending = false;
                        }
                      });
                    },
                  ),
                  _buildTableHeader(
                    'Doanh thu',
                    'revenue',
                    _serviceSortCol,
                    _serviceAscending,
                    (col) {
                      setState(() {
                        if (_serviceSortCol == col) {
                          _serviceAscending = !_serviceAscending;
                        } else {
                          _serviceSortCol = col;
                          _serviceAscending = false;
                        }
                      });
                    },
                  ),
                ],
              ),
              if (svcs.isEmpty)
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Không có dữ liệu'),
                    ),
                    const SizedBox(),
                    const SizedBox(),
                  ],
                )
              else
                ...svcs.map((s) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          s.serviceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          s.count.toString(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          _formatCurrency(s.revenue),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkTeal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(
    String label,
    String code,
    String activeCode,
    bool isAscending,
    Function(String) onTap,
  ) {
    final bool active = code == activeCode;
    return InkWell(
      onTap: () => onTap(code),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: active ? primaryTeal : Colors.grey[600],
              ),
            ),
            if (active)
              Icon(
                isAscending
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: primaryTeal,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // 5. Transactions Table Widget (with Search & Pagination)
  Widget _buildTransactionsTable(RevenueReport report, String rangeText) {
    final list = _controller.paginatedTransactions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách giao dịch thanh toán',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryTeal,
                      side: BorderSide(color: primaryTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.table_chart_rounded, size: 16),
                    label: const Text(
                      'Xuất Excel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _exportExcel(report, rangeText),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text(
                      'Xuất PDF',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _exportHtmlPdf(report, rangeText),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo mã lịch khám, tên bệnh nhân, bác sĩ...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _controller.updateSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryTeal, width: 1.5),
              ),
            ),
            onChanged: (val) => _controller.updateSearchQuery(val),
          ),
          const SizedBox(height: 16),

          // Datatable or compact cards
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return _buildDesktopTransactionsTable(list);
              } else {
                return _buildMobileTransactionsList(list);
              }
            },
          ),
          const SizedBox(height: 16),

          // Pagination Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hiển thị ${_controller.filteredTransactions.isEmpty ? 0 : (_controller.currentPage - 1) * _controller.itemsPerPage + 1} - ${_controller.currentPage * _controller.itemsPerPage > _controller.filteredTransactions.length ? _controller.filteredTransactions.length : _controller.currentPage * _controller.itemsPerPage} trong tổng số ${_controller.filteredTransactions.length} giao dịch',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _controller.currentPage > 1
                        ? () => _controller.setPage(_controller.currentPage - 1)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trang ${_controller.currentPage} / ${_controller.totalPages}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _controller.currentPage < _controller.totalPages
                        ? () => _controller.setPage(_controller.currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTransactionsTable(List<RevenueTransaction> list) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1.5),
        6: FlexColumnWidth(1.8),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey[100]!, width: 1),
      ),
      children: [
        // Table Header
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[50]),
          children: [
            _buildTableHeader(
              'Mã LK',
              'bookingId',
              _controller.sortColumn,
              _controller.sortAscending,
              _controller.sort,
            ),
            _buildTableHeader(
              'Bệnh nhân',
              'patientName',
              _controller.sortColumn,
              _controller.sortAscending,
              _controller.sort,
            ),
            _buildTableHeader(
              'Bác sĩ',
              'doctorName',
              _controller.sortColumn,
              _controller.sortAscending,
              _controller.sort,
            ),
            _buildTableHeader(
              'Ngày thanh toán',
              'paymentTime',
              _controller.sortColumn,
              _controller.sortAscending,
              _controller.sort,
            ),
            _buildTableHeader(
              'Phương thức',
              'paymentMethod',
              _controller.sortColumn,
              _controller.sortAscending,
              _controller.sort,
            ),
            _buildTableHeader(
              'Giảm giá',
              'discountAmount',
              _controller.sortColumn,
              _controller.sortAscending,
              _controller.sort,
            ),
            _buildTableHeader(
              'Tổng tiền',
              'totalAmount',
              _controller.sortColumn,
              _controller.sortAscending,
              _controller.sort,
            ),
          ],
        ),
        // Rows
        if (list.isEmpty)
          TableRow(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Không tìm thấy kết quả'),
              ),
              const SizedBox(),
              const SizedBox(),
              const SizedBox(),
              const SizedBox(),
              const SizedBox(),
              const SizedBox(),
            ],
          )
        else
          ...list.map((tx) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    tx.bookingId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    tx.patientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    tx.doctorName,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(tx.paymentTime),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.paymentMethod,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    _formatCurrency(tx.discountAmount),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    _formatCurrency(tx.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkTeal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildMobileTransactionsList(List<RevenueTransaction> list) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không tìm thấy kết quả'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          color: bgGrey,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tx.bookingId,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                    Text(
                      _formatCurrency(tx.totalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkTeal,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bệnh nhân: ${tx.patientName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Bác sĩ: ${tx.doctorName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(tx.paymentTime)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    Text(
                      'P.Thức: ${tx.paymentMethod} | Giảm: ${_formatCurrency(tx.discountAmount)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
