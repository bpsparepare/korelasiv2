import 'package:flutter/material.dart';
import 'package:korelasi/screens/home_screen.dart';
import 'package:korelasi/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_user;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Beri jeda singkat agar splash screen terlihat
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // Jika login, ambil data user dari SharedPreferences
      final userId = prefs.getString('userId');
      final namaLengkap = prefs.getString('namaLengkap');
      final username = prefs.getString('username');
      final role = prefs.getString('userRole');

      if (userId != null && namaLengkap != null && username != null && role != null) {
        // Buat kembali objek user
        final user = app_user.User(
          id: userId,
          namaLengkap: namaLengkap,
          username: username,
          role: role,
          password: '', // Password tidak perlu disimpan/dibawa-bawa setelah login
        );
        // Arahkan ke HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
        );
      } else {
        // Jika data user tidak lengkap, arahkan ke LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // Jika tidak login, arahkan ke LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan sederhana untuk Splash Screen
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 158, 68),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_korelasi_fix_300p.png', // Pastikan path logo benar
              width: 150,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
