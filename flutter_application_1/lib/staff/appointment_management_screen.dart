import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/doctor_model.dart';
import '../models/service.dart';
import '../services/booking_service.dart';
import '../services/doctor_service.dart';
import '../services/service_api.dart';
import 'staff_create_booking_screen.dart';

class StaffAppointmentDashboard extends StatefulWidget {
  const StaffAppointmentDashboard({super.key});

  @override
  State<StaffAppointmentDashboard> createState() => _StaffAppointmentDashboardState();
}

class _StaffAppointmentDashboardState extends State<StaffAppointmentDashboard> {
  final _doctorService = DoctorService();
  
  List<Booking> _bookings = [];
  List<Doctor> _doctors = [];
  List<Service> _services = [];
  
  Map<String, dynamic> _stats = {
    'all': {'total': 0, 'pending': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0},
    'today': {'total': 0, 'pending': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0}
  };

  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDoctorId;
  String? _selectedStatus;
  DateTime? _selectedDate;
  
  final Color primaryColor = const Color(0xFF0F766E); // Deep Teal
  final Color accentColor = const Color(0xFF2DD4BF); // Light Teal

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _doctorService.getDoctors();
      final svcs = await ServiceApi.getServices();
      setState(() {
        _doctors = docs;
        _services = svcs;
      });
      await _fetchAppointmentsAndStats();
    } catch (e) {
      print('Staff Dashboard error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu ban đầu: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAppointmentsAndStats() async {
    try {
      final dateStr = _selectedDate != null 
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!) 
          : null;
          
      final list = await BookingService.getAllBookings(
        doctorId: _selectedDoctorId,
        dateStr: dateStr,
        status: _selectedStatus,
        search: _searchQuery,
      );
      
      final summary = await BookingService.getStatsSummary();
      
      setState(() {
        _bookings = list;
        _stats = summary;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách lịch khám: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await BookingService.updateStatus(id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái thành công!'), backgroundColor: Colors.green),
      );
      _fetchAppointmentsAndStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _cancelAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy cuộc hẹn'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch khám này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Quay lại')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await BookingService.updateStatus(id, 'cancelled');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy lịch khám!'), backgroundColor: Colors.green),
      );
      _fetchAppointmentsAndStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hủy lịch: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _rescheduleAppointment(String id, String currentBookingDate, String currentTimeSlot) async {
    DateTime initialDate;
    try {
      initialDate = DateTime.parse(currentBookingDate);
    } catch (_) {
      initialDate = DateTime.now().add(const Duration(days: 1));
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(DateTime.now()) ? initialDate : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (selectedDate == null) return;
    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (selectedTime == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final slotStr = 'Ca ${selectedTime.hour >= 12 ? "Chiều" : "Sáng"} (${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')})';

    try {
      await BookingService.updateBooking(id, bookingDate: dateStr, timeSlot: slotStr);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi lịch khám thành công!'), backgroundColor: Colors.green),
      );
      _fetchAppointmentsAndStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đổi lịch: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _reassignDoctor(String id, String currentDoctorId) async {
    String? chosenDocId = currentDoctorId;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chuyển bác sĩ điều trị'),
          content: DropdownButtonFormField<String>(
            value: chosenDocId,
            items: _doctors.map((d) => DropdownMenuItem(
              value: d.id,
              child: Text(d.fullName),
            )).toList(),
            onChanged: (val) {
              setDialogState(() {
                chosenDocId = val;
              });
            },
            decoration: const InputDecoration(labelText: 'Bác sĩ điều trị', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || chosenDocId == null || chosenDocId == currentDoctorId) return;

    try {
      await BookingService.updateBooking(id, doctorId: chosenDocId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chuyển bác sĩ điều trị thành công!'), backgroundColor: Colors.green),
      );
      _fetchAppointmentsAndStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chuyển bác sĩ: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _openStaffBookingDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffCreateBookingScreen(
          onSuccess: () {
            _fetchAppointmentsAndStats();
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade800;
      case 'confirmed':
        return const Color(0xFF0F766E);
      case 'checked_in':
        return Colors.blue.shade700;
      case 'in_progress':
        return Colors.indigo.shade700;
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
        return 'Chờ duyệt';
      case 'confirmed':
        return 'Đã duyệt';
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
        title: const Text('Quản lý & Theo dõi lịch khám', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: _openStaffBookingDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Đăng ký lịch khám',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: _fetchAppointmentsAndStats,
          ),
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsBanner(),
                _buildFilterBar(),
                Expanded(
                  child: _bookings.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy lịch khám nào khớp với bộ lọc',
                            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        )
                      : _buildDataTable(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    final allStats = _stats['all'] ?? {};
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildStatsCard('Tổng lịch hẹn', allStats['total'] ?? 0, Colors.blue.shade700, Icons.assignment_outlined),
          const SizedBox(width: 12),
          _buildStatsCard('Chờ duyệt', allStats['pending'] ?? 0, Colors.amber.shade800, Icons.hourglass_empty),
          const SizedBox(width: 12),
          _buildStatsCard('Đã duyệt', allStats['confirmed'] ?? 0, primaryColor, Icons.check_circle_outline),
          const SizedBox(width: 12),
          _buildStatsCard('Hoàn thành', allStats['completed'] ?? 0, Colors.green.shade700, Icons.task_alt),
          const SizedBox(width: 12),
          _buildStatsCard('Đã hủy', allStats['cancelled'] ?? 0, Colors.redAccent.shade700, Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          // Search box
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm theo tên BN, bác sĩ, lý do...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
                _fetchAppointmentsAndStats();
              },
            ),
          ),
          const SizedBox(width: 12),
          
          // Doctor Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedDoctorId,
              hint: const Text('Bác sĩ'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Tất cả bác sĩ')),
                ..._doctors.map((d) => DropdownMenuItem(value: d.id, child: Text(d.fullName))),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedDoctorId = val;
                });
                _fetchAppointmentsAndStats();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              hint: const Text('Trạng thái'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Tất cả trạng thái')),
                const DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                const DropdownMenuItem(value: 'confirmed', child: Text('Đã duyệt')),
                const DropdownMenuItem(value: 'checked_in', child: Text('Đã Check-in')),
                const DropdownMenuItem(value: 'in_progress', child: Text('Đang khám')),
                const DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                const DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedStatus = val;
                });
                _fetchAppointmentsAndStats();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Date Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  _selectedDate == null 
                      ? 'Lọc ngày: Tất cả' 
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  style: const TextStyle(fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                      _fetchAppointmentsAndStats();
                    }
                  },
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                      _fetchAppointmentsAndStats();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
              dataRowHeight: 65,
              columns: const [
                DataColumn(label: Text('Mã cuộc hẹn', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Bác sĩ điều trị', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Dịch vụ', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ngày giờ khám', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Hành động quản lý', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _bookings.map((appt) {
                String formattedDate = appt.bookingDate;
                try {
                  final parsedDate = DateTime.parse(appt.bookingDate);
                  formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                } catch (_) {}
                final formattedTime = appt.timeSlot;
                final patientName = appt.patient?.fullName ?? 'Khách lạ';
                final doctorName = appt.doctor?.fullName ?? 'Chưa chỉ định';
                const serviceName = 'Khám & Tư vấn răng hàm mặt';

                return DataRow(
                  cells: [
                    DataCell(Text('LH-${appt.id}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(patientName, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(doctorName)),
                    DataCell(const Text(serviceName)),
                    DataCell(Text('$formattedTime, ngày $formattedDate', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(appt.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusName(appt.status),
                          style: TextStyle(color: _getStatusColor(appt.status), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(_buildActionsCell(appt)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsCell(Booking appt) {
    final status = appt.status.toLowerCase();
    
    if (status == 'completed' || status == 'cancelled' || status == 'no_show') {
      return const Text('Không thể thao tác', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CONFIRM Action (Pending -> Confirmed)
        if (status == 'pending')
          IconButton(
            tooltip: 'Xác nhận cuộc hẹn',
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _updateStatus(appt.id, 'confirmed'),
          ),

        // CHECK IN Action (Confirmed -> Checked In)
        if (status == 'confirmed')
          IconButton(
            tooltip: 'Check-in bệnh nhân',
            icon: const Icon(Icons.login, color: Colors.blue),
            onPressed: () => _updateStatus(appt.id, 'checked_in'),
          ),

        // START TREATMENT Action (Checked In -> In Progress)
        if (status == 'checked_in')
          IconButton(
            tooltip: 'Bác sĩ bắt đầu khám',
            icon: const Icon(Icons.play_circle_outline, color: Colors.teal),
            onPressed: () => _updateStatus(appt.id, 'in_progress'),
          ),

        // COMPLETE TREATMENT Action (In Progress -> Completed)
        if (status == 'in_progress')
          IconButton(
            tooltip: 'Hoàn thành điều trị',
            icon: const Icon(Icons.task_alt, color: Colors.green),
            onPressed: () => _updateStatus(appt.id, 'completed'),
          ),

        // RESCHEDULE Action
        if (status == 'pending' || status == 'confirmed')
          IconButton(
            tooltip: 'Đổi ngày/giờ khám',
            icon: const Icon(Icons.calendar_month, color: Colors.orange),
            onPressed: () => _rescheduleAppointment(appt.id, appt.bookingDate, appt.timeSlot),
          ),

        // REASSIGN DOCTOR Action
        if (status == 'pending' || status == 'confirmed')
          IconButton(
            tooltip: 'Chuyển bác sĩ điều trị',
            icon: const Icon(Icons.person_add_outlined, color: Colors.indigo),
            onPressed: () => _reassignDoctor(appt.id, appt.doctorId),
          ),

        // CANCEL Action
        IconButton(
          tooltip: 'Hủy cuộc hẹn',
          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
          onPressed: () => _cancelAppointment(appt.id),
        ),
      ],
    );
  }
}
