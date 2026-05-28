import 'package:flutter/material.dart';
// Import file Booking từ folder mới
import 'booking/booking_screen.dart'; 

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với thanh Menu
  final List<Widget> _screens = [
    const PatientHomeContent(), // Màn hình Home (được định nghĩa ở dưới)
    const BookingScreen(),      // Màn hình Đặt lịch (từ folder booking)
    const Center(child: Text('Màn hình Thông báo')),
    const Center(child: Text('Màn hình Hồ sơ')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Chỉ dùng Scaffold này để bọc BottomNavigationBar. 
      // AppBar sẽ do từng màn hình con tự quản lý.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.redAccent.withOpacity(0.5),
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedIndex == 0 ? Colors.redAccent.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.home_outlined),
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Đặt lịch'),
          const BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: 'Thông báo'),
          const BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

// =====================================================================
// GIAO DIỆN TRANG CHỦ (Chứa News, Lịch sắp tới, Nút chức năng...)
// =====================================================================
class PatientHomeContent extends StatelessWidget {
  const PatientHomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.menu, color: Colors.redAccent), onPressed: () {}),
        title: const Text('LongVuDentist', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.account_circle_outlined, color: Colors.redAccent), onPressed: () {})],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.redAccent, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNewsSection(),
            const SizedBox(height: 24),
            _buildUpcomingAppointment(),
            const SizedBox(height: 24),
            _buildActionGrid(),
            const SizedBox(height: 24),
            _buildNotifications(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('News', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.blue[50],
            image: const DecorationImage(image: NetworkImage('https://via.placeholder.com/400x150'), fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Lịch hẹn sắp tới', style: TextStyle(color: Colors.grey, fontSize: 13)),
                SizedBox(height: 4),
                Text('Thứ 2, 15 tháng 5 - 8:00 AM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text('Dr.Long - Chuyên gia răng miệng', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildActionCard('Đặt cuộc hẹn\nvới bác sĩ', 'Đặt lịch sớm nhất', Icons.calendar_today, const Color(0xFFE5F5E5))),
            const SizedBox(width: 16),
            Expanded(child: _buildActionCard('Dịch vụ chúng\ntôi', 'Tất cả dịch vụ', Icons.medical_services_outlined, const Color(0xFFF5E5F0))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionCard('Cuộc hẹn của\ntôi', 'Các cuộc hẹn đã đặt', Icons.access_time, const Color(0xFFE5E5F5))),
            const SizedBox(width: 16),
            Expanded(child: _buildActionCard('Hồ sơ bệnh án', 'Bệnh án cá nhân', Icons.assignment_outlined, const Color(0xFFE5F0F5))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Thông báo phòng khám', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text('Tất cả', style: TextStyle(color: Colors.grey))),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.black54),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cập nhật thời gian cuộc hẹn', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Bạn đã cập nhật thời gian từ 13:00 thành 8:00', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Text('30 T5', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        )
      ],
    );
  }
}