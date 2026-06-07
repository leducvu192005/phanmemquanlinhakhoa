class CalendarPatientDetail {
  final String name;
  final String phone;
  final String? gender;
  final String? dob;
  final String symptoms;
  final String status;

  CalendarPatientDetail({
    required this.name,
    required this.phone,
    this.gender,
    this.dob,
    required this.symptoms,
    required this.status,
  });

  factory CalendarPatientDetail.fromJson(Map<String, dynamic> json) {
    return CalendarPatientDetail(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'],
      dob: json['dob'],
      symptoms: json['symptoms'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'gender': gender,
      'dob': dob,
      'symptoms': symptoms,
      'status': status,
    };
  }
}

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
  final List<CalendarPatientDetail> patients;
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
          ? (json['patients'] as List)
              .map((e) => e is Map<String, dynamic>
                  ? CalendarPatientDetail.fromJson(e)
                  : CalendarPatientDetail(
                      name: e.toString(),
                      phone: '',
                      symptoms: '',
                      status: '',
                    ))
              .toList()
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
      'patients': patients.map((e) => e.toJson()).toList(),
      'leave_type': leaveType,
      'reason': reason,
    };
  }
}
