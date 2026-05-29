class Patient {
  final int id;
  final String patientCode;
  final String fullName;
  final String gender;
  final String dateOfBirth;
  final String phone;
  final String email;
  final String address;
  final String? avatar;
  final String? bloodType;
  final String? allergies;
  final String? medicalHistory;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool status;
  final DateTime? lastVisit;
  final String? notes;
  Patient({
    required this.id,
    required this.patientCode,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.phone,
    required this.email,
    required this.address,
    this.avatar,
    this.bloodType,
    this.allergies,
    this.medicalHistory,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.status,
    this.lastVisit,
    this.notes,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      patientCode: json['patient_code'],
      fullName: json['full_name'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      avatar: json['avatar'],
      bloodType: json['blood_type'],
      lastVisit: json['last_visit'] != null
          ? DateTime.parse(json['last_visit'])
          : null,
      notes: json['notes'],
      allergies: json['allergies'],
      medicalHistory: json['medical_history'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      status: json['status'] ?? true,
    );
  }
}
