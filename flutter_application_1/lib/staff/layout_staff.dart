import 'package:flutter/material.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'work_shift_management.dart';
import 'DoctorScheduleManagement.dart';

class LayoutStaff extends StatefulWidget {
  const LayoutStaff({super.key});

  @override
  State<LayoutStaff> createState() => _LayoutStaffState();
}

class _LayoutStaffState extends State<LayoutStaff> {
  int selectedIndex = 0;
  final _storage = const FlutterSecureStorage();
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

    final pages = [
      const WorkShiftManagementScreen(),
      const Doctorschedulemanagement(),
    ];

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: isWide ? 240 : 72,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isWide
                      ? Row(
                          children: [
                            const Icon(
                              Icons.healing_outlined,
                              color: Colors.teal,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nha Khoa Staff',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal[800],
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Icon(
                            Icons.healing_outlined,
                            color: Colors.teal,
                          ),
                        ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _SidebarItem(
                        icon: Icons.schedule_outlined,
                        label: 'Ca làm việc',
                        wide: isWide,
                        selected: selectedIndex == 0,
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.event_available_outlined,
                        label: 'Đăng kí lịch trực',
                        wide: isWide,
                        selected: selectedIndex == 1,
                        onTap: () {
                          setState(() {
                            selectedIndex = 1;
                          });
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.medical_services_outlined,
                        label: 'Dịch vụ',
                        wide: isWide,
                        selected: selectedIndex == 2,
                        onTap: () {
                          setState(() {
                            selectedIndex = 2;
                          });
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.monetization_on_outlined,
                        label: 'Bảng giá',
                        wide: isWide,
                        selected: selectedIndex == 3,
                        onTap: () {
                          setState(() {
                            selectedIndex = 3;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                            title: const Text('Xác nhận đăng xuất'),
                            content: const Text(
                              'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống quản trị?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Hủy',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _doLogout();
                                },
                                child: const Text(
                                  'Đăng xuất',
                                  style: TextStyle(color: Colors.redAccent),
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
          Expanded(child: pages[selectedIndex]),
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
    final Color itemColor = isDestructive
        ? Colors.redAccent
        : (selected ? Colors.teal : const Color(0xFF64748B));

    final Color textColor = isDestructive
        ? Colors.redAccent
        : (selected ? Colors.teal[800]! : const Color(0xFF334155));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: selected ? Colors.teal[50] : Colors.transparent,
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
