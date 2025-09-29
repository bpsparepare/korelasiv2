import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _namaLengkapController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    final String namaLengkap = _namaLengkapController.text.trim();
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validasi Input (Tetap sama)
    if (namaLengkap.isEmpty || username.isEmpty || password.isEmpty) {
      _showSnackbar('Semua field harus diisi.', isError: true);
      setState(() { _isLoading = false; });
      return;
    }

    if (password != confirmPassword) {
      _showSnackbar('Password dan Konfirmasi Password tidak cocok.', isError: true);
      setState(() { _isLoading = false; });
      return;
    }

    // --- INI BAGIAN BARUNYA ---
    try {
      final supabase = Supabase.instance.client;

      // 2. Perintah untuk memasukkan data baru ke tabel
      await supabase.from('korelasi_login').insert({
        'nama_lengkap': namaLengkap,
        'username': username,
        'password': password, // Ingat, ini menyimpan password sebagai teks biasa
      });

      // 3. Jika berhasil
      _showSnackbar('Pendaftaran berhasil! Silakan login.');
      if (!mounted) return;
      // Kembali ke halaman login setelah berhasil
      Navigator.pop(context);

    } catch (error) {
      // 4. Jika terjadi error (kemungkinan besar username sudah ada)
      // Kita set kolom username sebagai 'unique' di Supabase,
      // jadi database akan otomatis menolak jika ada duplikat.
      _showSnackbar('Username ini sudah terdaftar. Silakan gunakan username lain.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    // --- AKHIR BAGIAN BARU ---
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bagian UI (build method) tidak perlu diubah sama sekali.
    // Anda bisa menggunakan kode UI Anda yang sudah ada.
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Registrasi Pengguna Baru',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 158, 68),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.person_add_alt_1_outlined,
                size: 100,
                color: Color.fromARGB(255, 255, 158, 68),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _namaLengkapController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() { _isPasswordVisible = !_isPasswordVisible; });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() { _isConfirmPasswordVisible = !_isConfirmPasswordVisible; });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 158, 68),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Daftar'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Kembali ke halaman login
                },
                child: const Text(
                  'Sudah punya akun? Kembali ke Login',
                  style: TextStyle(color: Color.fromARGB(255, 255, 158, 68)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}