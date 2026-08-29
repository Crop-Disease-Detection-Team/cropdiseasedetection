class AppUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String role; // 'user' | 'admin'
  final bool isActive;
  final bool emailVerified;
  final String? profilePic;
  final String? createdAt;
  final String? lastLogin;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    this.profilePic,
    this.createdAt,
    this.lastLogin,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? true,
      emailVerified: json['email_verified'] ?? false,
      profilePic: json['profile_pic'],
      createdAt: json['created_at'],
      lastLogin: json['last_login'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'role': role,
        'is_active': isActive,
        'email_verified': emailVerified,
        'profile_pic': profilePic,
        'created_at': createdAt,
        'last_login': lastLogin,
      };
}
