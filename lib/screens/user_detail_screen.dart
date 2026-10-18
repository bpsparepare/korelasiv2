// lib/screens/user_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:korelasi/models/user.dart' as app_user;

/// Detail pengguna Korelasi untuk admin. Sandi tidak lagi ditampilkan: sejak
/// 2.2.0 login memakai akun Bolt dan sandi dikelola Supabase Auth.
class UserDetailScreen extends StatelessWidget {
  final app_user.User user;
  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.namaLengkap, style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDetailCard('ID Pengguna', user.id),
          _buildDetailCard('Nama Lengkap', user.namaLengkap),
          _buildDetailCard('Username', user.username),
          _buildDetailCard('Peran', user.role),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.grey.shade600)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}
