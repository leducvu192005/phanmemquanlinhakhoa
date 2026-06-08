class SalaryConfigModel {
  final int id;
  final double baseSalaryPerHour;
  final String effectiveDate;
  final String createdAt;

  SalaryConfigModel({
    required this.id,
    required this.baseSalaryPerHour,
    required this.effectiveDate,
    required this.createdAt,
  });

  factory SalaryConfigModel.fromJson(Map<String, dynamic> json) {
    return SalaryConfigModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      baseSalaryPerHour: (json['base_salary_per_hour'] as num?)?.toDouble() ?? 0.0,
      effectiveDate: json['effective_date'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class SalaryShiftCoefficientModel {
  final int id;
  final String shiftName;
  final double coefficient;
  final String createdAt;

  SalaryShiftCoefficientModel({
    required this.id,
    required this.shiftName,
    required this.coefficient,
    required this.createdAt,
  });

  factory SalaryShiftCoefficientModel.fromJson(Map<String, dynamic> json) {
    return SalaryShiftCoefficientModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      shiftName: json['shift_name'] ?? '',
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class SalaryComplexityCoefficientModel {
  final int id;
  final String complexityLevel;
  final double coefficient;
  final String createdAt;

  SalaryComplexityCoefficientModel({
    required this.id,
    required this.complexityLevel,
    required this.coefficient,
    required this.createdAt,
  });

  factory SalaryComplexityCoefficientModel.fromJson(Map<String, dynamic> json) {
    return SalaryComplexityCoefficientModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      complexityLevel: json['complexity_level'] ?? '',
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class SalarySlipModel {
  final int id;
  final String doctorId;
  final int month;
  final int year;
  final double baseRate;
  final double doctorCoefficient;
  final int totalShifts;
  final double totalHours;
  final double totalComplexityCoef;
  final double totalSalary;
  final String createdAt;
  final int? createdBy;
  final String doctorName;
  final String doctorCode;
  final String doctorQualification;

  SalarySlipModel({
    required this.id,
    required this.doctorId,
    required this.month,
    required this.year,
    required this.baseRate,
    required this.doctorCoefficient,
    required this.totalShifts,
    required this.totalHours,
    required this.totalComplexityCoef,
    required this.totalSalary,
    required this.createdAt,
    this.createdBy,
    required this.doctorName,
    required this.doctorCode,
    required this.doctorQualification,
  });

  factory SalarySlipModel.fromJson(Map<String, dynamic> json) {
    final doctorMap = json['doctor'] as Map<String, dynamic>?;
    return SalarySlipModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      doctorId: json['doctor_id'] ?? '',
      month: json['month'] is num ? (json['month'] as num).toInt() : 1,
      year: json['year'] is num ? (json['year'] as num).toInt() : 2026,
      baseRate: (json['base_rate'] as num?)?.toDouble() ?? 0.0,
      doctorCoefficient: (json['doctor_coefficient'] as num?)?.toDouble() ?? 1.0,
      totalShifts: json['total_shifts'] is num ? (json['total_shifts'] as num).toInt() : 0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalComplexityCoef: (json['total_complexity_coef'] as num?)?.toDouble() ?? 0.0,
      totalSalary: (json['total_salary'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] ?? '',
      createdBy: json['created_by'] is num ? (json['created_by'] as num).toInt() : null,
      doctorName: doctorMap != null ? (doctorMap['full_name'] ?? '') : '',
      doctorCode: doctorMap != null ? (doctorMap['doctor_code'] ?? '') : '',
      doctorQualification: doctorMap != null ? (doctorMap['qualification'] ?? '') : '',
    );
  }
}

class DoctorSalaryReportItemModel {
  final String doctorId;
  final String doctorCode;
  final String fullName;
  final double totalSalary;
  final double totalHours;
  final int totalShifts;

  DoctorSalaryReportItemModel({
    required this.doctorId,
    required this.doctorCode,
    required this.fullName,
    required this.totalSalary,
    required this.totalHours,
    required this.totalShifts,
  });

  factory DoctorSalaryReportItemModel.fromJson(Map<String, dynamic> json) {
    return DoctorSalaryReportItemModel(
      doctorId: json['doctor_id'] ?? '',
      doctorCode: json['doctor_code'] ?? '',
      fullName: json['full_name'] ?? '',
      totalSalary: (json['total_salary'] as num?)?.toDouble() ?? 0.0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalShifts: json['total_shifts'] is num ? (json['total_shifts'] as num).toInt() : 0,
    );
  }
}

class MonthlySalaryReportModel {
  final int month;
  final int year;
  final List<DoctorSalaryReportItemModel> items;

  MonthlySalaryReportModel({
    required this.month,
    required this.year,
    required this.items,
  });

  factory MonthlySalaryReportModel.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return MonthlySalaryReportModel(
      month: json['month'] is num ? (json['month'] as num).toInt() : 1,
      year: json['year'] is num ? (json['year'] as num).toInt() : 2026,
      items: list.map((e) => DoctorSalaryReportItemModel.fromJson(e)).toList(),
    );
  }
}

class YearlyDoctorSalaryReportItemModel {
  final int month;
  final double totalSalary;
  final double totalHours;
  final int totalShifts;

  YearlyDoctorSalaryReportItemModel({
    required this.month,
    required this.totalSalary,
    required this.totalHours,
    required this.totalShifts,
  });

  factory YearlyDoctorSalaryReportItemModel.fromJson(Map<String, dynamic> json) {
    return YearlyDoctorSalaryReportItemModel(
      month: json['month'] is num ? (json['month'] as num).toInt() : 1,
      totalSalary: (json['total_salary'] as num?)?.toDouble() ?? 0.0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalShifts: json['total_shifts'] is num ? (json['total_shifts'] as num).toInt() : 0,
    );
  }
}

class YearlyDoctorSalaryReportModel {
  final String doctorId;
  final String fullName;
  final int year;
  final List<YearlyDoctorSalaryReportItemModel> months;
  final double totalSalaryYear;
  final double averageSalaryMonth;

  YearlyDoctorSalaryReportModel({
    required this.doctorId,
    required this.fullName,
    required this.year,
    required this.months,
    required this.totalSalaryYear,
    required this.averageSalaryMonth,
  });

  factory YearlyDoctorSalaryReportModel.fromJson(Map<String, dynamic> json) {
    final list = json['months'] as List? ?? [];
    return YearlyDoctorSalaryReportModel(
      doctorId: json['doctor_id'] ?? '',
      fullName: json['full_name'] ?? '',
      year: json['year'] is num ? (json['year'] as num).toInt() : 2026,
      months: list.map((e) => YearlyDoctorSalaryReportItemModel.fromJson(e)).toList(),
      totalSalaryYear: (json['total_salary_year'] as num?)?.toDouble() ?? 0.0,
      averageSalaryMonth: (json['average_salary_month'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class YearlyAllDoctorSalaryReportModel {
  final int year;
  final double totalPool;
  final List<DoctorSalaryReportItemModel> items;

  YearlyAllDoctorSalaryReportModel({
    required this.year,
    required this.totalPool,
    required this.items,
  });

  factory YearlyAllDoctorSalaryReportModel.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return YearlyAllDoctorSalaryReportModel(
      year: json['year'] is num ? (json['year'] as num).toInt() : 2026,
      totalPool: (json['total_pool'] as num?)?.toDouble() ?? 0.0,
      items: list.map((e) => DoctorSalaryReportItemModel.fromJson(e)).toList(),
    );
  }
}
