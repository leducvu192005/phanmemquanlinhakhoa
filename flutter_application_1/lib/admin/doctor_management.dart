import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'revenue_service.dart';
import 'revenue_model.dart';

class DentalAdminDashboard extends StatefulWidget {
  const DentalAdminDashboard({super.key});

  @override
  State<DentalAdminDashboard> createState() => _DentalAdminDashboardState();
}

class _DentalAdminDashboardState extends State<DentalAdminDashboard> {
  // Brand color palette (Teal Modern)
  final Color primaryTeal = const Color(0xFF00A896);
  final Color darkTeal = const Color(0xFF028090);
  final Color lightTeal = const Color(0xFFF0FDFA);
  final Color bgGrey = const Color(0xFFF8FAFC);
  final Color accentOrange = const Color(0xFFF59E0B);

  bool _isLoading = true;
  String? _error;

  // Real Database statistics
  int _todayBookingsCount = 0;
  int _pendingBookingsCount = 0;
  double _todayRevenue = 0.0;
  double _monthRevenue = 0.0;

  List<Booking> _todayBookingsList = [];
  List<DailyRevenue> _chartRevenueTrend = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Fetch Today's Bookings
      final bookings = await BookingService.getAllBookings(dateStr: todayStr);
      _todayBookingsList = bookings;
      _todayBookingsCount = bookings.length;

      // 2. Fetch Booking stats summary for pending appointments count
      final stats = await BookingService.getStatsSummary();
      _pendingBookingsCount = (stats['all']?['pending'] as num?)?.toInt() ?? 0;

      // 3. Fetch Revenue statistics (for last 7 days / current month)
      final report = await RevenueService.fetchRevenueReport();
      _todayRevenue = report.todayRevenue;
      _monthRevenue = report.monthRevenue;
      _chartRevenueTrend = report.dailyRevenue;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return accentOrange;
      case 'confirmed':
        return Colors.blue;
      case 'checked_in':
        return Colors.indigo;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return primaryTeal;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'confirmed':
        return 'Đã duyệt';
      case 'checked_in':
        return 'Đã check-in';
      case 'in_progress':
        return 'Đang khám';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan hệ thống',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            Text(
              'Chào buổi sáng, Quản trị viên',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.grey,
            ),
            onPressed: _fetchDashboardData,
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF00A896),
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text('Không thể tải dữ liệu: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                        onPressed: _fetchDashboardData,
                        child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. STATS KPI CARDS GRID
                      _buildStatsGrid(isWide),
                      const SizedBox(height: 24),

                      // 2. CHART & QUEUE LIST VIEWPORT
                      isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildChartCard()),
                                const SizedBox(width: 16),
                                Expanded(flex: 2, child: _buildQueueCard()),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildChartCard(),
                                const SizedBox(height: 24),
                                _buildQueueCard(),
                              ],
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsGrid(bool isWide) {
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth;
      final int crossAxisCount = width > 1100 ? 4 : (width > 600 ? 2 : 1);
      final double childAspectRatio = width > 1100 ? 2.3 : 2.0;

      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
        children: [
          _buildStatCard(
            title: 'HẸN HÔM NAY',
            value: '$_todayBookingsCount',
            icon: Icons.calendar_today_rounded,
            color: Colors.blue,
            trending: 'Số ca đặt khám của ngày hôm nay',
          ),
          _buildStatCard(
            title: 'DOANH THU HÔM NAY',
            value: _formatCurrency(_todayRevenue),
            icon: Icons.monetization_on_rounded,
            color: primaryTeal,
            trending: 'Thực thu sau khi trừ giảm giá',
          ),
          _buildStatCard(
            title: 'DOANH THU THÁNG NÀY',
            value: _formatCurrency(_monthRevenue),
            icon: Icons.analytics_rounded,
            color: darkTeal,
            trending: 'Thống kê lũy kế tháng hiện tại',
          ),
          _buildStatCard(
            title: 'HẸN CHỜ DUYỆT',
            value: '$_pendingBookingsCount',
            icon: Icons.pending_actions_rounded,
            color: accentOrange,
            trending: 'Lịch hẹn mới cần phê duyệt',
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trending,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trending,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    if (_chartRevenueTrend.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Không có dữ liệu xu hướng doanh thu.')),
      );
    }

    final List<FlSpot> spots = [];
    double maxRevenue = 1000000;

    for (int i = 0; i < _chartRevenueTrend.length; i++) {
      final rev = _chartRevenueTrend[i].revenue;
      if (rev > maxRevenue) maxRevenue = rev;
      spots.add(FlSpot(i.toDouble(), rev));
    }

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
            'Xu hướng doanh thu theo ngày',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 232,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[100]!,
                    strokeWidth: 1,
                  ),
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
                      getTitlesWidget: (value, meta) {
                        final int idx = value.toInt();
                        if (idx >= 0 && idx < _chartRevenueTrend.length) {
                          final dateParsed = DateTime.tryParse(_chartRevenueTrend[idx].date);
                          if (dateParsed != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('dd/MM').format(dateParsed),
                                style: TextStyle(color: Colors.grey[500], fontSize: 10),
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('0');
                        if (value >= 1000000) {
                          return Text('${(value / 1000000).toStringAsFixed(1)}M');
                        }
                        return Text('${(value / 1000).toStringAsFixed(0)}k');
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: primaryTeal,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4.5,
                        color: Colors.white,
                        strokeColor: primaryTeal,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryTeal.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch hẹn hôm nay',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_todayBookingsList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_todayBookingsList.length} ca',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayBookingsList.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không có ca khám nào hôm nay',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayBookingsList.length > 5 ? 5 : _todayBookingsList.length,
              itemBuilder: (context, index) {
                final b = _todayBookingsList[index];
                final statusColor = _getStatusColor(b.status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: lightTeal,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: primaryTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.patient?.fullName ?? 'Bệnh nhân ẩn danh',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bác sĩ: ${b.doctor?.fullName ?? "Chưa chỉ định"}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b.timeSlot,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(b.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
