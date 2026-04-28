import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final String? phone;
  final String? cedula;
  final String roleId;
  final String? roleName;
  final bool isActive;
  final bool mustChangePassword;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    this.cedula,
    required this.roleId,
    this.roleName,
    this.isActive = true,
    this.mustChangePassword = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      cedula: json['cedula'],
      roleId: json['role_id'],
      roleName: json['roles']?['name'] ?? json['role_name'],
      isActive: json['is_active'] ?? true,
      mustChangePassword: json['must_change_password'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'cedula': cedula,
      'role_id': roleId,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? cedula,
    String? roleId,
    String? roleName,
    bool? isActive,
    bool? mustChangePassword,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      cedula: cedula ?? this.cedula,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        cedula,
        roleId,
        roleName,
        isActive,
        mustChangePassword,
      ];
}
