import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';
import '../models/service.dart';
import '../models/doctor_work_schedule.dart';
import '../models/work_shift.dart';
import '../models/patient_model.dart';
import '../services/doctor_service.dart';
import '../services/service_api.dart';
import '../services/patient_service.dart';
import '../services/doctor_work_schedule_service.dart';
import '../services/work_shift.dart';
import '../services/booking_service.dart';

class StaffCreateBookingScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const StaffCreateBookingScreen({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<StaffCreateBookingScreen> createState() => _StaffCreateBookingScreenState();
}

class _StaffCreateBookingScreenState extends State<StaffCreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorService = DoctorService();
  final _scheduleService = DoctorWorkScheduleService();
  final _patientService = PatientService();

  List<Patient> _patients = [];
  List<Service> _services = [];
  List<Doctor> _doctors = [];
  Map<String, WorkShift> _shiftsMap = {};
  List<DoctorWorkSchedule> _doctorSchedules = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  // Selection states
  Patient? _matchedPatient;
  String? _selectedServiceId;
  DoctorWorkSchedule? _selectedSchedule;
  final _reasonCtrl = TextEditingController();

  // Patient inputs
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDob;

  // Filters state for schedules
  String _searchQuery = '';
  String _selectedDateFilter = 'all';
  String _selectedShiftFilter = 'all';

  // Weekdays definition
  final List<Map<String, String>> _weekdays = const [
    {'value': '1', 'label': 'Thứ 2', 'short': 'T2'},
    {'value': '2', 'label': 'Thứ 3', 'short': 'T3'},
    {'value': '3', 'label': 'Thứ 4', 'short': 'T4'},
    {'value': '4', 'label': 'Thứ 5', 'short': 'T5'},
    {'value': '5', 'label': 'Thứ 6', 'short': 'T6'},
    {'value': '6', 'label': 'Thứ 7', 'short': 'T7'},
    {'value': '7', 'label': 'Chủ Nhật', 'short': 'CN'},
  ];

  // Design Colors for Staff Portal
  final Color primaryColor = const Color(0xFF0F766E); // Deep Teal 700
  final Color accentColor = const Color(0xFF2DD4BF); // Turquoise
  final Color bgLight = const Color(0xFFF0FDFA); // Light Jade Green

  @override
  void initState() {
    super.initState();
    _loadData();
    _phoneCtrl.addListener(_lookupPhone);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_lookupPhone);
    _reasonCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _lookupPhone() {
    final phoneInput = _phoneCtrl.text.trim();
    if (phoneInput.length >= 9) {
      Patient? found;
      for (var p in _patients) {
        if (p.phone == phoneInput) {
          found = p;
          break;
        }
      }
      if (found != null) {
        final f = found;
        if (_matchedPatient?.id != f.id) {
          setState(() {
            _matchedPatient = f;
            _fullNameCtrl.text = f.fullName;
            _selectedGender = f.gender;
            if (f.dateOfBirth != null) {
              try {
                _selectedDob = DateTime.parse(f.dateOfBirth!);
              } catch (_) {}
            }
            _emailCtrl.text = f.email;
            _addressCtrl.text = f.address ?? '';
          });
        }
      }
    } else {
      if (_matchedPatient != null) {
        setState(() {
          _matchedPatient = null;
        });
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final patientsList = await _patientService.getPatients();
      final svcs = await ServiceApi.getServices();
      final docs = await _doctorService.getDoctors();
      final shifts = await WorkShiftApi.getAllShifts();
      final schedules = await _scheduleService.getAll();

      final shiftsMap = {for (var s in shifts) s.id: s};

      setState(() {
        _patients = patientsList;
        _services = svcs;
        _doctors = docs;
        _shiftsMap = shiftsMap;
        _doctorSchedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải thông tin: $e';
        _isLoading = false;
      });
    }
  }

  List<DoctorWorkSchedule> get _filteredSchedules {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = _doctorSchedules.where((s) {
      if (s.doctorId == null || s.doctorId!.isEmpty) return false;

      final date = DateTime(s.workDate.year, s.workDate.month, s.workDate.day);
      if (date.isBefore(today)) return false;

      final statusLower = s.status.toLowerCase();
      if (statusLower != 'available' && statusLower != 'active') return false;

      if (_selectedDateFilter != 'all') {
        final weekdayVal = int.tryParse(_selectedDateFilter);
        if (weekdayVal != null && s.workDate.weekday != weekdayVal) return false;
      }

      if (_selectedShiftFilter != 'all') {
        final shift = _shiftsMap[s.workShiftId];
        final shiftName = (shift?.shiftName ?? '').toLowerCase();
        if (_selectedShiftFilter == 'morning' && !shiftName.contains('sáng')) return false;
        if (_selectedShiftFilter == 'afternoon' && !shiftName.contains('chiều')) return false;
        if (_selectedShiftFilter == 'evening' && !shiftName.contains('tối')) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final doctor = _doctors.firstWhere(
          (d) => d.id == s.doctorId,
          orElse: () => Doctor(
            id: s.doctorId ?? '',
            doctorCode: s.doctorCode ?? '',
            fullName: s.doctorName ?? '',
            phone: '',
            email: '',
            status: true,
            specialty: 'Răng Hàm Mặt',
          ),
        );
        final doctorNameLower = doctor.fullName.toLowerCase();
        final specialtyLower = (doctor.specialty ?? 'Răng Hàm Mặt').toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        if (!doctorNameLower.contains(queryLower) && !specialtyLower.contains(queryLower)) {
          return false;
        }
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      int dateCompare = a.workDate.compareTo(b.workDate);
      if (dateCompare != 0) return dateCompare;
      return a.workShiftId.compareTo(b.workShiftId);
    });

    return filtered;
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ca trực của bác sĩ.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final phoneInput = _phoneCtrl.text.trim();
      Patient? finalPatient = _matchedPatient;

      if (finalPatient == null) {
        for (var p in _patients) {
          if (p.phone == phoneInput) {
            finalPatient = p;
            break;
          }
        }
      }

      // If patient does not exist, create a new patient
      if (finalPatient == null) {
        final patientCode = 'BN${DateTime.now().millisecondsSinceEpoch % 1000000}';
        final newPat = await _patientService.createPatient({
          'patient_code': patientCode,
          'full_name': _fullNameCtrl.text.trim(),
          'phone': phoneInput,
          'email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : '$phoneInput@dental-system.local',
          'gender': _selectedGender,
          'date_of_birth': _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : null,
          'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
          'status': true,
        });
        finalPatient = newPat;
      }

      final doctor = _doctors.firstWhere(
        (d) => d.id == _selectedSchedule!.doctorId,
        orElse: () => Doctor(
          id: _selectedSchedule!.doctorId ?? '',
          doctorCode: _selectedSchedule!.doctorCode ?? '',
          fullName: _selectedSchedule!.doctorName ?? 'Bác sĩ',
          phone: '',
          email: '',
          status: true,
          specialty: 'Răng Hàm Mặt',
        ),
      );

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedSchedule!.workDate);
      final shift = _shiftsMap[_selectedSchedule!.workShiftId];
      final slotStr = shift != null
          ? '${shift.shiftName} (${shift.startTime.substring(0, 5)} - ${shift.endTime.substring(0, 5)})'
          : 'Ca ${_selectedSchedule!.workShiftId}';

      final selectedService = _services.firstWhere((s) => s.id == _selectedServiceId);
      final fullSymptoms = '[Staff đăng ký] Dịch vụ: ${selectedService.serviceName}\nYêu cầu khám: ${_reasonCtrl.text.trim()}';

      await BookingService.createBooking(
        patientId: finalPatient.id,
        doctorId: doctor.id,
        bookingDate: dateStr,
        timeSlot: slotStr,
        symptoms: fullSymptoms,
        scheduleId: int.tryParse(_selectedSchedule!.id),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký lịch khám thành công cho bệnh nhân ${finalPatient.fullName}!'), backgroundColor: Colors.green),
      );

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }

      Navigator.pop(context);
    } catch (e, stackTrace) {
      if (!mounted) return;
      print('Submit booking error: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký thất bại: $e\n$stackTrace'), 
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 15),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildShiftFilterChip(String value, String label) {
    final isSelected = _selectedShiftFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedShiftFilter = value;
          });
        }
      },
      selectedColor: primaryColor.withOpacity(0.15),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.grey.shade300,
          width: 1,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: bgLight.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final schedules = _filteredSchedules;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Đăng Ký Hẹn Khám Mới (Staff)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Section: Patient & Service Info
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: _buildPatientFormSection(),
                              ),
                            ),
                            // Divider
                            Container(width: 1, color: Colors.grey.shade200, height: double.infinity),
                            // Right Section: Schedule Selector
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildScheduleFilterHeader(),
                                  Expanded(child: _buildScheduleSelectionGrid(schedules)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPatientFormSection(),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text(
                                'Chọn ca trực của bác sĩ:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              _buildScheduleFilterHeader(),
                              const SizedBox(height: 12),
                              Container(
                                height: 400,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: _buildScheduleSelectionGrid(schedules),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: _isSubmitting
                                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                                    : ElevatedButton(
                                        onPressed: _submitBooking,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text(
                                          'Đăng Ký Đặt Lịch Hẹn',
                                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                ),
    );
  }

  Widget _buildPatientFormSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Thông tin Bệnh nhân & Dịch vụ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),

            // Phone Number Input
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _buildInputDecoration(label: 'Số điện thoại bệnh nhân', icon: Icons.phone_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                if (v.trim().length < 9) return 'Số điện thoại không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 16),

            if (_matchedPatient != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phát hiện hồ sơ: ${_matchedPatient!.fullName} (${_matchedPatient!.patientCode})',
                        style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _matchedPatient = null;
                          _phoneCtrl.clear();
                          _fullNameCtrl.clear();
                          _emailCtrl.clear();
                          _addressCtrl.clear();
                          _selectedGender = null;
                          _selectedDob = null;
                        });
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                      child: const Text('Nhập mới', style: TextStyle(fontSize: 12)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Full Name Input
            TextFormField(
              controller: _fullNameCtrl,
              decoration: _buildInputDecoration(label: 'Họ và tên bệnh nhân', icon: Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên bệnh nhân' : null,
            ),
            const SizedBox(height: 16),

            // Gender and DOB (Row)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    hint: const Text('Giới tính'),
                    items: const [
                      DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                      DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                      DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedGender = val;
                      });
                    },
                    decoration: _buildInputDecoration(label: 'Giới tính', icon: Icons.wc_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDob = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: bgLight.withOpacity(0.1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDob == null
                                ? 'Ngày sinh'
                                : DateFormat('dd/MM/yyyy').format(_selectedDob!),
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedDob == null ? Colors.grey.shade600 : Colors.black87,
                            ),
                          ),
                          Icon(Icons.calendar_today_outlined, size: 16, color: primaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address Input
            TextFormField(
              controller: _addressCtrl,
              decoration: _buildInputDecoration(label: 'Địa chỉ (Tùy chọn)', icon: Icons.location_on_outlined),
            ),
            const SizedBox(height: 16),

            // Email Input
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildInputDecoration(label: 'Email (Tùy chọn)', icon: Icons.email_outlined),
            ),
            const SizedBox(height: 20),

            // Service Dropdown
            if (_services.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedServiceId,
                hint: const Text('Chọn dịch vụ điều trị'),
                items: _services.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    '${s.serviceName} (${NumberFormat('#,###', 'vi_VN').format(s.price)}đ)',
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedServiceId = val;
                  });
                },
                decoration: _buildInputDecoration(label: 'Dịch vụ nha khoa', icon: Icons.medical_services_outlined),
                validator: (v) => v == null ? 'Vui lòng chọn dịch vụ' : null,
              ),
              const SizedBox(height: 20),
            ],

            // Note/Symptoms
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: _buildInputDecoration(label: 'Ghi chú triệu chứng / Lý do khám', icon: Icons.notes_outlined),
              validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập lý do khám' : null,
            ),

            if (MediaQuery.of(context).size.width > 900) ...[
              const SizedBox(height: 32),
              // Submit button directly inside the form for desktop view
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isSubmitting
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : ElevatedButton(
                        onPressed: _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Đăng Ký Đặt Lịch Hẹn',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên BS hoặc chuyên khoa...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Weekday filter
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weekdays.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedDateFilter == 'all';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4, top: 4),
                    child: ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedDateFilter = 'all';
                        });
                      },
                      selectedColor: primaryColor.withOpacity(0.15),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? primaryColor : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade300),
                      ),
                    ),
                  );
                }

                final day = _weekdays[index - 1];
                final val = day['value']!;
                final isSelected = _selectedDateFilter == val;

                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4, top: 4),
                  child: ChoiceChip(
                    label: Text(day['label']!),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedDateFilter = val;
                      });
                    },
                    selectedColor: primaryColor.withOpacity(0.15),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade300),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Shift filter
          Row(
            children: [
              _buildShiftFilterChip('all', 'Tất cả ca'),
              const SizedBox(width: 8),
              _buildShiftFilterChip('morning', 'Ca Sáng'),
              const SizedBox(width: 8),
              _buildShiftFilterChip('afternoon', 'Ca Chiều'),
              const SizedBox(width: 8),
              _buildShiftFilterChip('evening', 'Ca Tối'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSelectionGrid(List<DoctorWorkSchedule> schedules) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Không tìm thấy ca trực phù hợp', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final s = schedules[index];
        final doctor = _doctors.firstWhere(
          (d) => d.id == s.doctorId,
          orElse: () => Doctor(
            id: s.doctorId ?? '',
            doctorCode: s.doctorCode ?? '',
            fullName: s.doctorName ?? 'Bác sĩ',
            phone: '',
            email: '',
            status: true,
            specialty: 'Răng Hàm Mặt',
          ),
        );

        final shift = _shiftsMap[s.workShiftId];
        final shiftName = shift?.shiftName ?? 'Ca ${s.workShiftId}';
        final shiftTime = shift != null
            ? '${shift.startTime.substring(0, 5)} - ${shift.endTime.substring(0, 5)}'
            : '';
        final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(s.workDate);

        final remaining = s.maxPatients - s.currentPatients;
        final isFull = remaining <= 0;
        final isSelected = _selectedSchedule?.id == s.id;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: isFull ? null : () {
              setState(() {
                _selectedSchedule = s;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Radio<String?>(
                    value: s.id,
                    groupValue: _selectedSchedule?.id,
                    activeColor: primaryColor,
                    onChanged: isFull ? null : (val) {
                      setState(() {
                        _selectedSchedule = s;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      doctor.fullName.isNotEmpty ? doctor.fullName.split(' ').last[0] : 'B',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BS. ${doctor.fullName} (${doctor.specialty ?? 'Răng Hàm Mặt'})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isFull ? Colors.grey : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('$shiftName ($shiftTime)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFull
                          ? Colors.red.shade50
                          : (remaining <= 3 ? Colors.orange.shade50 : bgLight),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFull
                            ? Colors.red.shade200
                            : (remaining <= 3 ? Colors.orange.shade200 : primaryColor.withOpacity(0.3)),
                      ),
                    ),
                    child: Text(
                      isFull ? 'Hết chỗ' : 'Còn $remaining chỗ',
                      style: TextStyle(
                        color: isFull
                            ? Colors.red.shade700
                            : (remaining <= 3 ? Colors.orange.shade700 : primaryColor),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
