import 'package:flutter/material.dart';
import '../../models/patient_model.dart';

class PatientDetailScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  // Widget hiển thị từng ô thông tin nhỏ gọn, chuyên nghiệp
  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? "—" : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget bọc từng phân khu (Section) lớn
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "Chi tiết bệnh nhân",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BANNER HEADER
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFEEF2FF),
                        backgroundImage:
                            (patient.avatar != null &&
                                patient.avatar!.isNotEmpty)
                            ? NetworkImage(patient.avatar!)
                            : null,
                        child:
                            (patient.avatar == null || patient.avatar!.isEmpty)
                            // Đã sửa: Thay vì hiển thị chữ cái đầu, hiển thị một icon người dùng
                            ? Icon(
                                Icons.person_outline_rounded,
                                size: 40,
                                color: const Color(0xFF2563EB),
                              )
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    patient.patientCode,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: patient.status
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    patient.status
                                        ? "Đang hoạt động"
                                        : "Ngừng hoạt động",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: patient.status
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. PHẦN THÔNG TIN CHI TIẾT CHIA THEO BLOCK/GRID
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _buildMainInfoCard()),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: _buildMedicalAndEmergencyCard(),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildMainInfoCard(),
                          const SizedBox(height: 24),
                          _buildMedicalAndEmergencyCard(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Khối thông tin hành chính & liên hệ
  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: _buildSection(
        "Thông tin cá nhân & Liên hệ",
        Icons.person_outline_rounded,
        [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _infoTile(Icons.wc_rounded, "Giới tính", patient.gender ?? ""),
              _infoTile(
                Icons.cake_outlined,
                "Ngày sinh",
                patient.dateOfBirth ?? "",
              ),
              _infoTile(Icons.phone_outlined, "Số điện thoại", patient.phone),
              _infoTile(Icons.email_outlined, "Email", patient.email),
            ],
          ),
          const SizedBox(height: 16),
          _infoTile(
            Icons.location_on_outlined,
            "Địa chỉ cư trú",
            patient.address ?? "",
          ),
        ],
      ),
    );
  }

  // Khối thông tin y tế bệnh lý và liên hệ khẩn cấp
  Widget _buildMedicalAndEmergencyCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: _buildSection(
            "Hồ sơ y tế cơ bản",
            Icons.health_and_safety_outlined,
            [
              _infoTile(
                Icons.bloodtype_outlined,
                "Nhóm máu",
                patient.bloodType ?? "",
              ),
              const SizedBox(height: 12),
              _infoTile(
                Icons.warning_amber_rounded,
                "Dị ứng",
                patient.allergies ?? "",
              ),
              const SizedBox(height: 12),
              _infoTile(
                Icons.history_edu_rounded,
                "Tiểu sử bệnh án",
                patient.medicalHistory ?? "",
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child:
              _buildSection("Liên hệ khẩn cấp", Icons.contact_phone_outlined, [
                _infoTile(
                  Icons.account_box_outlined,
                  "Người liên hệ",
                  patient.emergencyContactName ?? "",
                ),
                const SizedBox(height: 12),
                _infoTile(
                  Icons.phone_forwarded_outlined,
                  "SĐT khẩn cấp",
                  patient.emergencyContactPhone ?? "",
                ),
              ]),
        ),
      ],
    );
  }
}
