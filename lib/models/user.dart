// lib/models/user.dart

class User {
  final String id;
  final String namaLengkap;
  final String username;
  final String password; // PENTING: Tambahkan properti password
  final String role;

  User({
    required this.id,
    required this.namaLengkap,
    required this.username,
    required this.password, // PENTING
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? 'Tanpa Nama',
      username: json['username'] ?? '',
      password: json['password'] ?? '', // PENTING: Baca password dari data
      role: json['role'] ?? 'user',
    );
  }

  // toJson tidak wajib untuk fitur ini, tapi baik untuk kelengkapan
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'username': username,
      'password': password,
      'role': role,
    };
  }
}

