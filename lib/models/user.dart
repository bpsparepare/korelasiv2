// lib/models/user.dart

/// Baris `korelasi_login` milik pengguna (tanpa kolom `password`).
///
/// Sejak 2.2.0 login memakai akun Bolt (Supabase Auth); baris ini dicari lewat
/// `korelasi_login.auth_user_id` dengan RPC `korelasi_saya()`. `id` tetap
/// dipakai sebagai `id_pelanggan` pesanan.
class User {
  final String id;
  final String namaLengkap;
  final String username;
  final String role;

  User({
    required this.id,
    required this.namaLengkap,
    required this.username,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? 'Tanpa Nama',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  bool get isAdmin => role == 'admin';

  User copyWith({String? namaLengkap, String? username}) {
    return User(
      id: id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      username: username ?? this.username,
      role: role,
    );
  }
}
