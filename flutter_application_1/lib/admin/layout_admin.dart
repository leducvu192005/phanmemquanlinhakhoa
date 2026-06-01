import 'package:flutter/material.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dashboard.dart'; // Chứa DentalAdminDashboard
import 'patient_management_screen.dart';
import 'pricing_screen.dart';
import 'service_management_screen.dart';
import 'doctor_management.dart'; // Chứa AdminDashboard quản lý bác sĩ

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int selectedIndex = 0; // Mặc định hiển thị trang đầu tiên (Dashboard)
  final _storage = const FlutterSecureStorage();

  final Color primaryTeal = const Color(0xFF00A896);

  Future<void> _doLogout() async {
    try {
      await _storage.deleteAll();
      print("Storage deleted");

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) {
            print("Creating LoginPage");
            return LoginPage();
          },
        ),
        (route) => false,
      );

      print("Navigation called");
    } catch (e, s) {
      print(e);
      print(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;

    // Sắp xếp lại thứ tự Pages tương ứng với Sidebar
    final pages = [
      DentalAdminDashboard(), // Index 0: Tổng quan Dashboard xịn xò
      AdminDashboard(), // Index 1: Quản lý Bác sĩ (Danh sách/Thêm)
      PatientManagementContent(), // Index 2: Quản lý Bệnh nhân
      ServiceManagementScreen(), // Index 3: Quản lý Dịch vụ
      PricingScreen(), // Index 4: Cấu hình Bảng giá
    ];

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR CONTAINER
          Container(
            width: isWide ? 240 : 72,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // LOGO HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 16.0,
                  ),
                  child: isWide
                      ? Row(
                          children: [
                            Icon(
                              Icons.healing_outlined,
                              color: primaryTeal,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Nha Khoa Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal[800],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Icon(
                            Icons.healing_outlined,
                            color: primaryTeal,
                            size: 26,
                          ),
                        ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // DANH SÁCH MENU SIDEBAR
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      // 1. TỔNG QUAN (DENTAL ADMIN DASHBOARD)
                      _SidebarItem(
                        icon: Icons.dashboard_customize_outlined,
                        label: 'Tổng quan',
                        wide: isWide,
                        selected: selectedIndex == 0,
                        onTap: () {
                          setState(() => selectedIndex = 0);
                        },
                      ),

                      // 2. BÁC SĨ (ADMIN DASHBOARD)
                      _SidebarItem(
                        icon: Icons.assignment_ind_outlined,
                        label: 'Bác sĩ',
                        wide: isWide,
                        selected: selectedIndex == 1,
                        onTap: () {
                          setState(() => selectedIndex = 1);
                        },
                      ),

                      // 3. BỆNH NHÂN
                      _SidebarItem(
                        icon: Icons.people_outline_rounded,
                        label: 'Bệnh nhân',
                        wide: isWide,
                        selected: selectedIndex == 2,
                        onTap: () {
                          setState(() => selectedIndex = 2);
                        },
                      ),

                      // 4. DỊCH VỤ
                      _SidebarItem(
                        icon: Icons.medical_services_outlined,
                        label: 'Dịch vụ',
                        wide: isWide,
                        selected: selectedIndex == 3,
                        onTap: () {
                          setState(() => selectedIndex = 3);
                        },
                      ),

                      // 5. BẢNG GIÁ
                      _SidebarItem(
                        icon: Icons.monetization_on_outlined,
                        label: 'Bảng giá',
                        wide: isWide,
                        selected: selectedIndex == 4,
                        onTap: () {
                          setState(() => selectedIndex = 4);
                        },
                      ),
                    ],
                  ),
                ),

                // NÚT ĐĂNG XUẤT NẰM Ở ĐÁY SIDEBAR
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _SidebarItem(
                    icon: Icons.logout_rounded,
                    label: 'Đăng xuất',
                    wide: isWide,
                    selected: false,
                    isDestructive: true,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Xác nhận đăng xuất',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống quản trị?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Hủy',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent[100]
                                      ?.withOpacity(0.2),
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _doLogout();
                                },
                                child: const Text(
                                  'Đăng xuất',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // NỘI DUNG HIỂN THỊ CHÍNH PHÍA BÊN PHẢI
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool wide;
  final bool selected;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.wide,
    this.selected = false,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryTeal = const Color(0xFF00A896);

    final Color itemColor = isDestructive
        ? Colors.redAccent
        : (selected ? primaryTeal : const Color(0xFF64748B));

    final Color textColor = isDestructive
        ? Colors.redAccent
        : (selected ? const Color(0xFF0F766E) : const Color(0xFF334155));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        horizontalTitleGap: wide ? 12 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: selected ? const Color(0xFFE6F7F6) : Colors.transparent,
        leading: Icon(icon, color: itemColor, size: 22),
        title: wide
            ? Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
