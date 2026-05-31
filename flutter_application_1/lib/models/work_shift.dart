class WorkShift {
  final int id;
  final String shiftCode;
  final String shiftName;
  final String startTime;
  final String endTime;
  final int maxPatients;
  final bool status;

  WorkShift({
    required this.id,
    required this.shiftCode,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.maxPatients,
    required this.status,
  });

  factory WorkShift.fromJson(Map<String, dynamic> json) {
    return WorkShift(
      id: json['id'],
      shiftCode: json['shift_code'],
      shiftName: json['shift_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      maxPatients: json['max_patients'],
      status: json['status'],
    );
  }
}
