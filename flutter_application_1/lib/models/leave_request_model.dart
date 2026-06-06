class LeaveRequest {
  final int id;
  final String requestCode;
  final int userId;
  final String? userName;
  final String? userEmail;
  final String? userRole;
  final DateTime startDate;
  final DateTime endDate;
  final String leaveType; // 'Nghỉ phép', 'Nghỉ ốm', 'Công tác', 'Khác'
  final String reason;
  final String status; // 'Pending', 'Approved', 'Rejected', 'Cancelled'
  final DateTime createdAt;
  final int? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectReason;

  LeaveRequest({
    required this.id,
    required this.requestCode,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userRole,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectReason,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int,
      requestCode: json['request_code'] ?? '',
      userId: json['user_id'] as int,
      userName: json['user_name'],
      userEmail: json['user_email'],
      userRole: json['user_role'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      leaveType: json['leave_type'] ?? 'Nghỉ phép',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.parse(json['created_at']),
      approvedBy: json['approved_by'] as int?,
      approvedByName: json['approved_by_name'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      rejectReason: json['reject_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'leave_type': leaveType,
      'reason': reason,
    };
  }
}
