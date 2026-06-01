import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Dùng để vẽ biểu đồ doanh thu xịn xò

class DentalAdminDashboard extends StatefulWidget {
  @override
  _DentalAdminDashboardState createState() => _DentalAdminDashboardState();
}

class _DentalAdminDashboardState extends State<DentalAdminDashboard> {
  // Hệ màu cao cấp chuyên biệt cho Nha Khoa (Teal Modern)
  final Color primaryTeal = const Color(0xFF00A896);
  final Color darkTeal = const Color(0xFF028090);
  final Color lightTeal = const Color(0xFFF0FDFA);
  final Color bgGrey = const Color(0xFFF8FAFC);
  final Color accentOrange = const Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
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
                color: Colors.black,
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
            icon: Badge(
              label: const Text('3'),
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.grey[700],
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF00A896),
            child: Text(
              'V',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CÁC THẺ KPI STATS (GRID VIEW)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  title: 'Hẹn hôm nay',
                  value: '42',
                  icon: Icons.calendar_today_rounded,
                  color: primaryTeal,
                  trending: '+12% so với hôm qua',
                ),
                _buildStatCard(
                  title: 'Khách hàng mới',
                  value: '18',
                  icon: Icons.people_alt_rounded,
                  color: darkTeal,
                  trending: '+5% tuần này',
                ),
                _buildStatCard(
                  title: 'Doanh thu (đ)',
                  value: '24.5M',
                  icon: Icons.analytics_rounded,
                  color: accentOrange,
                  trending: 'Mục tiêu đạt 85%',
                ),
                _buildStatCard(
                  title: 'Ghế trống',
                  value: '3/5',
                  icon: Icons.airline_seat_flat_angled_rounded,
                  color: Colors.blue,
                  trending: 'Hiệu suất: 60%',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. BIỂU ĐỒ DOANH THU TUẦN
            const Text(
              'Xu hướng doanh thu tuần',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildChartCard(),
            const SizedBox(height: 24),

            // 3. DANH SÁCH LỊCH HẸN GẦN NHẤT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch hẹn sắp tới',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: darkTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildAppointmentList(),
          ],
        ),
      ),
    );
  }

  // Widget dựng thẻ thống kê nhanh (KPI)
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trending,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trending,
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget dựng biểu đồ đường (LineChart)
  Widget _buildChartCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
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
                getTitlesWidget: (value, meta) {
                  const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Text(
                      days[value.toInt()],
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 10),
                const FlSpot(1, 15),
                const FlSpot(2, 12),
                const FlSpot(3, 24),
                const FlSpot(4, 18),
                const FlSpot(5, 28),
                const FlSpot(6, 22),
              ],
              isCurved: true,
              color: primaryTeal,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: primaryTeal.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget dựng danh sách hàng đợi / lịch hẹn
  Widget _buildAppointmentList() {
    // Data mẫu giả lập từ API thực tế
    final appointments = [
      {
        'name': 'Nguyễn Văn A',
        'time': '09:00',
        'service': 'Nhổ răng khôn',
        'status': 'Đang đợi',
      },
      {
        'name': 'Trần Thị B',
        'time': '10:30',
        'service': 'Bọc răng sứ',
        'status': 'Đang khám',
      },
      {
        'name': 'Lê Văn C',
        'time': '14:00',
        'service': 'Niềng răng kiểm tra',
        'status': 'Đã hẹn',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final item = appointments[index];
        Color statusColor = primaryTeal;
        if (item['status'] == 'Đang khám') statusColor = accentOrange;
        if (item['status'] == 'Đã hẹn') statusColor = Colors.blue;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightTeal,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline_rounded, color: primaryTeal),
            ),
            title: Text(
              item['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${item['time']} | ${item['service']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item['status']!,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
