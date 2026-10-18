// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sesi_korelasi.dart';

/// Login dengan akun Bolt: email + sandi, atau Google. Sesudah berhasil,
/// [SesiKorelasi] mencari baris korelasi_login lalu membuka Beranda.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Email dan sandi tidak boleh kosong.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Layar pindah ke Beranda lewat SesiKorelasi (event signedIn).
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      debugPrint('Login Gagal: ${error.message}');
      _showSnackbar(
        error.code == 'invalid_credentials'
            ? 'Email atau sandi salah.'
            : 'Login gagal: ${error.message}',
        isError: true,
      );
    } catch (error) {
      debugPrint('Login Gagal: $error');
      _showSnackbar('Login gagal. Periksa koneksi lalu coba lagi.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Membuka browser; aplikasi kembali lewat alamatBalikLogin dan
      // supabase_flutter menukar kodenya menjadi sesi (event signedIn).
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: alamatBalikPlatform,
      );
    } catch (error) {
      debugPrint('Login Google Gagal: $error');
      _showSnackbar('Gagal membuka login Google.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Selamat Datang',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 158, 68),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/logo_korelasi_fix_300p.png',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 30),
              const Text(
                'Masuk dengan akun Bolt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Sandi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color.fromARGB(255, 255, 158, 68),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(
                    255,
                    255,
                    158,
                    68,
                  ),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Masuk'),
              ),
              const SizedBox(height: 15),
              if (!_isLoading)
                OutlinedButton.icon(
                  onPressed: _loginGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 32),
                  label: const Text('Masuk dengan Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 255, 158, 68),
                    side: const BorderSide(
                      color: Color.fromARGB(255, 255, 158, 68),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Belum punya akun atau lupa sandi? Akun dibuat dan sandi '
                'diatur lewat aplikasi Bolt. Hubungi admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
