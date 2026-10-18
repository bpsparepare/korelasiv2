// lib/main.dart

import 'package:flutter/material.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart'; // <-- Ganti ke sini
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// BARU: Import untuk inisialisasi tanggal
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  // Pastikan semua widget siap sebelum menjalankan aplikasi
  WidgetsFlutterBinding.ensureInitialized();

  // BARU: Inisialisasi locale untuk format tanggal Indonesia
  // Baris ini harus ada sebelum Supabase.initialize atau runApp
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase dengan URL dan kunci publishable (pengganti anon legacy, BOLT-32 Bolt)
  await Supabase.initialize(
    url: 'https://iubeqsafpibmousxvmfk.supabase.co',
    anonKey: 'sb_publishable_4uQyI4wGRTCwXJWMAJD8Rg_fMVc8Dcj',
  );

  runApp(const MyApp());
}

// Membuat helper agar client Supabase mudah diakses di mana saja
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider tetap digunakan untuk state management keranjang
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'KORELASI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange, // Ganti warna agar lebih sesuai
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: Colors.white,
        ),
        // Aplikasi akan selalu dimulai dari Splash Screen untuk memeriksa sesi login
        home: const SplashScreen(), // <-- Ganti ke sini
      ),
    );
  }
}
