import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../models/leave_request_model.dart';
import '../services/leave_request_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  final bool isEmbedded;
  final bool isStaff;

  const LeaveRequestScreen({
    super.key,
    this.isEmbedded = false,
    this.isStaff = false,
  });

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  // --- BẢNG MÀU PHÒNG KHÁM NHA KHOA ---
  final Color primaryTeal = const Color(0xFF0F766E);
  final Color lightTeal = const Color(0xFFE6F7F6);
  final Color accentTeal = const Color(0xFF2DD4BF);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;

  final _storage = const FlutterSecureStorage();
  int? _currentUserId;

  bool _isLoading = true;
  List<LeaveRequest> _allRequests = [];
  List<LeaveRequest> _filteredRequests = [];
  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
    'cancelled': 0,
  };

  // Staff switch tab: false = duyệt yêu cầu, true = yêu cầu của tôi
  bool _viewingOwn = false;

  // Bộ lọc
  final List<String> _filterOptions = [
    'Tất cả',
    'Chờ duyệt',
    'Đã duyệt',
    'Từ chối',
    'Đã hủy'
  ];
  String _selectedFilter = 'Tất cả';
  String _searchQuery = '';

  // Form Đăng ký nghỉ phép
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedLeaveType = 'Nghỉ phép';
  final List<String> _leaveTypes = ['Nghỉ phép', 'Nghỉ ốm', 'Công tác', 'Khác'];
  final _reasonCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Đối với bác sĩ, luôn xem yêu cầu của chính họ
    if (!widget.isStaff) {
      _viewingOwn = true;
    }
    _loadCurrentUserId();
    _loadData();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final token = await _storage.read(key: 'jwt');
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          String normalized = base64Url.normalize(parts[1]);
          String resp = utf8.decode(base64Url.decode(normalized));
          final payload = jsonDecode(resp);
          setState(() {
            _currentUserId = int.tryParse(payload['sub']?.toString() ?? '');
          });
        }
      } catch (e) {
        debugPrint("Error decoding jwt: $e");
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Tải thống kê
      final statsData = await LeaveRequestService.getStats(own: _viewingOwn);
      // 2. Tải danh sách yêu cầu
      final list = await LeaveRequestService.getRequests(own: _viewingOwn);
      
      if (mounted) {
        setState(() {
          _stats = statsData;
          _allRequests = list;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    setState(() {
      Iterable<LeaveRequest> list = _allRequests;

      // 1. Filter by status
      if (_selectedFilter != 'Tất cả') {
        String statusMapped = 'Pending';
        if (_selectedFilter == 'Chờ duyệt') statusMapped = 'Pending';
        if (_selectedFilter == 'Đã duyệt') statusMapped = 'Approved';
        if (_selectedFilter == 'Từ chối') statusMapped = 'Rejected';
        if (_selectedFilter == 'Đã hủy') statusMapped = 'Cancelled';

        list = list.where((req) => req.status.toLowerCase() == statusMapped.toLowerCase());
      }

      // 2. Filter by search query
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        list = list.where((req) {
          final name = (req.userName ?? '').toLowerCase();
          final email = (req.userEmail ?? '').toLowerCase();
          final code = req.requestCode.toLowerCase();
          final type = req.leaveType.toLowerCase();
          final r = req.reason.toLowerCase();
          return name.contains(q) || email.contains(q) || code.contains(q) || type.contains(q) || r.contains(q);
        });
      }

      _filteredRequests = list.toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  // Gửi yêu cầu nghỉ phép
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ ngày bắt đầu và ngày kết thúc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (_startDate!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không được đăng ký nghỉ phép trong quá khứ.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc không được nhỏ hơn ngày bắt đầu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    final body = {
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
      'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
      'leave_type': _selectedLeaveType,
      'reason': _reasonCtrl.text.trim(),
    };

    try {
      await LeaveRequestService.createRequest(body);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu nghỉ phép thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _startDate = null;
          _endDate = null;
          _selectedLeaveType = 'Nghỉ phép';
          _reasonCtrl.clear();
          _isSubmitting = false;
        });

        // Reload
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi yêu cầu thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hủy yêu cầu (Pending)
  Future<void> _cancelRequest(int id) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await LeaveRequestService.cancelRequest(id);
      if (mounted) {
        navigator.pop(); // Đóng loading dialog
        navigator.pop(); // Đóng details dialog

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Đã hủy yêu cầu nghỉ phép thành công!'),
            backgroundColor: Colors.grey,
          ),
        );

        _loadData();
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Đóng loading dialog
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Không thể hủy yêu cầu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Phê duyệt yêu cầu (Staff)
  Future<void> _approveRequest(int id) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await LeaveRequestService.approveRequest(id);
      if (mounted) {
        navigator.pop(); // Đóng loading dialog
        navigator.pop(); // Đóng details dialog

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Đã phê duyệt yêu cầu nghỉ phép thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        _loadData();
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Đóng loading dialog
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Phê duyệt thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Từ chối yêu cầu (Staff)
  Future<void> _rejectRequest(int id, String reason) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await LeaveRequestService.rejectRequest(id, reason);
      if (mounted) {
        navigator.pop(); // Đóng loading dialog
        navigator.pop(); // Đóng details dialog

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối yêu cầu nghỉ phép thành công!'),
            backgroundColor: Colors.redAccent,
          ),
        );

        _loadData();
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Đóng loading dialog
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Từ chối thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectReasonDialog(int id) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập lý do từ chối'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: 'Nhập lý do cụ thể từ chối yêu cầu này...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context); // Đóng reject reason dialog
              _rejectRequest(id, reason);
            },
            child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 950;
    // Form chỉ được vẽ trên cột bên phải Web/Desktop khi đang ở chế độ xem yêu cầu của chính mình (hoặc với bác sĩ)
    final bool shouldShowRightForm = isWide && _viewingOwn;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                widget.isStaff ? 'Quản Lý Nghỉ Phép' : 'Yêu Cầu Nghỉ Phép',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: primaryTeal,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryTeal))
                : shouldShowRightForm
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cột trái: Thống kê + Bộ lọc + Danh sách
                          Expanded(
                            flex: 7,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeaderStats(),
                                  const SizedBox(height: 24),
                                  _buildFilterSection(),
                                  const SizedBox(height: 16),
                                  _buildRequestsList(),
                                ],
                              ),
                            ),
                          ),
                          // Ngăn cách dọc
                          Container(width: 1, color: Colors.grey.shade200, height: double.infinity),
                          // Cột phải: Form Đăng ký cố định
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildLeaveRequestFormCard(),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderStats(),
                            const SizedBox(height: 20),
                            _buildFilterSection(),
                            const SizedBox(height: 16),
                            _buildRequestsList(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: (isWide || !_viewingOwn)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openRequestFormBottomSheet(),
              backgroundColor: primaryTeal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Đăng ký nghỉ phép', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }


  // --- STATS HEADER ---
  Widget _buildHeaderStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard('Tổng yêu cầu', _stats['total'] ?? 0, Colors.blueGrey, Icons.assessment_outlined),
            _buildStatCard('Chờ duyệt', _stats['pending'] ?? 0, Colors.orange, Icons.hourglass_empty),
            _buildStatCard('Đã duyệt', _stats['approved'] ?? 0, Colors.green, Icons.check_circle_outline),
            _buildStatCard('Từ chối', _stats['rejected'] ?? 0, Colors.red, Icons.cancel_outlined),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    
    return Container(
      width: isMobile ? (MediaQuery.of(context).size.width - 44) / 2 : 200,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
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

  // --- FILTER SECTION ---
  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (val) {
            _searchQuery = val;
            _applyFilter();
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm theo tên nhân viên, loại nghỉ, lý do...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: primaryTeal, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final opt = _filterOptions[index];
              final isSelected = _selectedFilter == opt;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(opt),
                  selected: isSelected,
                  selectedColor: lightTeal,
                  checkmarkColor: primaryTeal,
                  labelStyle: TextStyle(
                    color: isSelected ? primaryTeal : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? primaryTeal : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = opt;
                        _applyFilter();
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- REQUESTS LIST ---
  Widget _buildRequestsList() {
    if (_filteredRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy yêu cầu nghỉ phép nào',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        final req = _filteredRequests[index];
        final startStr = DateFormat('dd/MM/yyyy').format(req.startDate);
        final endStr = DateFormat('dd/MM/yyyy').format(req.endDate);
        final createdStr = DateFormat('dd/MM/yyyy HH:mm').format(req.createdAt.toLocal());
        final statusColor = _getStatusColor(req.status);

        return Card(
          color: cardColor,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showRequestDetailsDialog(req),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        req.requestCode,
                        style: TextStyle(
                          color: primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(req.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.isStaff && !_viewingOwn) ...[
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Người gửi: ${req.userName} (${req.userRole == 'doctor' ? 'Bác sĩ' : 'Nhân viên'})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '$startStr -> $endStr',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Loại nghỉ: ${req.leaveType}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.create_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Ngày tạo: $createdStr',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- DETAILS DIALOG ---
  void _showRequestDetailsDialog(LeaveRequest req) {
    final startStr = DateFormat('dd/MM/yyyy').format(req.startDate);
    final endStr = DateFormat('dd/MM/yyyy').format(req.endDate);
    final createdStr = DateFormat('dd/MM/yyyy HH:mm').format(req.createdAt.toLocal());
    final approvedStr = req.approvedAt != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(req.approvedAt!.toLocal())
        : null;
    final statusColor = _getStatusColor(req.status);

    final bool isOwnRequest = req.userId == _currentUserId;
    final bool showApprovalButtons = widget.isStaff && !_viewingOwn && req.status.toLowerCase() == 'pending';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chi Tiết Yêu Cầu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mã & Trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req.requestCode,
                      style: TextStyle(
                        color: primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(req.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Thông tin chi tiết
                _buildDetailRow('Người gửi', '${req.userName ?? 'Chưa rõ'} (${req.userRole == 'doctor' ? 'Bác sĩ' : 'Nhân viên'})'),
                const SizedBox(height: 10),
                _buildDetailRow('Thời gian nghỉ', '$startStr đến $endStr'),
                const SizedBox(height: 10),
                _buildDetailRow('Loại nghỉ phép', req.leaveType),
                const SizedBox(height: 10),
                _buildDetailRow('Lý do nghỉ', req.reason),
                const SizedBox(height: 10),
                _buildDetailRow('Thời điểm tạo', createdStr),
                
                if (req.approvedByName != null) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow('Người duyệt', req.approvedByName!),
                ],
                if (approvedStr != null) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow('Thời điểm duyệt', approvedStr),
                ],
                if (req.rejectReason != null && req.rejectReason!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow('Lý do từ chối', req.rejectReason!, isAlert: true),
                ],
                
                // NÚT HỦY YÊU CẦU CỦA CHÍNH MÌNH
                if (isOwnRequest && req.status.toLowerCase() == 'pending') ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmCancelDialog(req.id),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                      label: const Text(
                        'Hủy yêu cầu nghỉ phép',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // NÚT PHÊ DUYỆT / TỪ CHỐI (Dành cho Staff duyệt đơn người khác)
                if (showApprovalButtons) ...[
                  const SizedBox(height: 30),
                  if (isOwnRequest)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '⚠️ Bạn không thể tự phê duyệt/từ chối yêu cầu nghỉ phép của chính mình.',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showRejectReasonDialog(req.id),
                            icon: const Icon(Icons.close_rounded, color: Colors.red),
                            label: const Text('Từ chối', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmApproveDialog(req.id),
                            icon: const Icon(Icons.check_rounded, color: Colors.white),
                            label: const Text('Phê duyệt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isAlert ? Colors.redAccent : Colors.black87,
            fontWeight: isAlert ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _confirmCancelDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy yêu cầu'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu nghỉ phép này? Trạng thái sẽ được đổi thành Đã hủy (Cancelled).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context); // Đóng confirm dialog
              _cancelRequest(id);
            },
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmApproveDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận phê duyệt'),
        content: const Text('Bạn có chắc chắn muốn phê duyệt yêu cầu nghỉ phép này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context); // Đóng confirm dialog
              _approveRequest(id);
            },
            child: const Text('Xác nhận duyệt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FORM ĐĂNG KÝ NGHỈ PHÉP ---
  Widget _buildLeaveRequestFormCard() {
    final startStr = _startDate == null ? 'Chọn ngày bắt đầu' : DateFormat('dd/MM/yyyy').format(_startDate!);
    final endStr = _endDate == null ? 'Chọn ngày kết thúc' : DateFormat('dd/MM/yyyy').format(_endDate!);

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ĐĂNG KÝ NGHỈ PHÉP MỚI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Loại nghỉ phép
              DropdownButtonFormField<String>(
                initialValue: _selectedLeaveType,
                decoration: InputDecoration(
                  labelText: 'Loại nghỉ phép *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: _leaveTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLeaveType = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Chọn ngày
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        startStr,
                        style: TextStyle(
                          color: _startDate == null ? Colors.black54 : primaryTeal,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickStartDate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        endStr,
                        style: TextStyle(
                          color: _endDate == null ? Colors.black54 : primaryTeal,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickEndDate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lý do
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Lý do xin nghỉ phép *',
                  hintText: 'Vui lòng cung cấp lý do nghỉ phép chi tiết...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.comment_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng điền lý do xin nghỉ phép' : null,
              ),
              const SizedBox(height: 24),

              // Nút Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded),
                            SizedBox(width: 8),
                            Text(
                              'Gửi yêu cầu nghỉ phép',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate == null || _endDate!.isBefore(_startDate!)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  // --- BOTTOM SHEET FORM (MOBILE) ---
  void _openRequestFormBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final startStr = _startDate == null ? 'Chọn ngày bắt đầu' : DateFormat('dd/MM/yyyy').format(_startDate!);
            final endStr = _endDate == null ? 'Chọn ngày kết thúc' : DateFormat('dd/MM/yyyy').format(_endDate!);

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ĐĂNG KÝ NGHỈ PHÉP MỚI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Loại nghỉ phép
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLeaveType,
                        decoration: InputDecoration(
                          labelText: 'Loại nghỉ phép *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        items: _leaveTypes.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => _selectedLeaveType = val);
                            setState(() => _selectedLeaveType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Chọn ngày
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                startStr,
                                style: TextStyle(
                                  color: _startDate == null ? Colors.black54 : primaryTeal,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    _startDate = picked;
                                    if (_endDate == null || _endDate!.isBefore(_startDate!)) {
                                      _endDate = picked;
                                    }
                                  });
                                  setState(() {
                                    _startDate = picked;
                                    if (_endDate == null || _endDate!.isBefore(_startDate!)) {
                                      _endDate = picked;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                endStr,
                                style: TextStyle(
                                  color: _endDate == null ? Colors.black54 : primaryTeal,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? _startDate ?? DateTime.now(),
                                  firstDate: _startDate ?? DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() => _endDate = picked);
                                  setState(() => _endDate = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lý do
                      TextFormField(
                        controller: _reasonCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Lý do xin nghỉ phép *',
                          hintText: 'Vui lòng cung cấp lý do nghỉ phép chi tiết...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.comment_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng điền lý do xin nghỉ phép' : null,
                      ),
                      const SizedBox(height: 24),

                      // Nút Submit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final navigator = Navigator.of(context);
                                  await _submitRequest();
                                  if (!_isSubmitting) {
                                    navigator.pop(); // Đóng bottom sheet nếu thành công
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded),
                                    SizedBox(width: 8),
                                    Text(
                                      'Gửi yêu cầu nghỉ phép',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
          },
        );
      },
    );
  }
}
