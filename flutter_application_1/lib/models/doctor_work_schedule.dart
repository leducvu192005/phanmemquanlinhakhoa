class DoctorWorkSchedule {
  final String id;

  final String? doctorId;

  final String workShiftId;

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
      id: json['id']?.toString() ?? '',

      doctorId: json['doctor_id']?.toString(),

      workShiftId: json['work_shift_id']?.toString() ?? '',

      workDate: DateTime.parse(json['work_date'].toString()),

      maxPatients: json['max_patients'] ?? 0,

      currentPatients: json['current_patients'] ?? 0,

      status: json['status'] ?? 'unknown',

      note: json['note']?.toString(),

      doctorName: json['doctor_name']?.toString(),

      doctorCode: json['doctor_code']?.toString(),

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),

      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
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

  DoctorWorkSchedule copyWith({
    String? id,
    String? doctorId,
    String? workShiftId,
    DateTime? workDate,
    int? maxPatients,
    int? currentPatients,
    String? status,
    String? note,
    String? doctorName,
    String? doctorCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorWorkSchedule(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      workShiftId: workShiftId ?? this.workShiftId,
      workDate: workDate ?? this.workDate,
      maxPatients: maxPatients ?? this.maxPatients,
      currentPatients: currentPatients ?? this.currentPatients,
      status: status ?? this.status,
      note: note ?? this.note,
      doctorName: doctorName ?? this.doctorName,
      doctorCode: doctorCode ?? this.doctorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
