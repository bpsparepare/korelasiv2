// lib/screens/user_detail_screen.dart
// lib/screens/user_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:korelasi/models/user.dart' as app_user;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDetailScreen extends StatefulWidget {
  final app_user.User user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isPasswordVisible = false;
  final supabase = Supabase.instance.client;

  Future<void> _showAdminPasswordDialog() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? passwordConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verifikasi Admin'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Untuk melihat password, masukkan password admin Anda.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Admin',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final adminPassword = passwordController.text;
                  final prefs = await SharedPreferences.getInstance();
                  final adminId = prefs.getString('userId');

                  // PERBAIKAN: Cek jika adminId null sebelum query
                  if (adminId == null) {
                    Navigator.pop(context, false);
                    return;
                  }

                  try {
                    final response = await supabase
                        .from('korelasi_login')
                        .select('password')
                        .eq('id', adminId) // Sekarang aman digunakan
                        .single();

                    if (response['password'] == adminPassword) {
                      Navigator.pop(context, true); // Password benar
                    } else {
                      Navigator.pop(context, false); // Password salah
                    }
                  } catch (e) {
                    Navigator.pop(context, false); // Gagal verifikasi
                  }
                }
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );

    if (passwordConfirmed == true) {
      setState(() {
        _isPasswordVisible = true;
      });
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifikasi gagal. Password admin salah.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.namaLengkap, style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDetailCard('ID Pengguna', widget.user.id),
          _buildDetailCard('Nama Lengkap', widget.user.namaLengkap),
          _buildDetailCard('Username', widget.user.username),
          _buildPasswordCard(),
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

  Widget _buildPasswordCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Password', style: TextStyle(color: Colors.grey.shade600)),
        subtitle: Text(
          // PERBAIKAN: Sekarang bisa mengakses widget.user.password
          _isPasswordVisible ? widget.user.password : '••••••••',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        trailing: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            if (_isPasswordVisible) {
              setState(() {
                _isPasswordVisible = false;
              });
            } else {
              _showAdminPasswordDialog();
            }
          },
        ),
      ),
    );
  }
}
