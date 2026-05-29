import 'dart:convert';

class Doctor {
  final String id;

  final String doctorCode;

  final String fullName;

  final String? gender;

  final String? dateOfBirth;

  final String phone;

  final String email;

  final String? avatar;

  final String? specialty;

  final String? qualification;

  final int? experienceYears;

  final String? address;

  final String? bio;

  final bool status;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  Doctor({
    required this.id,
    required this.doctorCode,
    required this.fullName,
    this.gender,
    this.dateOfBirth,
    required this.phone,
    required this.email,
    this.avatar,
    this.specialty,
    this.qualification,
    this.experienceYears,
    this.address,
    this.bio,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'].toString(),

      doctorCode: json['doctor_code'] ?? '',

      fullName: json['full_name'] ?? '',

      gender: json['gender'],

      dateOfBirth: json['date_of_birth'],

      phone: json['phone'] ?? '',

      email: json['email'] ?? '',

      avatar: json['avatar'],

      specialty: json['specialty'],

      qualification: json['qualification'],

      experienceYears: json['experience_years'],

      address: json['address'],

      bio: json['bio'],

      status: json['status'] ?? true,

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,

      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'doctor_code': doctorCode,

      'full_name': fullName,

      'gender': gender,

      'date_of_birth': dateOfBirth,

      'phone': phone,

      'email': email,

      'avatar': avatar,

      'specialty': specialty,

      'qualification': qualification,

      'experience_years': experienceYears,

      'address': address,

      'bio': bio,

      'status': status,

      'created_at': createdAt?.toIso8601String(),

      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Doctor copyWith({
    String? id,
    String? doctorCode,
    String? fullName,
    String? gender,
    String? dateOfBirth,
    String? phone,
    String? email,
    String? avatar,
    String? specialty,
    String? qualification,
    int? experienceYears,
    String? address,
    String? bio,
    bool? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Doctor(
      id: id ?? this.id,

      doctorCode: doctorCode ?? this.doctorCode,

      fullName: fullName ?? this.fullName,

      gender: gender ?? this.gender,

      dateOfBirth: dateOfBirth ?? this.dateOfBirth,

      phone: phone ?? this.phone,

      email: email ?? this.email,

      avatar: avatar ?? this.avatar,

      specialty: specialty ?? this.specialty,

      qualification: qualification ?? this.qualification,

      experienceYears: experienceYears ?? this.experienceYears,

      address: address ?? this.address,

      bio: bio ?? this.bio,

      status: status ?? this.status,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension on JsonCodec {
  String? operator [](String other) {}
}
