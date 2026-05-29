class Patient {
  final int id;
  final String patientCode;
  final String fullName;
  final String gender;
  final String phone;
  final String email;
  final String address;
  final bool status;

  Patient({
    required this.id,
    required this.patientCode,
    required this.fullName,
    required this.gender,
    required this.phone,
    required this.email,
    required this.address,
    required this.status,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      patientCode: json['patient_code'] ?? '',
      fullName: json['full_name'] ?? '',
      gender: json['gender'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] == 1 ? true : false,
    );
  }
}
