import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/work_shift.dart';
import '../services/work_shift.dart';
import '../models/doctor_work_schedule.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import '../services/doctor_work_schedule_service.dart';

class DoctorScheduleRegisterScreen extends StatefulWidget {
  const DoctorScheduleRegisterScreen({Key? key}) : super(key: key);

  @override
  State<DoctorScheduleRegisterScreen> createState() =>
      _DoctorScheduleRegisterScreenState();
}

class _DoctorScheduleRegisterScreenState
    extends State<DoctorScheduleRegisterScreen> {
  final _scheduleService = DoctorWorkScheduleService();
  final _doctorService = DoctorService();

  List<DoctorWorkSchedule> _schedules = [];
  List<WorkShift> _workShifts = [];
  Doctor? _currentDoctor;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // --- BẢNG MÀU PHÒNG KHÁM NHA KHOA MINT & TEAL ---
  final Color primaryMint = const Color(0xFF0D9488);
  final Color lightMint = const Color(0xFFCCFBF1);
  final Color darkTeal = const Color(0xFF115E59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Tải hồ sơ bác sĩ đang đăng nhập
      final doc = await _doctorService.getMyProfile();
      _currentDoctor = doc;

      // 2. Tải danh sách ca làm việc
      final shifts = await WorkShiftApi.getAllShifts();
      _workShifts = shifts.where((s) => s.status).toList();

      // 3. Tải lịch trực
      await _fetchSchedules();
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu ban đầu: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải thông tin bác sĩ hoặc ca làm việc'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSchedules() async {
    try {
      final allSchedules = await _scheduleService.getAll();

      // Lọc lịch theo ngày đã chọn
      setState(() {
        _schedules = allSchedules.where((s) {
          return s.workDate.year == _selectedDate.year &&
              s.workDate.month == _selectedDate.month &&
              s.workDate.day == _selectedDate.day;
        }).toList();
      });
    } catch (e) {
      debugPrint("Lỗi tải danh sách lịch trực: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật danh sách lịch trực'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Chọn ngày lọc lịch
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      await _fetchSchedules();
      setState(() => _isLoading = false);
    }
  }

  // Nghiệp vụ đăng ký lịch trực có sẵn
  Future<void> _registerSchedule(DoctorWorkSchedule schedule) async {
    if (_currentDoctor == null) return;

    // Hiển thị loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _scheduleService.register(schedule.id, _currentDoctor!.id);

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký trực ca thành công! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _isLoading = true);
      await _fetchSchedules();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký thất bại: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Nghiệp vụ hủy đăng ký lịch trực
  Future<void> _unregisterSchedule(DoctorWorkSchedule schedule) async {
    if (schedule.currentPatients > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hủy ca trực đã có bệnh nhân đặt hẹn trước!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận hủy lịch trực'),
        content: Text(
          'Bạn có chắc chắn muốn hủy đăng ký ca trực ngày ${DateFormat('dd/MM/yyyy').format(schedule.workDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              'Xác nhận hủy',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _scheduleService.unregister(schedule.id);

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy đăng ký ca trực thành công!'),
          backgroundColor: Colors.blueGrey,
        ),
      );

      setState(() => _isLoading = true);
      await _fetchSchedules();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hủy đăng ký thất bại: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Dialog đăng ký/tạo ca trực hoàn toàn mới
  Future<void> _showAddScheduleDialog() async {
    if (_currentDoctor == null) return;

    String? selectedShiftId;
    final maxPatientsCtrl = TextEditingController(text: '10');
    DateTime selectedDate = _selectedDate;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogStateCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.add_chart, color: primaryMint),
                  const SizedBox(width: 8),
                  Text(
                    'Đăng ký ca trực mới',
                    style: TextStyle(
                      color: darkTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bạn có thể tự tạo và đăng ký ca trực cho bản thân tại đây.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // Chọn Ca khám
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Chọn ca làm việc',
                          prefixIcon: Icon(Icons.schedule, color: primaryMint),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _workShifts.map((shift) {
                          return DropdownMenuItem<String>(
                            value: shift.id.toString(),
                            child: Text(
                              '${shift.shiftName} (${shift.startTime} - ${shift.endTime})',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedShiftId = val),
                      ),
                      const SizedBox(height: 16),

                      // Chọn Ngày khám
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogStateCtx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 90),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
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
                                  const SizedBox(width: 10),
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
                      const SizedBox(height: 16),

                      // Số lượng bệnh nhân tối đa
                      TextField(
                        controller: maxPatientsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Số bệnh nhân tối đa nhận khám',
                          prefixIcon: Icon(
                            Icons.people_outline,
                            color: primaryMint,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Huỷ',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedShiftId == null) {
                      ScaffoldMessenger.of(dialogStateCtx).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn ca làm việc'),
                        ),
                      );
                      return;
                    }

                    try {
                      final newSchedule = DoctorWorkSchedule(
                        id: '',
                        doctorId: _currentDoctor!.id,
                        workShiftId: selectedShiftId!,
                        workDate: selectedDate,
                        maxPatients: int.tryParse(maxPatientsCtrl.text) ?? 10,
                        currentPatients: 0,
                        status: "available",
                        note: "Bác sĩ tự đăng ký ca trực",
                        doctorName: _currentDoctor!.fullName,
                        doctorCode: _currentDoctor!.doctorCode,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      await _scheduleService.create(newSchedule);

                      if (!dialogStateCtx.mounted) return;
                      Navigator.pop(dialogCtx); // Đóng dialog

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đăng ký ca trực mới thành công! 🌟'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        setState(() {
                          _selectedDate = selectedDate;
                          _isLoading = true;
                        });
                        await _fetchSchedules();
                      }
                    } catch (e) {
                      debugPrint("Lỗi lưu ca trực: $e");
                      if (dialogStateCtx.mounted) {
                        ScaffoldMessenger.of(dialogStateCtx).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đăng ký thất bại: Lịch làm việc này có thể đã bị trùng lắp.',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryMint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Đăng ký',
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

  // Lấy chi tiết thông tin ca khám dựa trên ID
  WorkShift? _getShiftDetail(String shiftId) {
    try {
      return _workShifts.firstWhere((s) => s.id.toString() == shiftId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'EEEE, dd/MM/yyyy',
      'vi_VN',
    ).format(_selectedDate);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Đăng Ký Lịch Trực Ca',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryMint))
          : Column(
              children: [
                // Thanh bộ lọc Ngày
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hiển thị ngày đang xem
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: primaryMint,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: darkTeal,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Nút chọn ngày khác
                      ElevatedButton.icon(
                        onPressed: () => _selectDate(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightMint,
                          foregroundColor: darkTeal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.date_range, size: 18),
                        label: const Text(
                          'Chọn ngày',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sách ca trực chính
                Expanded(
                  child: _schedules.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _schedules.length,
                          itemBuilder: (context, index) {
                            final schedule = _schedules[index];
                            final shift = _getShiftDetail(schedule.workShiftId);
                            return _buildScheduleCard(schedule, shift);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScheduleDialog,
        backgroundColor: primaryMint,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Đăng ký ca mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Trạng thái khi không có ca trực nào
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có ca trực nào được xếp lịch ngày này',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy nhấn nút bên dưới để tự tạo ca trực cho chính mình.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddScheduleDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryMint,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_circle, color: Colors.white),
            label: const Text(
              'Đăng ký ca trực mới',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ hiển thị thông tin ca trực
  Widget _buildScheduleCard(DoctorWorkSchedule schedule, WorkShift? shift) {
    final shiftName = shift?.shiftName ?? 'Ca trực #${schedule.workShiftId}';
    final shiftTime = shift != null
        ? '${shift.startTime} - ${shift.endTime}'
        : 'Chưa rõ khung giờ';

    // Kiểm tra mối quan hệ của bác sĩ hiện tại với ca trực này
    final isMySchedule =
        _currentDoctor != null && schedule.doctorId == _currentDoctor!.id;
    final isUnassigned =
        schedule.doctorId == null || schedule.doctorId!.isEmpty;

    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    if (isMySchedule) {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green.shade700;
      statusLabel = 'LỊCH CỦA TÔI';
    } else if (isUnassigned) {
      statusBgColor = Colors.amber.shade50;
      statusTextColor = Colors.amber.shade800;
      statusLabel = 'LỊCH CÒN TRỐNG';
    } else {
      statusBgColor = Colors.grey.shade100;
      statusTextColor = Colors.grey.shade700;
      statusLabel = 'ĐÃ CÓ BÁC SĨ KHÁC';
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMySchedule
              ? primaryMint.withOpacity(0.5)
              : Colors.grey.shade200,
          width: isMySchedule ? 1.5 : 1,
        ),
      ),
      elevation: isMySchedule ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng đầu: Tên ca & Trạng thái tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark_outline, color: primaryMint, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      shiftName,
                      style: TextStyle(
                        color: darkTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Khung giờ & Số bệnh nhân
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        shiftTime,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đã đặt: ${schedule.currentPatients}/${schedule.maxPatients}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tên Bác sĩ phụ trách (nếu có)
            Row(
              children: [
                const Icon(Icons.badge_outlined, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  isUnassigned
                      ? 'Chưa phân công bác sĩ'
                      : 'Bác sĩ trực: ${schedule.doctorName ?? 'N/A'} (${schedule.doctorCode ?? ''})',
                  style: TextStyle(
                    color: isUnassigned
                        ? Colors.amber.shade800
                        : Colors.grey.shade700,
                    fontSize: 14,
                    fontStyle: isUnassigned
                        ? FontStyle.italic
                        : FontStyle.normal,
                    fontWeight: isUnassigned
                        ? FontWeight.normal
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Note của ca làm (nếu có)
            if (schedule.note != null && schedule.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    color: Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ghi chú: ${schedule.note}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Nút Tương Tác
            if (isMySchedule || isUnassigned) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: isMySchedule
                    ? OutlinedButton.icon(
                        onPressed: () => _unregisterSchedule(schedule),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text(
                          'Hủy đăng ký ca trực này',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _registerSchedule(schedule),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryMint,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text(
                          'Đăng ký trực ca này',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
