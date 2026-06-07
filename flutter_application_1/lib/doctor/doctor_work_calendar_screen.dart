import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/doctor_work_calendar_model.dart';
import '../services/doctor_work_calendar_service.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import '../services/api.dart';

class DoctorWorkCalendarScreen extends StatefulWidget {
  final bool isEmbedded;

  const DoctorWorkCalendarScreen({Key? key, this.isEmbedded = false})
    : super(key: key);

  @override
  State<DoctorWorkCalendarScreen> createState() =>
      _DoctorWorkCalendarScreenState();
}

enum ScheduleViewMode { week, month }

class _DoctorWorkCalendarScreenState extends State<DoctorWorkCalendarScreen> {
  List<DoctorCalendarItem> _calendarItems = [];
  Doctor? _doctorProfile;
  bool _isLoading = true;
  String? _errorMessage;

  // View settings
  ScheduleViewMode _viewMode = ScheduleViewMode.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final double _hourHeight = 65.0;
  final int _startHour = 6;
  final int _endHour = 22;

  // Color palette
  final Color primaryTeal = const Color(0xFF0F766E);
  final Color lightTeal = const Color(0xFFE6F7F6);

  // Status colors - Pastel and Rich colors
  final Color normalShiftBg = const Color(0xFFD1FAE5);
  final Color normalShiftText = const Color(0xFF065F46);
  final Color normalShiftBorder = const Color(0xFF10B981);

  final Color todayShiftBg = const Color(0xFFDBEAFE);
  final Color todayShiftText = const Color(0xFF1E40AF);
  final Color todayShiftBorder = const Color(0xFF3B82F6);

  final Color fullShiftBg = const Color(0xFFFEE2E2);
  final Color fullShiftText = const Color(0xFF991B1B);
  final Color fullShiftBorder = const Color(0xFFEF4444);

  final Color leaveBg = const Color(0xFFF1F5F9);
  final Color leaveText = const Color(0xFF475569);
  final Color leaveBorder = const Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await DoctorWorkCalendarService.getDoctorCalendar();
      Doctor? profile;
      try {
        profile = await DoctorService().getMyProfile();
      } catch (e) {
        debugPrint('Không thể tải profile bác sĩ: $e');
      }

      setState(() {
        _calendarItems = items;
        _doctorProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải lịch làm việc: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      final items = await DoctorWorkCalendarService.getDoctorCalendar();
      setState(() {
        _calendarItems = items;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Làm mới dữ liệu thất bại: $e')));
    }
  }

  DateTime get _weekStart {
    int daysToSubtract = _selectedDay.weekday - 1; // 1 = Monday
    return DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  void _jumpToToday() {
    setState(() {
      _selectedDay = DateTime.now();
      _focusedDay = DateTime.now();
    });
  }

  List<DoctorCalendarItem> _getEventsForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return _calendarItems.where((item) => item.date == dateStr).toList();
  }

  double _timeToOffset(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return 0;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final double totalHours = hour + (minute / 60.0);
      final double offsetHours = totalHours - _startHour;
      return (offsetHours * _hourHeight).clamp(0.0, double.infinity);
    } catch (_) {
      return 0.0;
    }
  }

  double _durationToHeight(String startTime, String endTime) {
    final startOffset = _timeToOffset(startTime);
    final endOffset = _timeToOffset(endTime);
    final height = endOffset - startOffset;
    return height > 35.0 ? height : 35.0; // Min height for cards
  }

  Map<String, int> _calculateStats() {
    final monday = _weekStart;
    final sunday = monday.add(const Duration(days: 6));

    int totalShifts = 0;
    int totalPatients = 0;
    int emptySlots = 0;
    int leaveDays = 0;

    for (final item in _calendarItems) {
      try {
        final date = DateTime.parse(item.date);
        if (date.isAfter(monday.subtract(const Duration(days: 1))) &&
            date.isBefore(sunday.add(const Duration(days: 1)))) {
          if (item.status == 'leave') {
            leaveDays++;
          } else {
            totalShifts++;
            totalPatients += item.currentPatients;
            emptySlots += (item.maxPatients - item.currentPatients).clamp(
              0,
              999,
            );
          }
        }
      } catch (_) {}
    }

    return {
      'totalShifts': totalShifts,
      'totalPatients': totalPatients,
      'emptySlots': emptySlots,
      'leaveDays': leaveDays,
    };
  }

  String _getDoctorInitials(String name) {
    if (name.isEmpty) return 'BS';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[parts.length - 2][0] + parts[parts.length - 1][0])
          .toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getDayNameOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }

  String _formatDateStr(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _handleEventClick(DoctorCalendarItem item) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 700) {
      _showAppointmentDetailsDialog(item);
    } else {
      _showAppointmentDetailsBottomSheet(item);
    }
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsContent(DoctorCalendarItem item) {
    final isLeave = item.status == 'leave';
    final isFull = !isLeave && item.currentPatients >= item.maxPatients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLeave) ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: [
              _buildDetailCard(
                Icons.calendar_today,
                'Ngày nghỉ',
                _formatDateStr(item.date),
                Colors.red,
              ),
              _buildDetailCard(
                Icons.category_outlined,
                'Loại nghỉ',
                item.leaveType ?? 'Nghỉ phép',
                Colors.orange,
              ),
              _buildDetailCard(
                Icons.person_outline,
                'Người duyệt',
                'Ban Giám Đốc',
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lý do nghỉ phép:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.reason ?? 'Không có lý do cụ thể',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: [
              _buildDetailCard(
                Icons.calendar_today,
                'Ngày trực',
                _formatDateStr(item.date),
                primaryTeal,
              ),
              _buildDetailCard(
                Icons.access_time,
                'Thời gian',
                '${item.startTime} - ${item.endTime}',
                Colors.blue,
              ),
              _buildDetailCard(
                Icons.meeting_room_outlined,
                'Phòng khám',
                'Phòng Răng Hàm Mặt số 2',
                Colors.orange,
              ),
              _buildDetailCard(
                Icons.people_outline,
                'Bệnh nhân',
                '${item.currentPatients} / ${item.maxPatients} BN',
                isFull ? Colors.red : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Danh sách bệnh nhân đặt hẹn:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 10),
          if (item.patients.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_ind_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có bệnh nhân nào đặt lịch cho ca này.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: item.patients.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final patient = item.patients[index];

                  final genderStr = patient.gender == 'male'
                      ? 'Nam'
                      : (patient.gender == 'female' ? 'Nữ' : 'Khác');
                  final dobStr = patient.dob != null
                      ? _formatDateStr(patient.dob!)
                      : 'Chưa cập nhật';

                  Color statusBg = Colors.grey.shade100;
                  Color statusText = Colors.grey.shade700;
                  String statusLabel = 'Chờ duyệt';

                  if (patient.status == 'approved' ||
                      patient.status == 'confirmed') {
                    statusBg = const Color(0xFFD1FAE5);
                    statusText = const Color(0xFF065F46);
                    statusLabel = 'Đã duyệt';
                  } else if (patient.status == 'completed') {
                    statusBg = const Color(0xFFDBEAFE);
                    statusText = const Color(0xFF1E40AF);
                    statusLabel = 'Hoàn thành';
                  } else if (patient.status == 'pending') {
                    statusBg = const Color(0xFFFEF3C7);
                    statusText = const Color(0xFF92400E);
                    statusLabel = 'Chờ duyệt';
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: lightTeal,
                              child: Text(
                                patient.name.isNotEmpty
                                    ? patient.name[0].toUpperCase()
                                    : 'BN',
                                style: TextStyle(
                                  color: primaryTeal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                patient.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPatientDetailItem(
                                Icons.phone_outlined,
                                'SĐT:',
                                patient.phone,
                              ),
                            ),
                            Expanded(
                              child: _buildPatientDetailItem(
                                Icons.wc_outlined,
                                'Phái:',
                                genderStr,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPatientDetailItem(
                                Icons.cake_outlined,
                                'Sinh:',
                                dobStr,
                              ),
                            ),
                            Expanded(child: const SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade50.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellow.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.healing_outlined,
                                size: 14,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Lý do khám: ${patient.symptoms}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade800,
                                    height: 1.3,
                                  ),
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
      ],
    );
  }

  Widget _buildPatientDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetailsDialog(DoctorCalendarItem item) {
    final isLeave = item.status == 'leave';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isLeave ? Icons.event_busy : Icons.calendar_today_outlined,
                color: isLeave ? Colors.red : primaryTeal,
              ),
              const SizedBox(width: 12),
              Text(
                isLeave ? 'Ngày nghỉ phép' : 'Chi tiết ca trực',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width.clamp(300.0, 550.0),
            child: SingleChildScrollView(
              child: _buildEventDetailsContent(item),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Đóng',
                style: TextStyle(
                  color: primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAppointmentDetailsBottomSheet(DoctorCalendarItem item) {
    final isLeave = item.status == 'leave';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isLeave
                            ? Icons.event_busy
                            : Icons.calendar_today_outlined,
                        color: isLeave ? Colors.red : primaryTeal,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isLeave ? 'Ngày nghỉ phép' : 'Chi tiết ca trực',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildEventDetailsContent(item),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventCard(DoctorCalendarItem item, {bool isCompact = false}) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = item.date == todayStr;
    final isLeave = item.status == 'leave';
    final isFull = !isLeave && item.currentPatients >= item.maxPatients;

    Color bg;
    Color text;
    Color border;

    if (isLeave) {
      bg = leaveBg;
      text = leaveText;
      border = leaveBorder;
    } else if (isFull) {
      bg = fullShiftBg;
      text = fullShiftText;
      border = fullShiftBorder;
    } else if (isToday) {
      bg = todayShiftBg;
      text = todayShiftText;
      border = todayShiftBorder;
    } else {
      bg = normalShiftBg;
      text = normalShiftText;
      border = normalShiftBorder;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      elevation: 1.0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => _handleEventClick(item),
        borderRadius: BorderRadius.circular(12),
        hoverColor: text.withOpacity(0.08),
        splashColor: text.withOpacity(0.15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border.withOpacity(0.5), width: 1.5),
          ),
          padding: EdgeInsets.all(isCompact ? 6.0 : 10.0),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLeave
                            ? Icons.event_busy
                            : Icons.calendar_today_outlined,
                        size: isCompact ? 10 : 12,
                        color: text,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.shiftName.toUpperCase(),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 9 : 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.startTime} - ${item.endTime}',
                    style: TextStyle(
                      color: text.withOpacity(0.8),
                      fontSize: isCompact ? 8 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (!isLeave)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          size: isCompact ? 10 : 12,
                          color: text,
                        ),
                        Text(
                          '${item.currentPatients}/${item.maxPatients}',
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 9 : 11,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'NGHỈ PHÉP',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 8 : 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HEADER TOOLBAR ---

  Widget _buildHeaderToolbar() {
    String currentRangeLabel = '';
    if (_viewMode == ScheduleViewMode.week) {
      final start = _weekStart;
      final end = start.add(const Duration(days: 6));
      if (start.month == end.month) {
        currentRangeLabel = 'Tháng ${start.month}, ${start.year}';
      } else {
        currentRangeLabel =
            'Tháng ${start.month} - ${end.month}, ${start.year}';
      }
    } else {
      currentRangeLabel = 'Tháng ${_focusedDay.month}, ${_focusedDay.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Nav buttons
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                if (_viewMode == ScheduleViewMode.week) {
                  _selectedDay = _selectedDay.subtract(const Duration(days: 7));
                  _focusedDay = _selectedDay;
                } else {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                    1,
                  );
                  _selectedDay = _focusedDay;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (_viewMode == ScheduleViewMode.week) {
                  _selectedDay = _selectedDay.add(const Duration(days: 7));
                  _focusedDay = _selectedDay;
                } else {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                    1,
                  );
                  _selectedDay = _focusedDay;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _jumpToToday,
            child: const Text('Hôm nay'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryTeal,
              side: BorderSide(color: primaryTeal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            currentRangeLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // View Mode Selector (Tuần / Tháng)
          SegmentedButton<ScheduleViewMode>(
            segments: const <ButtonSegment<ScheduleViewMode>>[
              ButtonSegment<ScheduleViewMode>(
                value: ScheduleViewMode.week,
                label: Text('Tuần'),
                icon: Icon(Icons.view_week),
              ),
              ButtonSegment<ScheduleViewMode>(
                value: ScheduleViewMode.month,
                label: Text('Tháng'),
                icon: Icon(Icons.calendar_view_month),
              ),
            ],
            selected: <ScheduleViewMode>{_viewMode},
            onSelectionChanged: (Set<ScheduleViewMode> newSelection) {
              setState(() {
                _viewMode = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: primaryTeal,
              selectedForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Làm mới',
          ),
          const SizedBox(width: 16),
          // Doctor Info
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _doctorProfile?.fullName ?? 'Bác sĩ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _doctorProfile?.specialty ?? 'Nha khoa',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: lightTeal,
                backgroundImage: _doctorProfile?.avatar != null
                    ? NetworkImage(
                        '${Api.baseUrl.replaceAll('/api/v1', '')}${_doctorProfile!.avatar}',
                      )
                    : null,
                child: _doctorProfile?.avatar == null
                    ? Text(
                        _getDoctorInitials(_doctorProfile?.fullName ?? 'BS'),
                        style: TextStyle(
                          color: primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WEEKLY TIMELINE GRID ---

  Widget _buildWeeklyTimelineGrid() {
    final monday = _weekStart;
    final List<DateTime> weekDays = List.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const double timeWidth = 55.0;
        final double dayColumnWidth = (constraints.maxWidth - timeWidth) / 7;

        return Column(
          children: [
            // Day Headers Row (pinned at top)
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  const SizedBox(width: timeWidth),
                  ...List.generate(7, (index) {
                    final day = weekDays[index];
                    final isSelected = isSameDay(_selectedDay, day);
                    final isToday = isSameDay(DateTime.now(), day);
                    final dayName = _getDayNameOfWeek(day.weekday);

                    return SizedBox(
                      width: dayColumnWidth,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDay = day;
                            _focusedDay = day;
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday
                                    ? primaryTeal
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryTeal
                                    : (isToday
                                          ? lightTeal
                                          : Colors.transparent),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                DateFormat('d').format(day),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isToday
                                            ? primaryTeal
                                            : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            // Scrollable Grid Area (Time Labels and Day Columns scroll together)
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: (_endHour - _startHour + 1) * _hourHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Labels
                      SizedBox(
                        width: timeWidth,
                        child: Column(
                          children: List.generate(_endHour - _startHour + 1, (
                            index,
                          ) {
                            final hour = _startHour + index;
                            final hourStr =
                                '${hour.toString().padLeft(2, '0')}:00';
                            return SizedBox(
                              height: _hourHeight,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 8.0,
                                    top: 4.0,
                                  ),
                                  child: Text(
                                    hourStr,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      // Columns stack
                      Expanded(
                        child: Stack(
                          children: [
                            // Horizontal lines
                            Column(
                              children: List.generate(
                                _endHour - _startHour + 1,
                                (index) {
                                  return Container(
                                    height: _hourHeight,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Vertical Divider Lines
                            Row(
                              children: List.generate(7, (index) {
                                return Container(
                                  width: dayColumnWidth,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey.shade100,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            // Current time indicator line
                            ..._buildCurrentTimeIndicator(
                              weekDays,
                              dayColumnWidth,
                            ),
                            // Absolute Event Cards
                            ..._buildWeeklyTimelineEvents(
                              weekDays,
                              dayColumnWidth,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildWeeklyTimelineEvents(
    List<DateTime> weekDays,
    double columnWidth,
  ) {
    final List<Widget> widgets = [];

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final day = weekDays[dayIndex];
      final dayStr = DateFormat('yyyy-MM-dd').format(day);
      final events = _calendarItems
          .where((item) => item.date == dayStr)
          .toList();

      for (final event in events) {
        final double top = _timeToOffset(event.startTime);
        final double height = _durationToHeight(event.startTime, event.endTime);
        final double left = dayIndex * columnWidth;

        widgets.add(
          Positioned(
            left: left + 2,
            top: top + 2,
            width: columnWidth - 4,
            height: height - 4,
            child: _buildEventCard(event, isCompact: true),
          ),
        );
      }
    }

    return widgets;
  }

  List<Widget> _buildCurrentTimeIndicator(
    List<DateTime> weekDays,
    double columnWidth,
  ) {
    // Đã ẩn hoàn toàn đường line hiển thị thời gian thực theo yêu cầu
    return [];
  }

  // --- MONTH VIEW GRID (CUSTOM TABLE CALENDAR) ---

  Widget _buildTableCalendarMonthGrid() {
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      rowHeight: 110, // Tall cells for month grid
      headerVisible: false, // Controlled by header toolbar
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        defaultDecoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade100, width: 0.5),
        ),
        weekendDecoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade100, width: 0.5),
        ),
        selectedDecoration: BoxDecoration(
          color: primaryTeal.withOpacity(0.1),
          border: Border.all(color: primaryTeal, width: 1.5),
        ),
        todayDecoration: BoxDecoration(
          color: todayShiftBg.withOpacity(0.3),
          border: Border.all(color: todayShiftBorder, width: 1),
        ),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) =>
            _buildMonthDayCell(day, isOutside: false),
        selectedBuilder: (context, day, focusedDay) =>
            _buildMonthDayCell(day, isSelected: true),
        todayBuilder: (context, day, focusedDay) =>
            _buildMonthDayCell(day, isToday: true),
        outsideBuilder: (context, day, focusedDay) =>
            _buildMonthDayCell(day, isOutside: true),
      ),
    );
  }

  Widget _buildMonthDayCell(
    DateTime day, {
    bool isSelected = false,
    bool isToday = false,
    bool isOutside = false,
  }) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    final events = _calendarItems.where((item) => item.date == dayStr).toList();

    Color cellBg = Colors.white;
    if (isOutside) {
      cellBg = Colors.grey.shade50;
    } else if (isSelected) {
      cellBg = primaryTeal.withOpacity(0.05);
    } else if (isToday) {
      cellBg = todayShiftBg.withOpacity(0.15);
    }

    return Container(
      decoration: BoxDecoration(
        color: cellBg,
        border: Border.all(
          color: isSelected ? primaryTeal : Colors.grey.shade200,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6.0, top: 4.0, right: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: isToday
                      ? BoxDecoration(
                          color: todayShiftBorder,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: (isToday || isSelected)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isToday
                          ? Colors.white
                          : (isOutside ? Colors.grey.shade400 : Colors.black87),
                    ),
                  ),
                ),
                if (events.isNotEmpty && isOutside == false)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: events.any((e) => e.status == 'leave')
                          ? leaveBorder
                          : normalShiftBorder,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemCount: events.length.clamp(0, 2),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final event = events[index];
                final isLeave = event.status == 'leave';
                final isFull =
                    !isLeave && event.currentPatients >= event.maxPatients;

                Color capsuleBg = isLeave
                    ? leaveBg
                    : (isFull ? fullShiftBg : normalShiftBg);
                Color capsuleText = isLeave
                    ? leaveText
                    : (isFull ? fullShiftText : normalShiftText);

                return GestureDetector(
                  onTap: () => _handleEventClick(event),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: capsuleBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isLeave
                          ? 'Nghỉ phép'
                          : '${event.shiftName} (${event.currentPatients}/${event.maxPatients})',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: capsuleText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
          if (events.length > 2)
            Padding(
              padding: const EdgeInsets.only(left: 6.0, bottom: 2.0),
              child: Text(
                '+${events.length - 2} thêm...',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- STATISTICS GRID ---

  Widget _buildStatisticsGrid({bool isGrid = false}) {
    final stats = _calculateStats();

    final cards = [
      _buildStatTile(
        'Tổng ca tuần này',
        '${stats['totalShifts']}',
        Icons.calendar_month,
        primaryTeal,
      ),
      _buildStatTile(
        'Bệnh nhân đã đặt',
        '${stats['totalPatients']}',
        Icons.person_outline,
        Colors.blue,
      ),
      _buildStatTile(
        'Ca còn trống',
        '${stats['emptySlots']}',
        Icons.event_available,
        Colors.green,
      ),
      _buildStatTile(
        'Số ngày nghỉ',
        '${stats['leaveDays']}',
        Icons.event_busy,
        Colors.red,
      ),
    ];

    if (isGrid) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
        children: cards,
      );
    }

    return Column(
      children: cards
          .map(
            (c) =>
                Padding(padding: const EdgeInsets.only(bottom: 8.0), child: c),
          )
          .toList(),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- RIGHT SIDEBAR / TODAY SCHEDULE ---

  Widget _buildTodayScheduleSidebar() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayEvents = _calendarItems
        .where((e) => e.date == todayStr)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch trực hôm nay',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (todayEvents.isEmpty)
          Text(
            'Không có ca trực hôm nay',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...todayEvents.map((event) {
            final isLeave = event.status == 'leave';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLeave ? leaveBg : lightTeal,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLeave
                      ? leaveBorder.withOpacity(0.3)
                      : primaryTeal.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isLeave ? Icons.event_busy : Icons.access_time_filled,
                    color: isLeave ? leaveText : primaryTeal,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.shiftName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isLeave ? leaveText : primaryTeal,
                          ),
                        ),
                        Text(
                          '${event.startTime} - ${event.endTime}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLeave)
                    Text(
                      '${event.currentPatients}/${event.maxPatients}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildMiniCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(8.0),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          headerPadding: EdgeInsets.symmetric(vertical: 4.0),
        ),
        rowHeight: 32,
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 9),
          weekendStyle: TextStyle(fontSize: 9),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(fontSize: 10),
          weekendTextStyle: const TextStyle(fontSize: 10),
          selectedDecoration: BoxDecoration(
            color: primaryTeal,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: todayShiftBorder.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(color: Colors.transparent),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final dateStr = DateFormat('yyyy-MM-dd').format(date);
            final dayEvents = _calendarItems
                .where((e) => e.date == dateStr)
                .toList();
            if (dayEvents.isEmpty) return const SizedBox();
            final hasLeave = dayEvents.any((e) => e.status == 'leave');
            return Positioned(
              bottom: 2,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: hasLeave ? Colors.red : primaryTeal,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- MOBILE COMPONENTS ---

  Widget _buildMobileWeekCalendar() {
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.week,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
          _selectedDay = focusedDay;
        });
      },
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        headerPadding: EdgeInsets.symmetric(vertical: 4.0),
      ),
      rowHeight: 45,
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        weekendStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(fontSize: 12),
        weekendTextStyle: const TextStyle(fontSize: 12),
        selectedDecoration: BoxDecoration(
          color: primaryTeal,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: todayShiftBorder.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(color: Colors.transparent),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final dayEvents = _calendarItems
              .where((e) => e.date == dateStr)
              .toList();
          if (dayEvents.isEmpty) return const SizedBox();
          final hasLeave = dayEvents.any((e) => e.status == 'leave');
          return Positioned(
            bottom: 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: hasLeave ? Colors.red : primaryTeal,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileDailyTimeline() {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final dayEvents = _calendarItems
        .where((item) => item.date == selectedDateStr)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour Labels Column
        SizedBox(
          width: 50,
          child: Column(
            children: List.generate(_endHour - _startHour + 1, (index) {
              final hour = _startHour + index;
              final hourStr = '${hour.toString().padLeft(2, '0')}:00';
              return SizedBox(
                height: _hourHeight,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                    child: Text(
                      hourStr,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Day Timeline Stack
        Expanded(
          child: Container(
            height: (_endHour - _startHour + 1) * _hourHeight,
            child: Stack(
              children: [
                // Horizontal Grid lines
                Column(
                  children: List.generate(_endHour - _startHour + 1, (index) {
                    return Container(
                      height: _hourHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Event cards overlays
                ...dayEvents.map((event) {
                  final double top = _timeToOffset(event.startTime);
                  final double height = _durationToHeight(
                    event.startTime,
                    event.endTime,
                  );
                  return Positioned(
                    left: 4,
                    top: top + 2,
                    right: 8,
                    height: height - 4,
                    child: _buildEventCard(event, isCompact: false),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- LAYOUTS ---

  Widget _buildDesktopView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Lịch làm việc'),
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
            ),
      body: Column(
        children: [
          _buildHeaderToolbar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Timeline / Grid (80%)
                Expanded(
                  flex: 8,
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _viewMode == ScheduleViewMode.week
                          ? _buildWeeklyTimelineGrid()
                          : _buildTableCalendarMonthGrid(),
                    ),
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                ),
                // Right Sidebar: Mini Calendar + Stats + Today Schedule (20%)
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lịch thu nhỏ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildMiniCalendar(),
                        const SizedBox(height: 20),
                        const Text(
                          'Báo cáo tuần',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatisticsGrid(),
                        const SizedBox(height: 20),
                        _buildTodayScheduleSidebar(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Lịch làm việc'),
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
            ),
      body: Column(
        children: [
          _buildHeaderToolbar(),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ExpansionTile(
              leading: Icon(Icons.analytics_outlined, color: primaryTeal),
              title: const Text(
                'Lịch rút gọn & Thống kê tuần',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildMiniCalendar()),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _buildStatisticsGrid(isGrid: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: _viewMode == ScheduleViewMode.week
                  ? _buildWeeklyTimelineGrid()
                  : _buildTableCalendarMonthGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Lịch làm việc'),
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData,
                ),
              ],
            ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildMobileWeekCalendar(),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thống kê tuần này',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildStatisticsGrid(isGrid: true),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lịch trực ngày ${DateFormat('dd/MM/yyyy').format(_selectedDay)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _buildMobileDailyTimeline(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchInitialData,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000) {
          return _buildDesktopView();
        } else if (constraints.maxWidth >= 700) {
          return _buildTabletView();
        } else {
          return _buildMobileView();
        }
      },
    );
  }
}
