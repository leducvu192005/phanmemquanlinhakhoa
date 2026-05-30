import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'patient_management_screen.dart';
import 'pricing_screen.dart';
import 'service_management_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;

    final pages = [
      const AdminDashboard(),
      PatientManagementContent(),
      ServiceManagementScreen(),
      PricingScreen(),
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
                              'Nha Khoa Admin',
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
                        icon: Icons.assignment_ind_outlined,
                        label: 'Bác sĩ',
                        wide: isWide,
                        selected: selectedIndex == 0,
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.people_outline,
                        label: 'Bệnh nhân',
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
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.wide,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: selected ? Colors.teal[50] : Colors.transparent,
        leading: Icon(
          icon,
          color: selected ? Colors.teal : const Color(0xFF64748B),
          size: 22,
        ),
        title: wide
            ? Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.teal[800] : const Color(0xFF334155),
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
