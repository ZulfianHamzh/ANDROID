enum UserRole { admin, kasir }

class AppUser {
  final String id;
  final String username;
  final String name;
  final UserRole role;
  final int? branchId;
  final String? branchName;

  AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.branchId,
    this.branchName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.kasir,
      ),
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'role': role.name,
  };

  bool get isAdmin => role == UserRole.admin;
}
