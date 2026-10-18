import 'package:flutter/material.dart';
import '../services/pembaruan_aplikasi.dart';
import '../services/sesi_korelasi.dart';

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
    // Beri jeda singkat agar splash screen terlihat, sekaligus cek versi
    final hasil = await Future.wait([
      PembaruanAplikasi.periksa(),
      Future.delayed(const Duration(seconds: 1)),
    ]);
    if (!mounted) return;

    final info = hasil.first as InfoPembaruan?;
    if (info != null && info.wajib) {
      PembaruanAplikasi.bukaLayarWajib(info);
      return;
    }
    if (info != null) {
      await PembaruanAplikasi.tawarkan(context, info);
      if (!mounted) return;
    }

    // Sesi dari Supabase.auth (akun Bolt); SesiKorelasi memindahkan layar ke
    // Login atau Beranda.
    SesiKorelasi.mulai();
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
