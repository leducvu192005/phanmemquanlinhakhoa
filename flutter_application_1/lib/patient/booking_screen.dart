import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';
import '../models/service.dart';
import '../models/doctor_work_schedule.dart';
import '../models/work_shift.dart';
import '../services/doctor_service.dart';
import '../services/service_api.dart';
import '../services/patient_service.dart';
import '../services/doctor_work_schedule_service.dart';
import '../services/work_shift.dart';
import '../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  final VoidCallback? onBookingSuccess;
  const BookingScreen({super.key, this.onBookingSuccess});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorService = DoctorService();
  final _scheduleService = DoctorWorkScheduleService();

  List<Service> _services = [];
  List<Doctor> _doctors = [];
  Map<String, WorkShift> _shiftsMap = {};
  List<DoctorWorkSchedule> _doctorSchedules = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _patientId;
  String _errorMessage = '';

  // Filters state
  String _searchQuery = '';
  String _selectedDateFilter = 'all';
  String _selectedShiftFilter = 'all';

  // Controller for booking notes/symptoms
  final _reasonCtrl = TextEditingController();
  String? _selectedServiceId;

  // Design Colors
  final Color primaryColor = const Color(0xFF0D9488); // Xanh Ngọc (Teal 600)
  final Color accentColor = const Color(0xFF2DD4BF); // Turquoise
  final Color bgLight = const Color(0xFFF0FDFA); // Light Jade Green

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final patient = await PatientService.getMyProfile();
      final svcs = await ServiceApi.getServices();
      final docs = await _doctorService.getDoctors();
      final shifts = await WorkShiftApi.getAllShifts();
      final schedules = await _scheduleService.getAll(); // Load all schedules

      final shiftsMap = {for (var s in shifts) s.id: s};

      setState(() {
        _patientId = patient.id;
        _services = svcs;
        _doctors = docs;
        _shiftsMap = shiftsMap;
        _doctorSchedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải thông tin phòng khám: $e';
        _isLoading = false;
      });
    }
  }

  // Weekdays list for filtering schedules by day of week
  final List<Map<String, String>> _weekdays = const [
    {'value': '1', 'label': 'Thứ 2', 'short': 'T2'},
    {'value': '2', 'label': 'Thứ 3', 'short': 'T3'},
    {'value': '3', 'label': 'Thứ 4', 'short': 'T4'},
    {'value': '4', 'label': 'Thứ 5', 'short': 'T5'},
    {'value': '5', 'label': 'Thứ 6', 'short': 'T6'},
    {'value': '6', 'label': 'Thứ 7', 'short': 'T7'},
    {'value': '7', 'label': 'Chủ Nhật', 'short': 'CN'},
  ];



  // Filters doctor work schedules based on user selection
  List<DoctorWorkSchedule> get _filteredSchedules {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = _doctorSchedules.where((s) {
      // 1. Must have a doctor assigned
      if (s.doctorId == null || s.doctorId!.isEmpty) return false;

      // 2. Filter out past schedules
      final date = DateTime(s.workDate.year, s.workDate.month, s.workDate.day);
      if (date.isBefore(today)) return false;

      // 3. Status must be available (or active)
      final statusLower = s.status.toLowerCase();
      if (statusLower != 'available' && statusLower != 'active') return false;

      // 4. Filter by weekday
      if (_selectedDateFilter != 'all') {
        final weekdayVal = int.tryParse(_selectedDateFilter);
        if (weekdayVal != null && s.workDate.weekday != weekdayVal) return false;
      }

      // 5. Filter by shift type
      if (_selectedShiftFilter != 'all') {
        final shift = _shiftsMap[s.workShiftId];
        final shiftName = (shift?.shiftName ?? '').toLowerCase();
        if (_selectedShiftFilter == 'morning' && !shiftName.contains('sáng'))
          return false;
        if (_selectedShiftFilter == 'afternoon' && !shiftName.contains('chiều'))
          return false;
        if (_selectedShiftFilter == 'evening' && !shiftName.contains('tối'))
          return false;
      }

      // 6. Filter by search query (doctor name / specialty)
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
        final specialtyLower = (doctor.specialty ?? 'Răng Hàm Mặt')
            .toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        if (!doctorNameLower.contains(queryLower) &&
            !specialtyLower.contains(queryLower)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by date then by shift id
    filtered.sort((a, b) {
      int dateCompare = a.workDate.compareTo(b.workDate);
      if (dateCompare != 0) return dateCompare;
      return a.workShiftId.compareTo(b.workShiftId);
    });

    return filtered;
  }

  Future<bool> _submitBooking({
    required DoctorWorkSchedule schedule,
    required Doctor doctor,
    required Service service,
    required String symptoms,
    required BuildContext sheetContext,
  }) async {
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Chưa tải được hồ sơ bệnh nhân.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(schedule.workDate);
      final shift = _shiftsMap[schedule.workShiftId];
      final slotStr = shift != null
          ? '${shift.shiftName} (${shift.startTime.substring(0, 5)} - ${shift.endTime.substring(0, 5)})'
          : 'Ca ${schedule.workShiftId}';

      final fullSymptoms =
          'Dịch vụ: ${service.serviceName}\nYêu cầu khám: $symptoms';

      await BookingService.createBooking(
        patientId: _patientId!,
        doctorId: doctor.id,
        bookingDate: dateStr,
        timeSlot: slotStr,
        symptoms: fullSymptoms,
        scheduleId: int.tryParse(schedule.id),
      );

      if (!mounted || !sheetContext.mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đặt lịch khám thành công! Vui lòng chờ phòng khám duyệt.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh layout data to get updated patients count
      _loadData();

      // Close bottom sheet
      Navigator.pop(sheetContext);

      if (widget.onBookingSuccess != null) {
        widget.onBookingSuccess!();
      } else {
        Navigator.pop(context, true);
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt lịch thất bại: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }
  }

  void _showBookingConfirmSheet(DoctorWorkSchedule schedule) {
    final doctor = _doctors.firstWhere(
      (d) => d.id == schedule.doctorId,
      orElse: () => Doctor(
        id: schedule.doctorId ?? '',
        doctorCode: schedule.doctorCode ?? '',
        fullName: schedule.doctorName ?? 'Bác sĩ',
        phone: '',
        email: '',
        status: true,
        specialty: 'Răng Hàm Mặt',
      ),
    );

    final shift = _shiftsMap[schedule.workShiftId];
    final shiftName = shift?.shiftName ?? 'Ca ${schedule.workShiftId}';
    final shiftTime = shift != null
        ? '${shift.startTime.substring(0, 5)} - ${shift.endTime.substring(0, 5)}'
        : '';
    final dateStr = DateFormat(
      'EEEE, dd/MM/yyyy',
      'vi_VN',
    ).format(schedule.workDate);

    // Default to the first service
    String? localServiceId =
        _selectedServiceId ??
        (_services.isNotEmpty ? _services.first.id : null);
    _reasonCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bottom Sheet Handle Bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chi tiết Đặt lịch',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Doctor & Shift summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  radius: 22,
                                  child: Text(
                                    doctor.fullName.isNotEmpty
                                        ? doctor.fullName.split(' ').last[0]
                                        : 'B',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BS. ${doctor.fullName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        doctor.specialty ?? 'Răng Hàm Mặt',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              height: 24,
                              thickness: 1,
                              color: Colors.black12,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_outlined,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$shiftName ($shiftTime)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Service Dropdown
                      if (_services.isNotEmpty) ...[
                        const Text(
                          'Dịch vụ mong muốn:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: localServiceId,
                          items: _services
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    '${s.serviceName} (${NumberFormat('#,###', 'vi_VN').format(s.price)}đ)',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setModalState(() {
                              localServiceId = val;
                            });
                          },
                          decoration: _buildInputDecoration(
                            label: 'Chọn dịch vụ',
                            icon: Icons.medical_services_outlined,
                          ),
                          validator: (v) =>
                              v == null ? 'Vui lòng chọn dịch vụ' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Reason/Symptoms Text Field
                      const Text(
                        'Lý do khám / Triệu chứng:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonCtrl,
                        maxLines: 3,
                        decoration: _buildInputDecoration(
                          label: 'Mô tả ngắn gọn triệu chứng hoặc lý do',
                          icon: Icons.notes_outlined,
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Vui lòng nhập triệu chứng/lý do khám'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: _isSubmitting
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate())
                                    return;

                                  setModalState(() {
                                    _isSubmitting = true;
                                  });

                                  final selectedService = _services.firstWhere(
                                    (s) => s.id == localServiceId,
                                  );

                                  await _submitBooking(
                                    schedule: schedule,
                                    doctor: doctor,
                                    service: selectedService,
                                    symptoms: _reasonCtrl.text.trim(),
                                    sheetContext: sheetContext,
                                  );

                                  setModalState(() {
                                    _isSubmitting = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Đăng Ký Đặt Lịch Hẹn',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
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
      },
    );
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
    final isWide = MediaQuery.of(context).size.width > 650;
    final schedules = _filteredSchedules;

    return Scaffold(
      backgroundColor: bgLight,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Gradient Header + Search Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 36),
                      const Text(
                        'Tìm ca khám phù hợp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chọn bác sĩ và ca trực để đăng ký lịch hẹn khám nhanh chóng',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search Input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên bác sĩ hoặc chuyên khoa...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(Icons.search, color: primaryColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Date Filters Horizontal Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'Lọc theo ngày khám',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 20, right: 10),
                        itemCount: _weekdays.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = _selectedDateFilter == 'all';
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: 10,
                                bottom: 8,
                                top: 4,
                              ),
                              child: Material(
                                color: isSelected ? primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDateFilter = 'all';
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.grey.shade300,
                                        width: 1.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Tất cả',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final day = _weekdays[index - 1];
                          final val = day['value']!;
                          final isSelected = _selectedDateFilter == val;

                          return Padding(
                            padding: const EdgeInsets.only(
                              right: 10,
                              bottom: 8,
                              top: 4,
                            ),
                            child: Material(
                              color: isSelected ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDateFilter = val;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 75,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey.shade300,
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        day['short']!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.black45,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        day['label']!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Shifts Filters Horizontal Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          _buildShiftFilterChip('all', 'Tất cả ca'),
                          const SizedBox(width: 7),
                          _buildShiftFilterChip('morning', 'Ca Sáng'),
                          const SizedBox(width: 7),
                          _buildShiftFilterChip('afternoon', 'Ca Chiều'),
                          const SizedBox(width: 7),
                          _buildShiftFilterChip('evening', 'Ca Tối'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Cards List
                Expanded(
                  child: schedules.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 48,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Không tìm thấy ca trực phù hợp',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Vui lòng thử đổi từ khóa tìm kiếm hoặc ngày/ca trực khác.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedDateFilter = 'all';
                                      _selectedShiftFilter = 'all';
                                    });
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Đặt lại bộ lọc'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : isWide
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: schedules.length,
                          itemBuilder: (context, index) {
                            return _buildScheduleCard(schedules[index]);
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: schedules.length,
                          itemBuilder: (context, index) {
                            return _buildScheduleCard(schedules[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildScheduleCard(DoctorWorkSchedule s) {
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

    Widget remainingBadge;
    if (isFull) {
      remainingBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Hết chỗ',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (remaining <= 3) {
      remainingBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          'Chỉ còn $remaining chỗ',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      remainingBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Text(
          'Còn $remaining chỗ',
          style: TextStyle(
            color: primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Doctor Info & Slots Badge
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    doctor.fullName.isNotEmpty
                        ? doctor.fullName.split(' ').last[0]
                        : 'B',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BS. ${doctor.fullName}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty ?? 'Răng Hàm Mặt',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                remainingBadge,
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
            ),
            // Middle Section: Date & Time details
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time_outlined, size: 14, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  '$shiftName ($shiftTime)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Button Section
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: isFull ? null : () => _showBookingConfirmSheet(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade100,
                  disabledForegroundColor: Colors.grey.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isFull ? 'Ca trực đã đầy' : 'Đăng Ký Đặt Lịch',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
