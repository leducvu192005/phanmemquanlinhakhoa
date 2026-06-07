class DoctorCalendarItem {
  final String id;
  final String date;
  final String shift;
  final String shiftName;
  final String startTime;
  final String endTime;
  final int maxPatients;
  final int currentPatients;
  final String status;
  final List<String> patients;
  final String? leaveType;
  final String? reason;

  DoctorCalendarItem({
    required this.id,
    required this.date,
    required this.shift,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.maxPatients,
    required this.currentPatients,
    required this.status,
    required this.patients,
    this.leaveType,
    this.reason,
  });

  factory DoctorCalendarItem.fromJson(Map<String, dynamic> json) {
    return DoctorCalendarItem(
      id: json['id']?.toString() ?? '',
      date: json['date'] ?? '',
      shift: json['shift'] ?? 'morning',
      shiftName: json['shift_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      maxPatients: json['max_patients'] ?? 0,
      currentPatients: json['current_patients'] ?? 0,
      status: json['status'] ?? 'working',
      patients: json['patients'] != null
          ? List<String>.from(json['patients'])
          : const [],
      leaveType: json['leave_type'],
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'shift': shift,
      'shift_name': shiftName,
      'start_time': startTime,
      'end_time': endTime,
      'max_patients': maxPatients,
      'current_patients': currentPatients,
      'status': status,
      'patients': patients,
      'leave_type': leaveType,
      'reason': reason,
    };
  }
}
