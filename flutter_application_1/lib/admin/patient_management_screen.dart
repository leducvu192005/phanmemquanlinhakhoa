import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin/patient_detail_screen.dart';
import '../../models/patient_model.dart';
import '/services/patient_service.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  String _currentMenu = "Bệnh nhân";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: Container(
        color: const Color(0xFFF47808),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  child: PatientManagementContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title) {
    final bool isSelected = _currentMenu == title;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _currentMenu = title);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Màu nền nhẹ khi được click chọn giống bản mẫu
            color: isSelected ? const Color(0xFFE0E7FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
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

  int calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    return age;
  }

  Future<void> fetchPatients({String? query}) async {
    setState(() => isLoading = true);
    try {
      final data = await userService.getPatients(query: query);
      setState(() {
        patients = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
    }
  }

  Future<void> _showEditPatientDialog(Patient p) async {
    final nameCtrl = TextEditingController(text: p.fullName);
    final phoneCtrl = TextEditingController(text: p.phone);
    final emailCtrl = TextEditingController(text: p.email);
    final addressCtrl = TextEditingController(text: p.address ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sửa bệnh nhân"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Họ tên"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: "Số điện thoại"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: "Địa chỉ"),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Hủy"),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  await userService.updatePatient(p.id, {
                    "full_name": nameCtrl.text,
                    "phone": phoneCtrl.text,
                    "email": emailCtrl.text,
                    "address": addressCtrl.text,
                  });

                  if (!mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cập nhật thành công")),
                  );

                  fetchPatients();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Lỗi cập nhật: $e")));
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(Patient p) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Xóa bệnh nhân"),
          content: Text("Bạn có chắc muốn xóa ${p.fullName} không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Hủy"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Xóa"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await userService.deletePatient(p.id);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã xóa bệnh nhân")));

        fetchPatients();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi xóa: $e")));
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Thẻ trạng thái tròn nhỏ tinh tế
  Widget _statusPill(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? "Active" : "Inactive",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ nhãn nhỏ cho phần dị ứng hoặc phân loại VIP
  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Cấu trúc một hàng thông tin bệnh nhân dạng Thẻ phẳng (Flat Card) chuyên nghiệp
  Widget _buildPatientCard(Patient p) {
    // Trích xuất chữ cái đầu của tên để làm Avatar mẫu
    final String initial = p.fullName.isNotEmpty
        ? p.fullName.trim().split(' ').last.substring(0, 1).toUpperCase()
        : "?";
    final bool isVip = p.fullName.contains(
      "Hương",
    ); // Giả định điều kiện logic VIP cho đồng bộ hình ảnh mẫu
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: p)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            /// 1. AVATAR & TÊN CHÍNH
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                fontSize: 15,
                              ),
                            ),
                            if (isVip) ...[
                              const SizedBox(width: 6),
                              _buildBadge(
                                "VIP",
                                const Color(0xFFFEF3C7),
                                const Color(0xFFD97706),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.patientCode,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// 2. THÔNG TIN LIÊN HỆ
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.mail_outlined,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.email,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.phone,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p.address ?? "Không có địa chỉ",
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// 3. CƠ BẢN (TUỔI, GIỚI TÍNH)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tuổi: ${calculateAge(DateTime.parse(p.dateOfBirth))} tuổi",
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Giới tính: ${p.gender ?? 'Nam'}",
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            /// 4. TIỀN SỬ BỆNH LÝ
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tiền sử / Dị ứng:",
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (p.allergies != null && p.allergies!.isNotEmpty)
                    _buildBadge(
                      p.allergies!,
                      const Color(0xFFFEE2E2),
                      const Color(0xFFEF4444),
                    )
                  else
                    const Text(
                      "Không có dữ liệu",
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                ],
              ),
            ),

            /// 5. LẦN KHÁM GẦN NHẤT
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lần khám cuối",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.lastVisit != null
                        ? "${p.lastVisit!.day}/${p.lastVisit!.month}/${p.lastVisit!.year}"
                        : "Chưa khám",
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 2),
                ],
              ),
            ),
            Row(children: [Text('${p.notes ?? "Không có ghi chú nào"}')]),

            /// 6. TRẠNG THÁI & HÀNH ĐỘNG
            Row(
              children: [
                _statusPill(p.status),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  onPressed: () {
                    _showEditPatientDialog(p);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  onPressed: () {
                    _confirmDelete(p);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị từng thẻ KPI thống kê ở trên cùng
  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtext,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (subtext != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        subtext,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// TOP BAR (Tiêu đề và Nút thêm)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Quản lý bệnh nhân",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Quản lý thông tin và hồ sơ bệnh nhân nha khoa",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
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
                fetchPatients();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                "Thêm bệnh nhân",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        /// KPI STATS CARDS (Thống kê như ảnh thiết kế mẫu)
        Row(
          children: [
            _buildKpiCard(
              "Tổng bệnh nhân",
              patients.length.toString(),
              Icons.people_alt_outlined,
              const Color(0xFF2563EB),
            ),
            const SizedBox(width: 16),
            _buildKpiCard(
              "Đang hoạt động",
              "4",
              Icons.toggle_on_outlined,
              const Color(0xFF16A34A),
            ),
            const SizedBox(width: 16),
            _buildKpiCard(
              "Mới tháng này",
              "4",
              Icons.person_add_alt_1_outlined,
              const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 16),
            _buildKpiCard(
              "Tăng trưởng",
              "+12%",
              Icons.trending_up_rounded,
              const Color(0xFFEA580C),
              subtext: "↑",
            ),
          ],
        ),
        const SizedBox(height: 24),

        /// SEARCH BAR & FILTER BUTTONS
        Row(
          children: [
            Expanded(
              child: Container(
                height: 67,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    print("SEARCH INPUT: $v");
                    fetchPatients(query: v);
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    hintText:
                        "Tìm kiếm bệnh nhân theo tên, số điện thoại, mã...",
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        /// LIST OF PATIENT CARDS
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                )
              : patients.isEmpty
              ? const Center(
                  child: Text(
                    "Không tìm thấy bệnh nhân nào",
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              : ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    return _buildPatientCard(patients[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String text) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}
