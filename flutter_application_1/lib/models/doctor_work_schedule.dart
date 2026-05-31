class DoctorWorkSchedule {
  final int id;

  // UUID string
  final String? doctorId;

  final int workShiftId;

  final DateTime workDate;

  final int maxPatients;

  final int currentPatients;

  final String status;

  final String? note;

  // join từ bảng doctors
  final String? doctorName;

  final String? doctorCode;

  final DateTime createdAt;

  final DateTime updatedAt;

  DoctorWorkSchedule({
    required this.id,
    this.doctorId,
    required this.workShiftId,
    required this.workDate,
    required this.maxPatients,
    required this.currentPatients,
    required this.status,
    this.note,
    this.doctorName,
    this.doctorCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorWorkSchedule.fromJson(Map<String, dynamic> json) {
    return DoctorWorkSchedule(
      id: json['id'] ?? 0,

      // UUID -> String
      doctorId: json['doctor_id']?.toString(),

      workShiftId: json['work_shift_id'] ?? 0,

      workDate: DateTime.parse(json['work_date']),

      maxPatients: json['max_patients'] ?? 0,

      currentPatients: json['current_patients'] ?? 0,

      status: json['status'] ?? "unknown",

      note: json['note'],

      // join doctors
      doctorName: json['doctor_name'],

      doctorCode: json['doctor_code'],

      createdAt: DateTime.parse(json['created_at']),

      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "doctor_id": doctorId,
      "work_shift_id": workShiftId,
      "work_date": workDate.toIso8601String().split('T')[0],
      "max_patients": maxPatients,
      "current_patients": currentPatients,
      "status": status,
      "note": note,
    };
  }
}
