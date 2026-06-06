import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/doctor_work_schedule.dart';
import '../models/work_shift.dart';
import '../models/medical_record_model.dart';
import '../services/booking_service.dart';
import '../services/doctor_work_schedule_service.dart';
import '../services/work_shift.dart';
import '../services/medical_record_service.dart';
import 'booking_screen.dart';

class PatientAppointmentListScreen extends StatefulWidget {
  const PatientAppointmentListScreen({super.key});

  @override
  State<PatientAppointmentListScreen> createState() =>
      _PatientAppointmentListScreenState();
}

class _PatientAppointmentListScreenState
    extends State<PatientAppointmentListScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _selectedFilter =
      'all'; // all, pending, confirmed, active, completed, cancelled
  String _errorMessage = '';

  final Color primaryColor = const Color(0xFF0D9488); // Deep Teal
  final Color accentColor = const Color(0xFF2DD4BF); // Light Teal
  final Color cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await BookingService.getMyBookings();
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Không thể tải danh sách lịch khám. Vui lòng thử lại sau.';
        _isLoading = false;
      });
    }
  }

  List<Booking> get _filteredAppointments {
    if (_selectedFilter == 'all') return _bookings;
    return _bookings.where((appt) {
      final status = appt.status.toLowerCase();
      if (_selectedFilter == 'pending') return status == 'pending';
      if (_selectedFilter == 'confirmed') return status == 'confirmed';
      if (_selectedFilter == 'active')
        return status == 'checked_in' || status == 'in_progress';
      if (_selectedFilter == 'completed') return status == 'completed';
      if (_selectedFilter == 'cancelled')
        return status == 'cancelled' || status == 'no_show';
      return true;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade800;
      case 'confirmed':
        return const Color(0xFF0D9488);
      case 'checked_in':
      case 'in_progress':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
      case 'no_show':
        return Colors.grey.shade600;
      default:
        return Colors.black54;
    }
  }

  String _getStatusName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checked_in':
        return 'Đã Check-in';
      case 'in_progress':
        return 'Đang khám';
      case 'completed':
        return 'Đã hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'no_show':
        return 'Vắng mặt';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Lịch khám của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: primaryColor.withOpacity(0.3), height: 1.0),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: _fetchAppointments,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
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
                            onPressed: _fetchAppointments,
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
                : _filteredAppointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy lịch khám nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchAppointments,
                    color: primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _filteredAppointments.length,
                      itemBuilder: (context, index) {
                        final appt = _filteredAppointments[index];
                        return _buildAppointmentCard(appt);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'id': 'all', 'label': 'Tất cả'},
      {'id': 'pending', 'label': 'Chờ duyệt'},
      {'id': 'confirmed', 'label': 'Đã duyệt'},
      {'id': 'active', 'label': 'Đang khám'},
      {'id': 'completed', 'label': 'Đã hoàn thành'},
      {'id': 'cancelled', 'label': 'Đã hủy'},
    ];

    return Container(
      height: 55,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  _selectedFilter = f['id']!;
                });
              },
              selectedColor: primaryColor,
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Booking appt) {
    String formattedDate = appt.bookingDate;
    try {
      final parsedDate = DateTime.parse(appt.bookingDate);
      formattedDate = DateFormat(
        'EEEE, dd/MM/yyyy',
        'vi_VN',
      ).format(parsedDate);
    } catch (_) {}

    final formattedTime = appt.timeSlot;
    final doctorName = appt.doctor?.fullName ?? 'Chưa chỉ định';
    final serviceName = 'Khám & Tư vấn răng hàm mặt';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PatientAppointmentDetailScreen(appointmentId: appt.id),
              ),
            );
            if (result == true) {
              _fetchAppointments();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appt.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusName(appt.status),
                        style: TextStyle(
                          color: _getStatusColor(appt.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      'Mã: LH-${appt.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$formattedTime - $formattedDate',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bác sĩ: $doctorName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dịch vụ: $serviceName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                if (appt.symptoms != null && appt.symptoms!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Lý do/Triệu chứng: ${appt.symptoms}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PatientAppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  const PatientAppointmentDetailScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<PatientAppointmentDetailScreen> createState() =>
      _PatientAppointmentDetailScreenState();
}

class _PatientAppointmentDetailScreenState
    extends State<PatientAppointmentDetailScreen> {
  Booking? _booking;
  MedicalRecord? _medicalRecord;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String _errorMessage = '';

  final Color primaryColor = const Color(0xFF0D9488); // Deep Teal
  final Color accentColor = const Color(0xFF2DD4BF); // Light Teal

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final b = await BookingService.getBookingById(widget.appointmentId);
      MedicalRecord? record;
      if (b.status.toLowerCase() == 'completed') {
        try {
          record = await MedicalRecordService.getMedicalRecordByAppointment(
            b.id,
          );
        } catch (_) {}
      }
      setState(() {
        _booking = b;
        _medicalRecord = record;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải chi tiết lịch khám.';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lịch hẹn'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch khám này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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

    setState(() => _isActionLoading = true);
    try {
      await BookingService.cancelBooking(widget.appointmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy lịch hẹn thành công'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _rescheduleAppointment() async {
    if (_booking == null) return;

    setState(() => _isActionLoading = true);
    List<DoctorWorkSchedule> schedules = [];
    try {
      final list = await DoctorWorkScheduleService().getByDoctor(
        _booking!.doctorId,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      schedules = list.where((s) {
        final date = DateTime(
          s.workDate.year,
          s.workDate.month,
          s.workDate.day,
        );
        return (date.isAtSameMomentAs(today) || date.isAfter(today)) &&
            s.status.toLowerCase() == 'available' &&
            s.currentPatients < s.maxPatients;
      }).toList();
      schedules.sort((a, b) => a.workDate.compareTo(b.workDate));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải lịch làm việc của bác sĩ: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isActionLoading = false);
      return;
    }
    setState(() => _isActionLoading = false);

    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bác sĩ này hiện chưa có lịch trực rảnh nào để đổi.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    List<WorkShift> shifts = [];
    try {
      shifts = await WorkShiftApi.getAllShifts();
    } catch (_) {}
    final shiftsMap = {for (var s in shifts) s.id: s};

    DoctorWorkSchedule? chosenSchedule;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chọn lịch khám mới'),
          content: DropdownButtonFormField<DoctorWorkSchedule>(
            value: chosenSchedule,
            hint: const Text('Chọn ca trực khám'),
            items: schedules.map((s) {
              final shift = shiftsMap[s.workShiftId];
              final shiftName = shift?.shiftName ?? 'Ca ${s.workShiftId}';
              final shiftTime = shift != null
                  ? ' (${shift.startTime.substring(0, 5)} - ${shift.endTime.substring(0, 5)})'
                  : '';
              final dateStr = DateFormat('dd/MM/yyyy').format(s.workDate);
              return DropdownMenuItem(
                value: s,
                child: Text('$dateStr - $shiftName$shiftTime'),
              );
            }).toList(),
            onChanged: (val) {
              setDialogState(() {
                chosenSchedule = val;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text(
                'Xác nhận đổi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || chosenSchedule == null) return;

    setState(() => _isActionLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(chosenSchedule!.workDate);
      final shift = shiftsMap[chosenSchedule!.workShiftId];
      final slotStr = shift != null
          ? '${shift.shiftName} (${shift.startTime.substring(0, 5)} - ${shift.endTime.substring(0, 5)})'
          : 'Ca ${chosenSchedule!.workShiftId}';

      await BookingService.updateBooking(
        widget.appointmentId,
        bookingDate: dateStr,
        timeSlot: slotStr,
        status: 'pending',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi lịch đặt khám thành công! Vui lòng chờ duyệt.'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đổi lịch thất bại: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  void _rebookAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookingScreen()),
    ).then((_) => Navigator.pop(context, true));
  }

  String _getStatusName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checked_in':
        return 'Đã check-in';
      case 'in_progress':
        return 'Đang khám';
      case 'completed':
        return 'Đã hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'no_show':
        return 'Vắng mặt';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _booking != null
              ? 'Chi tiết lịch khám LH-${_booking!.id}'
              : 'Chi tiết lịch khám',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchDetail,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 90,
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 650 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 20),
                          if (_booking!.status.toLowerCase() == 'completed' &&
                              _medicalRecord != null) ...[
                            _buildMedicalRecordCard(),
                            const SizedBox(height: 20),
                          ],
                          _buildTimelineSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomActionButtons(),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    final appt = _booking!;
    String formattedDate = appt.bookingDate;
    try {
      final parsedDate = DateTime.parse(appt.bookingDate);
      formattedDate = DateFormat(
        'EEEE, dd/MM/yyyy',
        'vi_VN',
      ).format(parsedDate);
    } catch (_) {}

    final formattedTime = appt.timeSlot;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thông tin cuộc hẹn',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LH-${appt.id}',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: primaryColor),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bác sĩ phụ trách',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appt.doctor?.fullName ?? 'Chưa chỉ định',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dịch vụ đăng ký',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Khám & Tư vấn răng hàm mặt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.access_time_filled, color: primaryColor),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thời gian khám',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$formattedTime, ngày $formattedDate',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (appt.symptoms != null && appt.symptoms!.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Lý do/Triệu chứng:',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                appt.symptoms!,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRecordCard() {
    final record = _medicalRecord!;
    final followUp = record.followUpDate != null
        ? DateFormat('dd/MM/yyyy').format(record.followUpDate!)
        : 'Không có';

    return Card(
      elevation: 0,
      color: const Color(0xFFEFF6F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Kết quả khám & Đơn thuốc',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Chẩn đoán bệnh:',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              record.diagnosis,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),

            const SizedBox(height: 12),
            const Text(
              'Phương pháp điều trị:',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              record.treatment,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),

            if (record.prescription != null &&
                record.prescription!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Đơn thuốc chỉ định:',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.prescription!,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Text(
              'Hẹn ngày tái khám:',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event_repeat, size: 18, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  followUp,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    final status = _booking!.status.toLowerCase();

    if (status == 'cancelled' || status == 'no_show') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.redAccent, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuộc hẹn này đã bị hủy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Timeline steps
    final steps = [
      {
        'key': 'pending',
        'title': 'Đã đặt lịch (Chờ duyệt)',
        'desc':
            'Cuộc hẹn đã được ghi nhận và đang chờ nhân viên phòng khám duyệt.',
      },
      {
        'key': 'confirmed',
        'title': 'Đã xác nhận lịch',
        'desc': 'Nhân viên đã xác nhận ca trực của bác sĩ và giờ hẹn cho bạn.',
      },
      {
        'key': 'checked_in',
        'title': 'Đã Check-in',
        'desc': 'Bạn đã có mặt tại phòng khám và sẵn sàng vào điều trị.',
      },
      {
        'key': 'in_progress',
        'title': 'Đang tiến hành điều trị',
        'desc': 'Bác sĩ đang thực hiện chẩn đoán và điều trị răng miệng.',
      },
      {
        'key': 'completed',
        'title': 'Hoàn thành ca khám',
        'desc':
            'Khám chữa bệnh hoàn tất. Bạn có thể xem kết quả bệnh án và đơn thuốc.',
      },
    ];

    int currentIdx = 0;
    if (status == 'confirmed') currentIdx = 1;
    if (status == 'checked_in') currentIdx = 2;
    if (status == 'in_progress') currentIdx = 3;
    if (status == 'completed') currentIdx = 4;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến trình cuộc hẹn',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final stepKey = step['key']!;
            final title = step['title']!;
            final desc = step['desc']!;

            final isCompleted = index < currentIdx;
            final isActive = index == currentIdx;
            final isFuture = index > currentIdx;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? primaryColor
                            : isActive
                            ? accentColor
                            : Colors.white,
                        border: Border.all(
                          color: isCompleted || isActive
                              ? primaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : isActive
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryColor,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 50,
                        color: isCompleted
                            ? primaryColor
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isFuture ? Colors.grey : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 12,
                            color: isFuture
                                ? Colors.grey.shade400
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    if (_booking == null) return const SizedBox.shrink();
    final status = _booking!.status.toLowerCase();

    bool showCancel = status == 'pending' || status == 'confirmed';
    bool showReschedule = status == 'pending' || status == 'confirmed';
    bool showRebook =
        status == 'completed' || status == 'cancelled' || status == 'no_show';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _isActionLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  if (showCancel) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelAppointment,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Hủy cuộc hẹn',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (showReschedule) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _rescheduleAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Đổi lịch hẹn',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  if (showRebook) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _rebookAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Đặt lại lịch khám mới',
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
