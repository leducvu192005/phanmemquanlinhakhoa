import 'package:flutter/material.dart';

import '../../models/patient_model.dart';
import '/services/patient_service.dart';

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
          _buildSidebar(),

          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: PatientManagementContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
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

          _menuItem(Icons.people, "Nhân viên"),

          _menuItem(Icons.person, "Bệnh nhân", selected: true),

          _menuItem(Icons.calendar_month, "Lịch làm việc"),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {bool selected = false}) {
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

class PatientManagementContent extends StatefulWidget {
  const PatientManagementContent({super.key});

  @override
  State<PatientManagementContent> createState() =>
      _PatientManagementContentState();
}

class _PatientManagementContentState extends State<PatientManagementContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  final userService = PatientService();

  List<Patient> patients = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    fetchPatients();
  }

  Future<void> fetchPatients({String? query}) async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await userService.getPatients(query: query);

      setState(() {
        patients = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _statusPill(String status) {
    final active = status == "active";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),

        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,

            color: active ? Colors.green : Colors.red,

            size: 16,
          ),

          const SizedBox(width: 6),

          Text(
            active ? 'Hoạt động' : 'Đang tắt',

            style: TextStyle(color: active ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _contactColumn(Patient p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            const Icon(Icons.email_outlined, size: 14, color: Colors.black45),

            const SizedBox(width: 6),

            Flexible(
              child: Text(
                p.email,

                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            const Icon(Icons.phone, size: 14, color: Colors.black45),

            const SizedBox(width: 6),

            Text(p.phone),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Quản lí bệnh nhân",

          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        Text(
          "Quản lí tài khoản bệnh nhân",

          style: TextStyle(color: Colors.grey.shade600),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Container(
            width: double.infinity,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(12),

              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),

            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,

                          padding: const EdgeInsets.symmetric(horizontal: 12),

                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,

                            borderRadius: BorderRadius.circular(8),
                          ),

                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.black45),

                              const SizedBox(width: 8),

                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (value) {
                                    fetchPatients(query: value);
                                  },
                                  decoration: const InputDecoration.collapsed(
                                    hintText: 'Tìm theo tên...',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      ElevatedButton.icon(
                        onPressed: () async {
                          await userService.createPatient({
                            "patient_code": "BN001",
                            "full_name": "Nguyễn Văn A",
                            "gender": "male",
                            "date_of_birth": "2000-01-01",
                            "phone": "0123456789",
                            "email": "a@gmail.com",
                            "address": "Hà Nội",
                          });

                          fetchPatients(); // reload list
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm'),
                      ),
                    ],
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,

                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),

                  child: const Row(
                    children: [
                      Expanded(
                        flex: 1,

                        child: Text(
                          'Mã',

                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      Expanded(
                        flex: 3,

                        child: Text(
                          'Tên khách hàng',

                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      Expanded(
                        flex: 4,

                        child: Text(
                          'Liên hệ',

                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      Expanded(
                        flex: 2,

                        child: Text(
                          'Trạng thái',

                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      Expanded(
                        flex: 2,

                        child: Text(
                          'Hoạt động',

                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          separatorBuilder: (_, __) => const Divider(height: 0),

                          itemCount: patients.length,

                          itemBuilder: (context, index) {
                            final p = patients[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),

                              child: Row(
                                children: [
                                  Expanded(flex: 1, child: Text(p.patientCode)),

                                  Expanded(flex: 3, child: Text(p.fullName)),

                                  Expanded(flex: 4, child: _contactColumn(p)),

                                  Expanded(
                                    flex: 2,

                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _statusPill(
                                        p.status ? "active" : "inactive",
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    flex: 2,

                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,

                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            await userService.updatePatient(
                                              p.id,
                                              {"full_name": "Updated Name"},
                                            );

                                            fetchPatients();
                                          },
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                        ),

                                        IconButton(
                                          onPressed: () async {
                                            await userService.deletePatient(
                                              p.id,
                                            );

                                            fetchPatients(); // reload list
                                          },
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
