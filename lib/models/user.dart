// lib/models/user.dart

class User {
  final String id;
  final String namaLengkap;
  final String username;
  final String role; // <-- TAMBAHKAN INI

  User({
    required this.id,
    required this.namaLengkap,
    required this.username,
    required this.role, // <-- TAMBAHKAN INI
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '', // Sesuaikan jika nama kolom berbeda
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'username': username,
      'role': role,
    };
  }
}
