import 'package:flutter/material.dart';

/// Screen that shows a sidebar + patient management content (full screen).
/// Also exposes `PatientManagementContent` so other screens (e.g. dashboard)
/// can embed the patient UI without duplicating the sidebar/scaffold.
class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: const PatientManagementContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSidebar() {
    return Container(
      width: 230,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            "Admin Panel",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 40),
          menuItem(Icons.people, "Nhân viên"),
          menuItem(Icons.person, "Bệnh nhân", selected: true),
          menuItem(Icons.calendar_month, "Lịch làm việc"),
        ],
      ),
    );
  }

  Widget menuItem(IconData icon, String title, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.black),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientManagementContent extends StatelessWidget {
  const PatientManagementContent({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> patients = [
      {
        "code": "0001",
        "name": "Nguyen Thanh Long",
        "email": "longwork@gmail.com",
        "phone": "0123456789",
        "status": true,
      },
      {
        "code": "0002",
        "name": "Le Duc Vu",
        "email": "leduccvu@gmail.com",
        "phone": "0988888888",
        "status": true,
      },
      {
        "code": "0003",
        "name": "Nguyen Thu Hien",
        "email": "hien@gmail.com",
        "phone": "0999999999",
        "status": false,
      },
    ];

    final searchController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quản lí bệnh nhân",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Quản lí tài khoản bệnh nhân",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search),
              hintText: "Nhập tên...",
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Expanded(flex: 1, child: Text("Mã")),
                      Expanded(flex: 2, child: Text("Tên")),
                      Expanded(flex: 3, child: Text("Liên hệ")),
                      Expanded(flex: 2, child: Text("Trạng thái")),
                      Expanded(flex: 2, child: Text("Hoạt động")),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final p = patients[index];
                      return Container(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text(p["code"])),
                            Expanded(flex: 2, child: Text(p["name"])),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text(p["email"]), Text(p["phone"])],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: p["status"]
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  p["status"] ? "Hoạt động" : "Đang tắt",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
