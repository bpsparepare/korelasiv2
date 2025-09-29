// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '/models/user.dart' as app_user;
import '/screens/edit_profile_screen.dart';
import '/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final app_user.User user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late app_user.User currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push<app_user.User>(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: currentUser)),
    );

    if (result != null) {
      setState(() {
        currentUser = result;
      });
    }
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final supabase = Supabase.instance.client;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ganti Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password Lama'),
                      validator: (value) => value!.isEmpty ? 'Password lama tidak boleh kosong' : null,
                    ),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password Baru'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password baru tidak boleh kosong';
                        if (value.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
                      validator: (value) => value != newPasswordController.text ? 'Password tidak cocok' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                FilledButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSaving = true);
                      try {
                        final response = await supabase
                            .from('korelasi_login')
                            .select('password')
                            .eq('id', currentUser.id)
                            .single();

                        final currentPassword = response['password'];

                        if (currentPassword != oldPasswordController.text) {
                          throw Exception('Password lama salah!');
                        }

                        await supabase
                            .from('korelasi_login')
                            .update({'password': newPasswordController.text})
                            .eq('id', currentUser.id);

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password berhasil diubah!'), backgroundColor: Colors.green),
                        );

                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
                        );
                      } finally {
                        setDialogState(() => isSaving = false);
                      }
                    }
                  },
                  child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // --- PERBAIKAN DI SINI ---
      // Menggunakan ListView agar konten bisa di-scroll jika tidak muat
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor,
                  child: Text(
                    currentUser.namaLengkap.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  currentUser.namaLengkap,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  '@${currentUser.username}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit Profil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _navigateToEditProfile,
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Ganti Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                ),
              ],
            ),
          ),
          // Hapus Spacer karena ListView sudah menangani scrolling
          // const Spacer(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0), // Padding seragam
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // --- AKHIR PERBAIKAN ---
    );
  }
}
