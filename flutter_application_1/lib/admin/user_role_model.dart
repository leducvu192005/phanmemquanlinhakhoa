class UserRoleModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;

  UserRoleModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  UserRoleModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
  }) {
    return UserRoleModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
