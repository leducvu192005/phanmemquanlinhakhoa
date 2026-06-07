import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/doctor_work_calendar_model.dart';
import '../services/doctor_work_calendar_service.dart';

class DoctorWorkCalendarScreen extends StatefulWidget {
  final bool isEmbedded;

  const DoctorWorkCalendarScreen({Key? key, this.isEmbedded = false})
    : super(key: key);

  @override
  State<DoctorWorkCalendarScreen> createState() =>
      _DoctorWorkCalendarScreenState();
}

class _DoctorWorkCalendarScreenState extends State<DoctorWorkCalendarScreen> {
  final CalendarController _calendarController = CalendarController();
  List<DoctorCalendarItem> _calendarItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // Color palette
  final Color primaryTeal = const Color(0xFF0F766E);
  final Color lightTeal = const Color(0xFFE6F7F6);
  final Color workColor = const Color(0xFF10B981); // Green
  final Color todayColor = const Color(0xFF3B82F6); // Blue
  final Color leaveColor = const Color(0xFFEF4444); // Red
  final Color emptyColor = const Color(0xFF94A3B8); // Grey

  @override
  void initState() {
    super.initState();
    _fetchCalendarData();
    _calendarController.displayDate = _selectedDate;
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _fetchCalendarData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await DoctorWorkCalendarService.getDoctorCalendar();
      setState(() {
        _calendarItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải lịch làm việc: $e';
        _isLoading = false;
      });
    }
  }

  List<Appointment> _getAppointments() {
    final List<Appointment> appointments = [];
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var item in _calendarItems) {
      if (item.status == 'leave') {
        // Leave request approved
        final date = DateTime.parse(item.date);
        appointments.add(
          Appointment(
            id: item.id,
            startTime: DateTime(date.year, date.month, date.day, 8, 0),
            endTime: DateTime(date.year, date.month, date.day, 21, 0),
            subject: 'NGHỈ PHÉP',
            color: leaveColor,
            isAllDay: false,
            notes: item.reason ?? 'Nghỉ phép được phê duyệt',
          ),
        );
      } else {
        // Working shift
        final date = DateTime.parse(item.date);
        final startParts = item.startTime.split(':');
        final endParts = item.endTime.split(':');

        final startHour = int.parse(startParts[0]);
        final startMin = int.parse(startParts[1]);
        final endHour = int.parse(endParts[0]);
        final endMin = int.parse(endParts[1]);

        final startDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          startHour,
          startMin,
        );
        final endDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          endHour,
          endMin,
        );

        final isToday = item.date == todayStr;
        final color = isToday ? todayColor : workColor;

        appointments.add(
          Appointment(
            id: item.id,
            startTime: startDateTime,
            endTime: endDateTime,
            subject:
                '${item.shiftName.toUpperCase()}\n${item.currentPatients} / ${item.maxPatients} BN',
            color: color,
            isAllDay: false,
            notes: 'Ca trực khám bệnh',
          ),
        );
      }
    }
    return appointments;
  }

  void _onCalendarTap(CalendarTapDetails details) {
    if (details.appointments == null || details.appointments!.isEmpty) {
      return;
    }

    final Appointment app = details.appointments!.first as Appointment;
    final String itemId = app.id.toString();

    try {
      final item = _calendarItems.firstWhere((x) => x.id == itemId);
      _showAppointmentDetails(item);
    } catch (e) {
      debugPrint('Error finding calendar item: $e');
    }
  }

  void _showAppointmentDetails(DoctorCalendarItem item) {
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
                item.status == 'leave'
                    ? Icons.event_busy
                    : Icons.calendar_today,
                color: item.status == 'leave' ? leaveColor : primaryTeal,
              ),
              const SizedBox(width: 12),
              Text(
                item.status == 'leave' ? 'Ngày nghỉ phép' : 'Chi tiết ca trực',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Ngày:', _formatDateStr(item.date)),
                _buildDetailRow('Ca trực:', item.shiftName),
                _buildDetailRow(
                  'Thời gian:',
                  '${item.startTime} - ${item.endTime}',
                ),
                if (item.status == 'leave') ...[
                  _buildDetailRow('Loại nghỉ:', item.leaveType ?? 'Nghỉ phép'),
                  _buildDetailRow(
                    'Lý do:',
                    item.reason ?? 'Không có lý do cụ thể',
                  ),
                ] else ...[
                  _buildDetailRow(
                    'Số bệnh nhân:',
                    '${item.currentPatients} / ${item.maxPatients}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Danh sách bệnh nhân đặt hẹn:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (item.patients.isEmpty)
                    Text(
                      'Chưa có bệnh nhân nào đặt lịch cho ca này.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: item.patients.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: lightTeal,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: primaryTeal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              item.patients[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateStr(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
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
                onPressed: _fetchCalendarData,
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
        if (constraints.maxWidth > 950) {
          return _buildDesktopView();
        } else if (constraints.maxWidth > 600) {
          return _buildTabletView();
        } else {
          return _buildMobileView();
        }
      },
    );
  }

  // --- DESKTOP VIEW ---
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
      body: Row(
        children: [
          // Weekly Calendar View
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
                child: _buildSfCalendar(),
              ),
            ),
          ),
          // Divider
          Container(width: 1, color: Colors.grey.shade200),
          // Mini Calendar & Legends
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Lịch làm việc cá nhân',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mini Calendar
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: CalendarDatePicker(
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onDateChanged: (DateTime date) {
                          setState(() {
                            _selectedDate = date;
                            _calendarController.displayDate = date;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Chú thích màu sắc',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem('Ca trực đã đăng ký', workColor),
                    _buildLegendItem('Ca trực hôm nay', todayColor),
                    _buildLegendItem('Ngày nghỉ phép', leaveColor),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _fetchCalendarData,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'Làm mới lịch',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TABLET VIEW ---
  Widget _buildTabletView() {
    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Lịch làm việc'),
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
            ),
      body: Card(
        elevation: 0,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSfCalendar(),
        ),
      ),
    );
  }

  // --- MOBILE VIEW ---
  Widget _buildMobileView() {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayItems = _calendarItems
        .where((item) => item.date == selectedDateStr)
        .toList();

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
          // Simplified horizontal day chooser
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _buildHorizontalWeekSelector(),
          ),
          const Divider(height: 1),
          // List of shifts/leaves for the selected date
          Expanded(
            child: dayItems.isEmpty
                ? _buildMobileEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dayItems.length,
                    itemBuilder: (context, index) {
                      final item = dayItems[index];
                      return _buildMobileScheduleCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Main SfCalendar widget
  Widget _buildSfCalendar() {
    return SfCalendar(
      controller: _calendarController,
      view: CalendarView.week,
      firstDayOfWeek: 1, // Monday
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 7,
        endHour: 21,
        nonWorkingDays: <int>[],
      ),
      dataSource: DoctorCalendarDataSource(_getAppointments()),
      onTap: _onCalendarTap,
      appointmentBuilder: (context, calendarAppointmentDetails) {
        final Appointment app =
            calendarAppointmentDetails.appointments.first as Appointment;
        return Container(
          decoration: BoxDecoration(
            color: app.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  '${DateFormat('HH:mm').format(app.startTime)} - ${DateFormat('HH:mm').format(app.endTime)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Legends Item Helper
  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Mobile Week Horizontal Selector
  Widget _buildHorizontalWeekSelector() {
    // Generate 7 days around the selected date
    final List<DateTime> weekDays = [];
    final monday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    for (int i = 0; i < 7; i++) {
      weekDays.add(monday.add(Duration(days: i)));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        final isSelected =
            day.year == _selectedDate.year &&
            day.month == _selectedDate.month &&
            day.day == _selectedDate.day;

        final weekdayStr = _getShortWeekday(day.weekday);
        final dayStr = DateFormat('dd').format(day);

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = day;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primaryTeal : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  weekdayStr,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayStr,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getShortWeekday(int weekday) {
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

  Widget _buildMobileEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Không có lịch trực hay lịch nghỉ phép',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileScheduleCard(DoctorCalendarItem item) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = item.date == todayStr;

    Color cardHeaderColor = workColor;
    if (item.status == 'leave') {
      cardHeaderColor = leaveColor;
    } else if (isToday) {
      cardHeaderColor = todayColor;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showAppointmentDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Left bar color indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: cardHeaderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              // Time and name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.shiftName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.startTime} - ${item.endTime}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Patient count or leave info
              if (item.status == 'leave')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: leaveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'NGHỈ PHÉP',
                    style: TextStyle(
                      color: leaveColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Bệnh nhân',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.currentPatients} / ${item.maxPatients}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: item.currentPatients >= item.maxPatients
                            ? Colors.red
                            : primaryTeal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom DataSource for SfCalendar
class DoctorCalendarDataSource extends CalendarDataSource {
  DoctorCalendarDataSource(List<Appointment> source) {
    appointments = source;
  }
}
