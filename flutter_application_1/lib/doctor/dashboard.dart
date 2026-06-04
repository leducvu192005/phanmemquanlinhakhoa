import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/appointment_model.dart';
import '../models/patient_model.dart';
import '../models/service.dart';
import '../services/appointment_service.dart';
import '../services/medical_record_service.dart';
import '../services/service_api.dart';
import '../services/api.dart';
import '../services/doctor_service.dart';
import '../login.dart';
import 'profile_screen.dart';
import 'schedule_register_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final _storage = const FlutterSecureStorage();
  
  bool _isLoadingAppointments = true;
  bool _isLoadingServices = true;
  List<Appointment> _appointments = [];
  List<Service> _allServices = [];
  Appointment? _selectedAppointment;
  
  // Thông tin bác sĩ đăng nhập
  String _doctorName = "Bác sĩ";
  String _doctorSpecialty = "Nha khoa tổng quát";
  String? _doctorAvatarUrl;

  // Form cập nhật bệnh án
  final _formKey = GlobalKey<FormState>();
  final _diagnosisCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _followUpDate;
  
  // Dịch vụ nha khoa được chỉ định
  final List<String> _selectedServiceIds = [];

  // Đơn thuốc động
  final List<Map<String, String>> _prescriptionList = [];
  final _medNameCtrl = TextEditingController();
  final _medQtyCtrl = TextEditingController();
  final _medUsageCtrl = TextEditingController();

  final Color primaryTeal = const Color(0xFF0F766E);
  final Color lightTeal = const Color(0xFFE6F7F6);
  final Color accentTeal = const Color(0xFF2DD4BF);

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
    _fetchAppointments();
    _fetchServices();
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _treatmentCtrl.dispose();
    _notesCtrl.dispose();
    _medNameCtrl.dispose();
    _medQtyCtrl.dispose();
    _medUsageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorInfo() async {
    final token = await _storage.read(key: 'jwt');
    if (token != null) {
      try {
        final doc = await DoctorService().getMyProfile();
        setState(() {
          _doctorName = doc.fullName;
          _doctorSpecialty = doc.specialty ?? 'Nha khoa tổng quát';
          _doctorAvatarUrl = doc.avatar;
        });
      } catch (e) {
        print('Error loading doctor info via doctor_service: $e');
        try {
          final baseUrl = Api.baseUrl;
          final res = await http.get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (res.statusCode == 200) {
            final user = jsonDecode(utf8.decode(res.bodyBytes));
            setState(() {
              _doctorName = user['username'] ?? 'Bác sĩ';
            });
          }
        } catch (err) {
          print('Error loading doctor info fallback: $err');
        }
      }
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoadingAppointments = true);
    try {
      final list = await AppointmentService.getDoctorTodayAppointments();
      setState(() {
        _appointments = list;
        // Tự động chọn ca đầu tiên nếu chưa chọn và danh sách có dữ liệu
        if (_selectedAppointment == null && list.isNotEmpty) {
          _selectAppointment(list.first);
        } else if (_selectedAppointment != null) {
          // Cập nhật lại ca đang chọn nếu có thay đổi từ DB
          final updated = list.firstWhere(
            (element) => element.id == _selectedAppointment!.id,
            orElse: () => list.first,
          );
          _selectAppointment(updated);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải lịch hẹn hôm nay: $e')),
      );
    } finally {
      setState(() => _isLoadingAppointments = false);
    }
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoadingServices = true);
    try {
      // Vì ServiceApi có thể fetch hết hoặc theo từ khóa, ta lấy hết dịch vụ hoạt động
      final list = await ServiceApi.getServices();
      setState(() {
        _allServices = list.where((s) => s.status == true).toList();
      });
    } catch (e) {
      print('Error fetching services: $e');
    } finally {
      setState(() => _isLoadingServices = false);
    }
  }

  void _selectAppointment(Appointment appointment) {
    setState(() {
      _selectedAppointment = appointment;
      // Reset form cập nhật khi đổi ca khám
      _diagnosisCtrl.clear();
      _treatmentCtrl.clear();
      _notesCtrl.clear();
      _followUpDate = null;
      _selectedServiceIds.clear();
      _prescriptionList.clear();

      // Nếu ca khám đã hoàn thành từ trước, có thể load bệnh án lên nếu có (ở đây làm form tạo mới cho ca chưa khám)
    });
  }

  Future<void> _doLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản Bác sĩ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _storage.deleteAll();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Thêm thuốc vào đơn thuốc tạm thời
  void _addMedicine() {
    if (_medNameCtrl.text.trim().isEmpty) return;
    setState(() {
      _prescriptionList.add({
        'name': _medNameCtrl.text.trim(),
        'qty': _medQtyCtrl.text.trim().isEmpty ? '1' : _medQtyCtrl.text.trim(),
        'usage': _medUsageCtrl.text.trim().isEmpty ? 'Uống sau ăn' : _medUsageCtrl.text.trim(),
      });
      _medNameCtrl.clear();
      _medQtyCtrl.clear();
      _medUsageCtrl.clear();
    });
  }

  // Xóa thuốc khỏi đơn tạm thời
  void _removeMedicine(int index) {
    setState(() {
      _prescriptionList.removeAt(index);
    });
  }

  // Gửi kết quả hoàn thành ca khám
  Future<void> _submitExamination() async {
    if (_selectedAppointment == null) return;
    if (!_formKey.currentState!.validate()) return;

    // Gộp đơn thuốc thành chuỗi văn bản gửi lên trường prescription dạng text
    String prescriptionText = "";
    if (_prescriptionList.isNotEmpty) {
      prescriptionText = _prescriptionList
          .map((m) => "- ${m['name']} (${m['qty']}): ${m['usage']}")
          .join('\n');
    }

    final payload = {
      'appointment_id': int.parse(_selectedAppointment!.id),
      'patient_id': int.parse(_selectedAppointment!.patientId),
      'doctor_id': int.parse(_selectedAppointment!.doctorId),
      'diagnosis': _diagnosisCtrl.text.trim(),
      'treatment': _treatmentCtrl.text.trim(),
      'prescription': prescriptionText.isEmpty ? null : prescriptionText,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'follow_up_date': _followUpDate != null
          ? DateFormat('yyyy-MM-dd').format(_followUpDate!)
          : null,
      'indicated_service_ids': _selectedServiceIds.map((id) => int.parse(id)).toList(),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await MedicalRecordService.createMedicalRecord(payload);
      Navigator.pop(context); // Đóng loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu bệnh án và hoàn thành ca khám thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh lịch khám
      await _fetchAppointments();
    } catch (e) {
      Navigator.pop(context); // Đóng loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể hoàn thành ca khám: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 950;
    final String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.medical_services_outlined, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Phòng Khám Nha Khoa - Bác Sĩ',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Hôm nay: $formattedDate',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            tooltip: 'Đăng ký lịch trực',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DoctorScheduleRegisterScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Hồ sơ cá nhân',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
              ).then((_) => _loadDoctorInfo());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: _doLogout,
          ),
        ],
      ),
      body: Row(
        children: [
          // 1. CỘT TRÁI: DANH SÁCH CA KHÁM (Chiếm 1/3 màn hình rộng hoặc toàn màn hình nếu trên điện thoại)
          Expanded(
            flex: isWide ? 4 : 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header danh sách ca khám
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: lightTeal,
                              backgroundImage: _doctorAvatarUrl != null && _doctorAvatarUrl!.isNotEmpty
                                  ? NetworkImage(_doctorAvatarUrl!.startsWith('http')
                                      ? _doctorAvatarUrl!
                                      : '${Api.baseUrl}$_doctorAvatarUrl')
                                  : null,
                              child: _doctorAvatarUrl == null || _doctorAvatarUrl!.isEmpty
                                  ? Icon(Icons.person, color: primaryTeal)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _doctorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  _doctorSpecialty,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Danh sách ca khám hôm nay',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: _fetchAppointments,
                              color: primaryTeal,
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Danh sách
                  Expanded(
                    child: _isLoadingAppointments
                        ? const Center(child: CircularProgressIndicator())
                        : _appointments.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Không có lịch hẹn nào hôm nay',
                                        style: TextStyle(color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _appointments.length,
                                itemBuilder: (context, index) {
                                  final app = _appointments[index];
                                  final isSelected = _selectedAppointment?.id == app.id;
                                  final timeStr = DateFormat('HH:mm').format(app.appointmentTime);
                                  
                                  Color statusColor = Colors.orange;
                                  String statusText = "Chờ khám";
                                  if (app.status == 'completed') {
                                    statusColor = Colors.green;
                                    statusText = "Đã khám";
                                  } else if (app.status == 'confirmed') {
                                    statusColor = Colors.blue;
                                    statusText = "Đã xác nhận";
                                  } else if (app.status == 'cancelled') {
                                    statusColor = Colors.red;
                                    statusText = "Đã hủy";
                                  }

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? lightTeal : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? primaryTeal : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          timeStr,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        app.patient?.fullName ?? 'Bệnh nhân chưa rõ',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            'Dịch vụ đặt trước: ${app.service?.serviceName ?? "Khám tổng quát"}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          if (app.reason != null && app.reason!.isNotEmpty)
                                            Text(
                                              'Lý do: ${app.reason}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                            ),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      onTap: () {
                                        _selectAppointment(app);
                                        if (!isWide) {
                                          // Trên điện thoại, khi tap sẽ mở màn hình chi tiết/khám bệnh đầy đủ
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MobileExaminationScreen(
                                                appointment: app,
                                                allServices: _allServices,
                                                onCompleted: () {
                                                  _fetchAppointments();
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),

          // 2. CỘT PHẢI: CHI TIẾT HỒ SƠ VÀ NHẬP KẾT QUẢ KHÁM (Chỉ hiện trực tiếp nếu màn hình Desktop/Web rộng)
          if (isWide)
            Expanded(
              flex: 8,
              child: _selectedAppointment == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Vui lòng chọn một ca khám để xem chi tiết', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // THÔNG TIN BỆNH NHÂN
                          _buildPatientProfileSection(_selectedAppointment!.patient),
                          const SizedBox(height: 24),

                          // NẾU CA ĐÃ KHÁM XONG
                          if (_selectedAppointment!.status == 'completed')
                            _buildCompletedExaminationNotice(_selectedAppointment!)
                          else
                            // FORM GHI NHẬN KHÁM BỆNH
                            _buildExaminationFormSection(),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  // Giao diện hiển thị chi tiết hồ sơ bệnh nhân
  Widget _buildPatientProfileSection(Patient? patient) {
    if (patient == null) return const SizedBox();
    final dob = patient.dateOfBirth;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'HỒ SƠ BỆNH NHÂN',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 0.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    patient.patientCode,
                    style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryTeal.withOpacity(0.1),
                  child: Text(
                    patient.fullName.substring(0, 1).toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTeal),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3,
                    ),
                    children: [
                      _buildProfileItem('Họ và tên', patient.fullName),
                      _buildProfileItem('Giới tính', patient.gender),
                      _buildProfileItem('Ngày sinh', dob),
                      _buildProfileItem('Số điện thoại', patient.phone),
                      _buildProfileItem('Nhóm máu', patient.bloodType ?? 'Chưa rõ'),
                      _buildProfileItem('Dị ứng thuốc', patient.allergies ?? 'Không có', isAlert: patient.allergies != null && patient.allergies!.isNotEmpty),
                    ],
                  ),
                )
              ],
            ),
            if (patient.medicalHistory != null && patient.medicalHistory!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Tiền sử bệnh án:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                patient.medicalHistory!,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isAlert ? Colors.redAccent : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Widget thông báo ca khám đã khám xong
  Widget _buildCompletedExaminationNotice(Appointment app) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Ca khám đã hoàn thành',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text(
            'Bệnh án điều trị cho ca khám này đã được bác sĩ lưu vào hệ thống cơ sở dữ liệu thật của phòng khám.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green.shade800, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Form nhập bệnh án điều trị cho Bác sĩ (trên Desktop/Web)
  Widget _buildExaminationFormSection() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KẾT QUẢ KHÁM & CHỈ ĐỊNH ĐIỀU TRỊ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 20),

              // 1. Chẩn đoán
              TextFormField(
                controller: _diagnosisCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Chẩn đoán lâm sàng *',
                  hintText: 'Nhập tình trạng răng miệng của bệnh nhân...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.search),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập chẩn đoán lâm sàng' : null,
              ),
              const SizedBox(height: 16),

              // 2. Phương pháp điều trị
              TextFormField(
                controller: _treatmentCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Phương pháp điều trị thực hiện *',
                  hintText: 'Nhập phương pháp xử lý (ví dụ: hàn composite răng số 36)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.settings),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập phương pháp điều trị' : null,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // 3. Chỉ định dịch vụ điều trị (lấy thật từ DB)
              const Text(
                'Chỉ định dịch vụ nha khoa điều trị:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _isLoadingServices
                  ? const Center(child: CircularProgressIndicator())
                  : _allServices.isEmpty
                      ? const Text('Không có danh mục dịch vụ điều trị khả dụng.')
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _allServices.map((service) {
                            final isSelected = _selectedServiceIds.contains(service.id);
                            return FilterChip(
                              label: Text('${service.serviceName} (${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(service.price)})'),
                              selected: isSelected,
                              selectedColor: lightTeal,
                              checkmarkColor: primaryTeal,
                              labelStyle: TextStyle(
                                color: isSelected ? primaryTeal : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: isSelected ? primaryTeal : Colors.grey.shade300),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedServiceIds.add(service.id);
                                  } else {
                                    _selectedServiceIds.remove(service.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // 4. Kê đơn thuốc động
              const Text(
                'Kê đơn thuốc điều trị:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              // Ô nhập thuốc
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _medNameCtrl,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Tên thuốc',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _medQtyCtrl,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'SL',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _medUsageCtrl,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Cách dùng',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addMedicine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Danh sách thuốc đã thêm
              if (_prescriptionList.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _prescriptionList.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final med = _prescriptionList[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${index + 1}. ${med['name']} (${med['qty']})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Hướng dẫn: ${med['usage']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          onPressed: () => _removeMedicine(index),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // 5. Ghi chú thêm & Ngày tái khám
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: TextField(
                      controller: _notesCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú khuyên dùng',
                        hintText: 'Ví dụ: Hạn chế đồ ăn cứng lạnh trong 24h...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _followUpDate == null
                            ? 'Chọn ngày tái khám'
                            : 'Hẹn tái khám: ${DateFormat('dd/MM/yyyy').format(_followUpDate!)}',
                        style: TextStyle(color: _followUpDate == null ? Colors.black54 : primaryTeal),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _followUpDate = picked);
                        }
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),

              // NÚT HOÀN THÀNH CA KHÁM
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitExamination,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded),
                      SizedBox(width: 8),
                      Text(
                        'Hoàn thành ca khám bệnh',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH KHÁM BỆNH CHO THIẾT BỊ DI ĐỘNG (MOBILE VIEW)
// ==========================================
class MobileExaminationScreen extends StatefulWidget {
  final Appointment appointment;
  final List<Service> allServices;
  final VoidCallback onCompleted;

  const MobileExaminationScreen({
    Key? key,
    required this.appointment,
    required this.allServices,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<MobileExaminationScreen> createState() => _MobileExaminationScreenState();
}

class _MobileExaminationScreenState extends State<MobileExaminationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _followUpDate;

  final List<String> _selectedServiceIds = [];
  final List<Map<String, String>> _prescriptionList = [];

  final _medNameCtrl = TextEditingController();
  final _medQtyCtrl = TextEditingController();
  final _medUsageCtrl = TextEditingController();

  final Color primaryTeal = const Color(0xFF0F766E);
  final Color lightTeal = const Color(0xFFE6F7F6);

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _treatmentCtrl.dispose();
    _notesCtrl.dispose();
    _medNameCtrl.dispose();
    _medQtyCtrl.dispose();
    _medUsageCtrl.dispose();
    super.dispose();
  }

  void _addMedicine() {
    if (_medNameCtrl.text.trim().isEmpty) return;
    setState(() {
      _prescriptionList.add({
        'name': _medNameCtrl.text.trim(),
        'qty': _medQtyCtrl.text.trim().isEmpty ? '1' : _medQtyCtrl.text.trim(),
        'usage': _medUsageCtrl.text.trim().isEmpty ? 'Uống sau ăn' : _medUsageCtrl.text.trim(),
      });
      _medNameCtrl.clear();
      _medQtyCtrl.clear();
      _medUsageCtrl.clear();
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      _prescriptionList.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String prescriptionText = "";
    if (_prescriptionList.isNotEmpty) {
      prescriptionText = _prescriptionList
          .map((m) => "- ${m['name']} (${m['qty']}): ${m['usage']}")
          .join('\n');
    }

    final payload = {
      'appointment_id': int.parse(widget.appointment.id),
      'patient_id': int.parse(widget.appointment.patientId),
      'doctor_id': int.parse(widget.appointment.doctorId),
      'diagnosis': _diagnosisCtrl.text.trim(),
      'treatment': _treatmentCtrl.text.trim(),
      'prescription': prescriptionText.isEmpty ? null : prescriptionText,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'follow_up_date': _followUpDate != null
          ? DateFormat('yyyy-MM-dd').format(_followUpDate!)
          : null,
      'indicated_service_ids': _selectedServiceIds.map((id) => int.parse(id)).toList(),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await MedicalRecordService.createMedicalRecord(payload);
      Navigator.pop(context); // Đóng loading dialog
      widget.onCompleted();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hoàn thành ca khám: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.appointment.patient;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryTeal,
        title: Text(patient?.fullName ?? 'Chi tiết ca khám'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin bệnh nhân rút gọn
            if (patient != null)
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bệnh nhân: ${patient.fullName} (${patient.gender})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('SĐT: ${patient.phone} | Ngày sinh: ${patient.dateOfBirth}'),
                      if (patient.allergies != null && patient.allergies!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Dị ứng: ${patient.allergies}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ]
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            if (widget.appointment.status == 'completed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(height: 8),
                    Text('Ca khám đã hoàn thành công việc khám bệnh.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chẩn đoán
                    TextFormField(
                      controller: _diagnosisCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Chẩn đoán lâm sàng *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập chẩn đoán' : null,
                    ),
                    const SizedBox(height: 16),

                    // Phương pháp điều trị
                    TextFormField(
                      controller: _treatmentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Điều trị thực tế *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập điều trị' : null,
                    ),
                    const SizedBox(height: 16),

                    // Chỉ định dịch vụ
                    const Text('Chỉ định dịch vụ thêm:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.allServices.map((service) {
                        final isSelected = _selectedServiceIds.contains(service.id);
                        return ChoiceChip(
                          label: Text(service.serviceName, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServiceIds.add(service.id);
                              } else {
                                _selectedServiceIds.remove(service.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Đơn thuốc
                    const Text('Kê đơn thuốc:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _medNameCtrl,
                            decoration: const InputDecoration(labelText: 'Tên thuốc', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _medQtyCtrl,
                            decoration: const InputDecoration(labelText: 'SL', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: primaryTeal, size: 30),
                          onPressed: _addMedicine,
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _medUsageCtrl,
                      decoration: const InputDecoration(labelText: 'Hướng dẫn sử dụng', isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    // Danh sách thuốc
                    if (_prescriptionList.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _prescriptionList.length,
                        itemBuilder: (context, index) {
                          final med = _prescriptionList[index];
                          return ListTile(
                            dense: true,
                            title: Text('${med['name']} (${med['qty']})'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeMedicine(index),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),

                    // Hẹn tái khám
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(_followUpDate == null
                          ? 'Đặt ngày tái khám'
                          : 'Tái khám: ${DateFormat('dd/MM/yyyy').format(_followUpDate!)}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _followUpDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Nút gửi
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white),
                        child: const Text('Hoàn thành ca khám', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
