import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/work_shift.dart';
import '../services/work_shift.dart';
import '../models/doctor_model.dart';
import '../models/doctor_work_schedule.dart';
import '../services/doctor_service.dart';
import '../services/doctor_work_schedule_service.dart';

class Doctorschedulemanagement extends StatefulWidget {
  const Doctorschedulemanagement({super.key});

  @override
  State<Doctorschedulemanagement> createState() =>
      _DoctorschedulemanagementState();
}

class _DoctorschedulemanagementState extends State<Doctorschedulemanagement> {
  final DoctorWorkScheduleService _scheduleService =
      DoctorWorkScheduleService();
  final DoctorService _doctorService = DoctorService();
  List<DoctorWorkSchedule> _schedules = [];
  List<Doctor> _doctors = [];
  List<WorkShift> _workShifts = [];
  bool _isLoading = false;
  DateTime? _selectedDate;

  // --- BIẾN PHỤ TRỢ CHO TÍNH NĂNG TÌM KIẾM ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // --- BẢNG MÀU PHÒNG KHÁM NHA KHOA HIỆN ĐẠI (MINT & TEAL) ---
  final Color primaryMint = const Color(0xFF0D9488);
  final Color lightMint = const Color(0xFFCCFBF1);
  final Color darkTeal = const Color(0xFF115E59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _loadDoctors();
    _loadWorkShifts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkShifts() async {
    try {
      final data = await WorkShiftApi.getAllShifts();
      setState(() {
        _workShifts = data;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final data = await _doctorService.getDoctors();
      setState(() {
        _doctors = data;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _scheduleService.getAll();
      if (!mounted) return;
      setState(() {
        if (_selectedDate == null) {
          _schedules = data;
        } else {
          _schedules = data.where((s) {
            return s.workDate.year == _selectedDate!.year &&
                s.workDate.month == _selectedDate!.month &&
                s.workDate.day == _selectedDate!.day;
          }).toList();
        }
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải dữ liệu lịch làm việc'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DoctorWorkSchedule> get _filteredSchedules {
    if (_searchQuery.isEmpty) return _schedules;
    return _schedules.where((item) {
      final doctorName = (item.doctorName ?? "").toLowerCase();
      final shiftId = item.workShiftId.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return doctorName.contains(query) || shiftId.contains(query);
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryMint,
              onPrimary: Colors.white,
              onSurface: darkTeal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSchedules();
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: darkTeal.withValues(alpha: 0.7),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: primaryMint, size: 20),
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryMint, width: 1.5),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    // THỐNG NHẤT KIỂU STRING? THEO MODEL ĐÃ CẬP NHẬT
    String? selectedDoctorId;
    String? selectedShiftId;
    final maxPatientsController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.add_task, color: primaryMint),
                  const SizedBox(width: 8),
                  Text(
                    'Thêm ca làm việc',
                    style: TextStyle(
                      color: darkTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String?>(
                        initialValue: selectedDoctorId,
                        decoration: _buildInputDecoration(
                          'Chọn bác sĩ nha khoa (tùy chọn)',
                          Icons.person_outline,
                        ),
                        dropdownColor: cardColor,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Chưa phân công bác sĩ',
                              style: TextStyle(
                                color: darkTeal,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          ..._doctors.map((doctor) {
                            return DropdownMenuItem<String?>(
                              value: doctor.id.toString(),
                              child: Text(
                                '${doctor.doctorCode} - ${doctor.fullName}',
                                style: TextStyle(color: darkTeal),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => selectedDoctorId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedShiftId,
                        decoration: _buildInputDecoration(
                          'Chọn ca làm việc',
                          Icons.schedule,
                        ),
                        dropdownColor: cardColor,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Chọn ca làm việc...',
                              style: TextStyle(
                                color: darkTeal.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          ..._workShifts.map((shift) {
                            return DropdownMenuItem<String?>(
                              value: shift.id.toString(),
                              child: Text(
                                '${shift.shiftName} (${shift.startTime} - ${shift.endTime})',
                                style: TextStyle(color: darkTeal),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedShiftId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: maxPatientsController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          'Số bệnh nhân tối đa',
                          Icons.people_outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: primaryMint,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(selectedDate),
                                    style: TextStyle(
                                      color: darkTeal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_drop_down, color: primaryMint),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: TextStyleWidget(
                    text: 'Huỷ',
                    color: Colors.grey.shade600,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (selectedShiftId == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng chọn ca làm việc'),
                          ),
                        );
                        return;
                      }

                      if (maxPatientsController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập số bệnh nhân tối đa'),
                          ),
                        );
                        return;
                      }

                      String? doctorName;
                      String? doctorCode;

                      if (selectedDoctorId != null) {
                        final doctor = _doctors.firstWhere(
                          (d) => d.id.toString() == selectedDoctorId,
                        );
                        doctorName = doctor.fullName;
                        doctorCode = doctor.doctorCode;
                      }

                      await _scheduleService.create(
                        DoctorWorkSchedule(
                          id: '', // Trống hoặc Backend tự sinh
                          doctorId: selectedDoctorId,
                          workShiftId: selectedShiftId!,
                          workDate: selectedDate,
                          maxPatients: int.parse(maxPatientsController.text),
                          currentPatients: 0,
                          status: "available",
                          note: null,
                          doctorName: doctorName,
                          doctorCode: doctorCode,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await _fetchSchedules();

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thêm ca làm việc thành công'),
                        ),
                      );
                    } catch (e) {
                      debugPrint("CREATE ERROR: $e");
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryMint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Lưu lịch',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(DoctorWorkSchedule item) async {
    // THỐNG NHẤT LẤY GIÁ TRỊ STRING? TỪ MODEL
    String? selectedDoctorId = item.doctorId;
    String? selectedShiftId = item.workShiftId;

    final maxPatientsController = TextEditingController(
      text: item.maxPatients.toString(),
    );

    DateTime selectedDate = item.workDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit_calendar, color: primaryMint),
                  const SizedBox(width: 8),
                  Text(
                    'Cập nhật ca làm',
                    style: TextStyle(
                      color: darkTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String?>(
                        initialValue: selectedDoctorId,
                        decoration: _buildInputDecoration(
                          'Chọn bác sĩ nha khoa (tùy chọn)',
                          Icons.person_outline,
                        ),
                        dropdownColor: cardColor,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Chưa phân công bác sĩ',
                              style: TextStyle(
                                color: darkTeal,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          ..._doctors.map((doctor) {
                            return DropdownMenuItem<String?>(
                              value: doctor.id.toString(),
                              child: Text(
                                '${doctor.doctorCode} - ${doctor.fullName}',
                                style: TextStyle(color: darkTeal),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDoctorId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedShiftId,
                        decoration: _buildInputDecoration(
                          'Chọn ca làm việc',
                          Icons.schedule,
                        ),
                        dropdownColor: cardColor,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Chọn ca làm việc...',
                              style: TextStyle(
                                color: darkTeal.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          ..._workShifts.map((shift) {
                            return DropdownMenuItem<String?>(
                              value: shift.id.toString(),
                              child: Text(
                                '${shift.shiftName} (${shift.startTime} - ${shift.endTime})',
                                style: TextStyle(color: darkTeal),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedShiftId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: maxPatientsController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          'Max Patients',
                          Icons.people_outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: primaryMint,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(selectedDate),
                                    style: TextStyle(
                                      color: darkTeal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_drop_down, color: primaryMint),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: TextStyleWidget(
                    text: 'Huỷ',
                    color: Colors.grey.shade600,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (selectedShiftId == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng chọn ca làm việc'),
                          ),
                        );
                        return;
                      }

                      await _scheduleService.update(item.id, {
                        "doctor_id": selectedDoctorId,
                        "work_shift_id": selectedShiftId,
                        "work_date": selectedDate.toIso8601String().split(
                          'T',
                        )[0],
                        "max_patients": int.parse(maxPatientsController.text),
                      });

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await _fetchSchedules();

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật thành công')),
                      );
                    } catch (e) {
                      debugPrint(e.toString());
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryMint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cập nhật',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSchedule(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Xoá lịch làm việc?'),
          content: const Text(
            'Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xoá ca làm này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: TextStyleWidget(text: 'Huỷ', color: Colors.grey),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Xoá ngay',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _scheduleService.delete(id);
        await _fetchSchedules();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xoá lịch làm việc')));
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchSchedules,
        color: primaryMint,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản lý Lịch Trình Nha Khoa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkTeal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Theo dõi, điều phối ca khám và điều trị của các bác sĩ',
                style: TextStyle(
                  fontSize: 14,
                  color: darkTeal.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),
              _buildTopStatsBar(),
              const SizedBox(height: 28),
              _buildFilterHeader(context),
              const SizedBox(height: 28),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryMint))
                  : _buildScheduleGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatsBar() {
    int totalShifts = _schedules.length;
    int totalPatients = _schedules.fold(
      0,
      (sum, item) => sum + item.currentPatients,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - (24 * 2)) / 3;

        return Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _buildStatCard(
              'Tổng Ca Làm Việc',
              totalShifts.toString(),
              Icons.calendar_view_week,
              const Color(0xE6E0F2FE),
              const Color(0xFF0284C7),
              cardWidth,
            ),
            _buildStatCard(
              'Ghế Hẹn Điều Trị',
              totalPatients.toString(),
              Icons.airline_seat_flat_angled,
              lightMint,
              primaryMint,
              cardWidth,
            ),
            _buildStatCard(
              'Bác Sĩ Trực Ca',
              _doctors.length.toString(),
              Icons.badge_outlined,
              const Color(0xE6F3F4F6),
              darkTeal,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
    double width,
  ) {
    return Container(
      width: width < 240 ? double.infinity : width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: darkTeal.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkTeal,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _selectDate(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: lightMint,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            icon: Icon(Icons.calendar_month, color: darkTeal, size: 18),
            label: Text(
              _selectedDate == null
                  ? 'Chọn ngày'
                  : DateFormat('dd/MM/yyyy').format(_selectedDate!),
              style: TextStyle(color: darkTeal, fontWeight: FontWeight.w600),
            ),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() => _selectedDate = null);
                _fetchSchedules();
              },
              child: Text(
                'Đặt lại',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(color: darkTeal, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên bác sĩ hoặc ca khám...',
                  hintStyle: TextStyle(
                    color: darkTeal.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search, color: primaryMint, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: darkTeal.withValues(alpha: 0.5),
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryMint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: const Text(
              'Thêm ca khám',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleGrid() {
    final displaySchedules = _filteredSchedules;

    if (displaySchedules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 48,
              color: darkTeal.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy lịch làm việc phù hợp',
              style: TextStyle(
                color: darkTeal.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : (constraints.maxWidth > 800 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displaySchedules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) =>
              _buildShiftCard(displaySchedules[index]),
        );
      },
    );
  }

  Widget _buildShiftCard(DoctorWorkSchedule item) {
    final progress = item.maxPatients > 0
        ? item.currentPatients / item.maxPatients
        : 0.0;

    Color progressColor = primaryMint;
    if (progress >= 0.9) {
      progressColor = Colors.redAccent;
    } else if (progress >= 0.6) {
      progressColor = Colors.orangeAccent;
    }

    // ĐỒNG BỘ SO SÁNH GIỮA HAI KIỂU STRING
    // Chuyển đổi an toàn để tìm Ca làm việc (WorkShift) phù hợp
    final currentShift = _workShifts.firstWhere(
      (s) => s.id.toString() == item.workShiftId.toString(),
      orElse: () => WorkShift(
        id: '', // <--- Sửa từ số 0 thành chuỗi trống '' để đúng kiểu String của Model WorkShift
        shiftCode: '',
        shiftName: 'Không rõ',
        startTime: '',
        endTime: '',
        maxPatients: 0,
        status: false,
      ),
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightMint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentShift.shiftName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: darkTeal,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showEditDialog(item),
                    icon: Icon(
                      Icons.mode_edit_outline,
                      color: darkTeal.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    hoverColor: lightMint,
                  ),
                  IconButton(
                    onPressed: () => _deleteSchedule(item.id),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    hoverColor: Color(0xFFFEF2F2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 16,
                color: darkTeal.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd/MM/yyyy').format(item.workDate),
                style: TextStyle(
                  color: darkTeal.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.doctorName ?? 'Chưa phân công bác sĩ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: item.doctorName != null
                  ? darkTeal
                  : Colors.orange.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.doctorCode ?? '--',
            style: TextStyle(
              color: darkTeal.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ghế hẹn đã đặt:',
                style: TextStyle(
                  fontSize: 13,
                  color: darkTeal.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${item.currentPatients}/${item.maxPatients}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: darkTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

class TextStyleWidget extends StatelessWidget {
  final String text;
  final Color color;
  const TextStyleWidget({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
