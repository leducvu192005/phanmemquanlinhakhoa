class Patient {
  final int id;

  final String fullName;

  final String email;

  final String phone;

  final bool status;

  Patient({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json["id"],

      fullName: json["full_name"],

      email: json["email"],

      phone: json["phone"],

      status: json["status"],
    );
  }
}
