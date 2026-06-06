import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../services/api.dart';
import '../services/patient_service.dart';
import '../models/patient_model.dart';
import '../models/service.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/service_api.dart';
import 'booking_screen.dart';
import 'appointment_tracking_screen.dart';
import 'medical_history_screen.dart';
import 'service_list_screen.dart';
import 'clinic_detail_screen.dart';
import '../login.dart';


class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF0D9488); // Xanh Ngọc (Teal 600)
  final Color accentColor = const Color(0xFF2DD4BF); // Turquoise

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PatientHomeContent(
        onTabChange: (idx) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedIndex = idx;
              });
            }
          });
        },
      ),
      BookingScreen(
        onBookingSuccess: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedIndex = 0; // Quay lại trang chủ sau khi đặt thành công
              });
            }
          });
        },
      ),
      const PatientNotificationScreen(),
      const PatientProfileScreen(),
    ];
  }

  Widget _buildBottomBarIcon(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: primaryColor.withOpacity(0.4),
        showUnselectedLabels: true,
        onTap: (index) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedIndex = index;
              });
            }
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: _buildBottomBarIcon(Icons.home_outlined, 0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildBottomBarIcon(Icons.calendar_month_outlined, 1),
            label: 'Đặt lịch',
          ),
          BottomNavigationBarItem(
            icon: _buildBottomBarIcon(Icons.notifications_none_outlined, 2),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: _buildBottomBarIcon(Icons.account_circle_outlined, 3),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// NỘI DUNG TRANG CHỦ BỆNH NHÂN (Home Content)
// =====================================================================
class PatientHomeContent extends StatefulWidget {
  final Function(int) onTabChange;
  const PatientHomeContent({Key? key, required this.onTabChange})
    : super(key: key);

  @override
  State<PatientHomeContent> createState() => _PatientHomeContentState();
}

class _PatientHomeContentState extends State<PatientHomeContent> {
  final Color primaryColor = const Color(0xFF0D9488);
  final Color accentColor = const Color(0xFF2DD4BF);
  final Color bgLight = const Color(0xFFF0FDFA);

  Patient? _patient;
  Booking? _upcomingBooking;
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    if (!mounted) return;
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final patient = await PatientService.getMyProfile();
      final bookings = await BookingService.getMyBookings();
      final svcs = await ServiceApi.getServices();

      // Tìm cuộc hẹn sắp tới (Chờ duyệt hoặc Đã duyệt) trong tương lai hoặc hôm nay
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      Booking? upcoming;
      final futureBookings = bookings.where((b) {
        final status = b.status.toLowerCase();
        final bDate = DateTime.tryParse(b.bookingDate);
        if (bDate == null) return false;
        // Bao gồm cả các lịch hẹn hôm nay hoặc tương lai
        final dateOnly = DateTime(bDate.year, bDate.month, bDate.day);
        return (status == 'pending' || status == 'confirmed') &&
            (dateOnly.isAtSameMomentAs(today) || dateOnly.isAfter(today));
      }).toList();

      if (futureBookings.isNotEmpty) {
        futureBookings.sort(
          (a, b) => a.bookingDate.compareTo(b.bookingDate),
        );
        upcoming = futureBookings.first;
      }

      if (mounted) {
        setState(() {
          _patient = patient;
          _upcomingBooking = upcoming;
          _services = svcs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('PatientHomeContent data load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _doLogout() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text(
          'Bạn có chắc muốn đăng xuất khỏi hệ thống phòng khám?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doLogout();
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showServicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dịch vụ của chúng tôi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: _services.isEmpty
                    ? const Center(child: Text('Đang tải danh sách dịch vụ...'))
                    : ListView.builder(
                        itemCount: _services.length,
                        itemBuilder: (ctx, idx) {
                          final s = _services[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: bgLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.check_circle_outline,
                                color: primaryColor,
                              ),
                              title: Text(
                                s.serviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                s.category ?? 'Nha khoa tổng quát',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '${NumberFormat('#,###', 'vi_VN').format(s.price)}đ',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientName = _patient?.fullName ?? 'Thành viên';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Nha Khoa Sáng Răng',
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Icon(Icons.healing, color: primaryColor),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: primaryColor),
            onPressed: _showLogoutDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: primaryColor.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadHomeData,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chào hỏi
                    Text(
                      'Xin chào, $patientName!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chúc bạn có một ngày tuyệt vời với nụ cười tỏa sáng.',
                      style: TextStyle(color: Colors.black45, fontSize: 13),
                    ),

                    const SizedBox(height: 24),
                    _buildNewsCard(),

                    const SizedBox(height: 24),
                    _buildUpcomingCard(),

                    const SizedBox(height: 24),
                    _buildActionGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNewsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'MẸO CHĂM SÓC RĂNG',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '5 bước chải răng đúng cách theo lời khuyên của chuyên gia nha khoa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chải răng ít nhất 2 lần/ngày kết hợp chỉ nha khoa giúp làm sạch 99% mảng bám vi khuẩn.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard() {
    if (_upcomingBooking == null) {
      return InkWell(
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientAppointmentListScreen(),
                ),
              ).then((_) => _loadHomeData());
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: bgLight,
                child: Icon(Icons.calendar_today, color: primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Không có lịch khám sắp tới',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bạn muốn khám răng? Hãy nhấn đặt lịch khám ngay.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: primaryColor,
                ),
                onPressed: () {
                  widget.onTabChange(1); // Switch to Booking screen
                },
              ),
            ],
          ),
        ),
      );
    }

    final booking = _upcomingBooking!;
    String dateStr = booking.bookingDate;
    try {
      final parsedDate = DateTime.parse(booking.bookingDate);
      dateStr = DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (_) {}
    
    final timeStr = booking.timeSlot;
    final doctor = booking.doctor?.fullName ?? 'Chưa chỉ định';
    final notes = booking.symptoms ?? 'Khám tổng quát';

    return InkWell(
      onTap: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PatientAppointmentListScreen(),
              ),
            ).then((_) => _loadHomeData());
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_available, color: primaryColor, size: 20),
                    const SizedBox(width: 6),
                    const Text(
                      'Lịch hẹn khám sắp tới',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toLowerCase() == 'confirmed'
                        ? 'Đã duyệt'
                        : 'Chờ duyệt',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              '$timeStr - ngày $dateStr',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bác sĩ: BS. $doctor',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              'Lý do/Triệu chứng: $notes',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Đặt lịch khám\nvới bác sĩ',
                'Hẹn bác sĩ sớm nhất',
                Icons.calendar_month,
                const Color(0xFFF0FDF4),
                onTap: () => widget.onTabChange(1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Dịch vụ của\nphòng khám',
                'Xem bảng giá dịch vụ',
                Icons.medical_services_outlined,
                const Color(0xFFFFFBEB),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientServiceListScreen(),
                        ),
                      ).then((res) {
                        if (res == true && mounted) {
                          widget.onTabChange(1); // Chuyển sang đặt lịch khám
                        }
                      });
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Theo dõi lịch\nkhám của tôi',
                'Xem trạng thái lịch hẹn',
                Icons.access_time,
                const Color(0xFFEFF6FF),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientAppointmentListScreen(),
                        ),
                      ).then((_) => _loadHomeData());
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Lịch sử khám\n& Bệnh án',
                'Kết quả chẩn đoán',
                Icons.assignment_outlined,
                bgLight,
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientMedicalHistoryScreen(),
                        ),
                      );
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color bgColor, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: primaryColor),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black45, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// THANH THÔNG BÁO DÂN CƯ CA LÂM SÀNG DỰA TRÊN LỊCH KHÁM THẬT (Notification Screen)
// =====================================================================
class PatientNotificationScreen extends StatefulWidget {
  const PatientNotificationScreen({super.key});

  @override
  State<PatientNotificationScreen> createState() =>
      _PatientNotificationScreenState();
}

class _PatientNotificationScreenState extends State<PatientNotificationScreen> {
  final Color primaryColor = const Color(0xFF0D9488);
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await BookingService.getMyBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _notifications {
    final list = <Map<String, dynamic>>[];

    // Luôn có 1 thông báo chào mừng
    list.add({
      'title': 'Chào mừng thành viên mới!',
      'body':
          'Chào mừng bạn đã tham gia hệ thống Nha Khoa Sáng Răng. Trải nghiệm dịch vụ chăm sóc nụ cười chuyên nghiệp nhất.',
      'date': 'Hệ thống',
      'icon': Icons.stars,
      'color': Colors.amber.shade700,
    });

    for (var b in _bookings) {
      String formattedDate = b.bookingDate;
      try {
        final parsedDate = DateTime.parse(b.bookingDate);
        formattedDate = DateFormat('dd/MM').format(parsedDate);
      } catch (_) {}
      
      final formattedTime = '${b.timeSlot}, ngày $formattedDate';
      final doctor = b.doctor?.fullName ?? 'Bác sĩ';
      final dateStr = formattedDate;

      if (b.status.toLowerCase() == 'confirmed') {
        list.add({
          'title': 'Lịch khám được xác nhận',
          'body':
              'Lịch hẹn khám với BS. $doctor lúc $formattedTime đã được phê duyệt.',
          'date': dateStr,
          'icon': Icons.check_circle,
          'color': primaryColor,
        });
      } else if (b.status.toLowerCase() == 'checked_in') {
        list.add({
          'title': 'Điểm danh check-in thành công',
          'body':
              'Bạn đã báo diện lúc $formattedTime. Bác sĩ sẽ gọi bạn vào phòng điều trị sớm.',
          'date': dateStr,
          'icon': Icons.login,
          'color': Colors.blue.shade700,
        });
      } else if (b.status.toLowerCase() == 'in_progress') {
        list.add({
          'title': 'Đang tiến hành điều trị',
          'body':
              'Bác sĩ đang tiến hành khám và thực hiện điều trị cho bạn lúc $formattedTime.',
          'date': dateStr,
          'icon': Icons.play_arrow,
          'color': Colors.indigo,
        });
      } else if (b.status.toLowerCase() == 'completed') {
        list.add({
          'title': 'Hoàn thành đợt khám bệnh',
          'body':
              'Ca khám lúc $formattedTime đã xong. Kết quả bệnh án chẩn đoán & đơn thuốc đã được cập nhật.',
          'date': dateStr,
          'icon': Icons.task_alt,
          'color': Colors.green.shade700,
        });
      } else if (b.status.toLowerCase() == 'cancelled') {
        list.add({
          'title': 'Lịch khám đã bị hủy',
          'body':
              'Lịch hẹn lúc $formattedTime của bạn đã được cập nhật trạng thái Đã hủy.',
          'date': dateStr,
          'icon': Icons.cancel,
          'color': Colors.redAccent,
        });
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final notifs = _notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Thông báo từ phòng khám',
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
          : notifs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có thông báo nào',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifs.length,
                itemBuilder: (context, index) {
                  final item = notifs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['body'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['date'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// =====================================================================
// MÀN HÌNH HỒ SƠ BỆNH NHÂN THẬT (Profile Screen)
// =====================================================================
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final Color primaryColor = const Color(0xFF0D9488);
  Patient? _patient;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await PatientService.getMyProfile();
      if (mounted) {
        setState(() {
          _patient = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _doLogout() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  void _showEditProfileBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: _patient?.fullName);
    final phoneCtrl = TextEditingController(text: _patient?.phone);
    final emailCtrl = TextEditingController(text: _patient?.email);
    final addressCtrl = TextEditingController(text: _patient?.address);
    final bloodTypeCtrl = TextEditingController(text: _patient?.bloodType);
    String? selectedGender = _patient?.gender;
    DateTime? selectedDOB = _patient?.dateOfBirth != null ? DateTime.tryParse(_patient!.dateOfBirth!) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final dobStr = selectedDOB == null ? 'Chưa cập nhật' : DateFormat('dd/MM/yyyy').format(selectedDOB!);
            bool isSaving = false;

            InputDecoration buildInputDecoration({
              required String label,
              required IconData icon,
            }) {
              return InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
                labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
                floatingLabelStyle: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              );
            }

            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chỉnh sửa Hồ sơ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: buildInputDecoration(label: 'Họ và tên *', icon: Icons.person),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: buildInputDecoration(label: 'Số điện thoại *', icon: Icons.phone),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số điện thoại' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: buildInputDecoration(label: 'Địa chỉ Email *', icon: Icons.email),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập email' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        decoration: buildInputDecoration(label: 'Giới tính', icon: Icons.transgender),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                          DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                          DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            selectedGender = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDOB ?? DateTime(2000, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDOB = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: buildInputDecoration(
                            label: 'Ngày sinh',
                            icon: Icons.cake_outlined,
                          ),
                          child: Text(
                            dobStr,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: addressCtrl,
                        decoration: buildInputDecoration(label: 'Địa chỉ nơi ở', icon: Icons.location_on),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bloodTypeCtrl,
                        decoration: buildInputDecoration(label: 'Nhóm máu', icon: Icons.bloodtype),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() {
                              isSaving = true;
                            });
                            
                            final payload = {
                              'full_name': nameCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'date_of_birth': selectedDOB != null ? DateFormat('yyyy-MM-dd').format(selectedDOB!) : null,
                              'address': addressCtrl.text.trim(),
                              'blood_type': bloodTypeCtrl.text.trim(),
                              'gender': selectedGender,
                            };

                            try {
                              final updated = await PatientService.updateMyProfile(payload);
                              if (mounted) {
                                setState(() {
                                  _patient = updated;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cập nhật hồ sơ cá nhân thành công!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(sheetContext);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cập nhật thất bại: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            } finally {
                              setModalState(() {
                                isSaving = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSaving 
                            ? const SizedBox(
                                width: 24, 
                                height: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showClinicDetailDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết Nha Khoa Sáng Răng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Sứ mệnh của chúng tôi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mang lại nụ cười tự tin và rạng rỡ nhất cho mọi khách hàng bằng việc cung cấp các giải pháp nha khoa toàn diện, chất lượng cao và an toàn tuyệt đối.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đội ngũ Bác sĩ giàu kinh nghiệm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  '100% bác sĩ tại Nha Khoa Sáng Răng tốt nghiệp Đại học Y Dược chuyên khoa Răng Hàm Mặt, có chứng chỉ hành nghề và tu nghiệp thường xuyên tại nước ngoài (Mỹ, Pháp, Hàn Quốc).',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Trang thiết bị hiện đại bậc nhất',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  '- Máy quét dấu răng 3D iTero Element 5D.\n- Máy chụp phim CT Cone Beam hiện đại chẩn đoán chính xác.\n- Hệ thống vô trùng khép kín chuẩn châu Âu.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cam kết chất lượng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chính sách bảo hành rõ ràng, chi phí minh bạch không phát sinh, dịch vụ chăm sóc khách hàng chu đáo trước, trong và sau quá trình điều trị.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutUsCard() {
    return InkWell(
      onTap: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClinicDetailScreen(),
              ),
            );
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Về phòng khám Nha Khoa Sáng Răng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.5), size: 14),
              ],
            ),
            const Divider(height: 20),
            const Text(
              'Nha Khoa Sáng Răng tự hào là thương hiệu chăm sóc răng miệng uy tín hàng đầu. Chúng tôi luôn cam kết đem lại chất lượng điều trị chuẩn y khoa, không gian dịch vụ an toàn, tận tâm và không ngừng cập nhật trang thiết bị tiên tiến nhất.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 12),
            _buildAboutDetailRow(Icons.location_on_outlined, '123 Đường Ba Tháng Hai, Quận 10, TP. HCM'),
            const SizedBox(height: 6),
            _buildAboutDetailRow(Icons.phone_in_talk_outlined, 'Hotline hỗ trợ: 1900 6789'),
            const SizedBox(height: 6),
            _buildAboutDetailRow(Icons.access_time_outlined, 'Giờ làm việc: 08:00 - 20:00 (Tất cả các ngày)'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClinicDetailScreen(),
                        ),
                      );
                    }
                  });
                },
                icon: Icon(Icons.explore_outlined, size: 16, color: primaryColor),
                label: Text(
                  'Xem chi tiết phòng khám & dịch vụ',
                  style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor.withOpacity(0.7), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: primaryColor),
            tooltip: 'Chỉnh sửa hồ sơ',
            onPressed: _showEditProfileBottomSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: primaryColor.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _patient == null
          ? const Center(child: Text('Không thể tải thông tin hồ sơ.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, size: 50, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _patient!.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Mã bệnh nhân: ${_patient!.patientCode ?? 'Chưa cập nhật'}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showEditProfileBottomSheet,
                    icon: Icon(Icons.edit, color: primaryColor, size: 16),
                    label: Text(
                      'Chỉnh sửa thông tin',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: primaryColor.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildProfileItem(
                    Icons.phone_android,
                    'Số điện thoại liên hệ',
                    _patient!.phone ?? 'Chưa cập nhật',
                  ),
                  _buildProfileItem(
                    Icons.email_outlined,
                    'Địa chỉ Email',
                    _patient!.email ?? 'Chưa cập nhật',
                  ),
                  _buildProfileItem(
                    Icons.transgender_outlined,
                    'Giới tính',
                    _patient!.gender ?? 'Chưa cập nhật',
                  ),
                  _buildProfileItem(
                    Icons.cake_outlined,
                    'Ngày sinh',
                    _patient!.dateOfBirth != null &&
                            DateTime.tryParse(_patient!.dateOfBirth!) != null
                        ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(DateTime.tryParse(_patient!.dateOfBirth!)!)
                        : 'Chưa cập nhật',
                  ),
                  _buildProfileItem(
                    Icons.location_on_outlined,
                    'Địa chỉ nơi ở',
                    _patient!.address ?? 'Chưa cập nhật',
                  ),
                  _buildProfileItem(
                    Icons.bloodtype_outlined,
                    'Nhóm máu',
                    _patient!.bloodType ?? 'Chưa cập nhật',
                  ),

                  const SizedBox(height: 24),
                  _buildAboutUsCard(),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Xác nhận đăng xuất'),
                            content: const Text(
                              'Bạn có chắc muốn đăng xuất khỏi ứng dụng phòng khám?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  'Hủy',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _doLogout();
                                },
                                child: const Text(
                                  'Đăng xuất',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Đăng xuất tài khoản',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
