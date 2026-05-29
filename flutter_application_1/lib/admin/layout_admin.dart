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
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isWide
                      ? Row(
                          children: const [
                            Icon(
                              Icons.medical_services,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Admin Panel',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : const Center(
                          child: Icon(Icons.menu, color: Colors.redAccent),
                        ),
                ),

                const Divider(),

                Expanded(
                  child: ListView(
                    children: [
                      _SidebarItem(
                        icon: Icons.people,
                        label: 'Nhân viên',
                        wide: isWide,
                        selected: selectedIndex == 0,
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                        },
                      ),

                      _SidebarItem(
                        icon: Icons.person,
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
                        icon: Icons.medical_services,
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
                        icon: Icons.attach_money,
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

          // PAGE
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
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.redAccent : Colors.black54),
      title: wide
          ? Text(
              label,
              style: TextStyle(
                color: selected ? Colors.redAccent : Colors.black87,
              ),
            )
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
