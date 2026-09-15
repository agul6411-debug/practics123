/// UserAdminModel
/// Data model representing a user account for admin user management.
class UserAdminModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final bool isEmailVerified;
  final String? createdAt;

  UserAdminModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.isEmailVerified = false,
    this.createdAt,
  });

  bool get isDeletionRequested => status.toLowerCase() == 'deletion_pending';

  factory UserAdminModel.fromJson(Map<String, dynamic> json) {
    return UserAdminModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'customer',
      status: json['status'] ?? 'active',
      isEmailVerified: json['is_email_verified'] == 1 || json['is_email_verified'] == true,
      createdAt: json['created_at'],
    );
  }
}

