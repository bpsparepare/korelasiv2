// lib/services/sesi_korelasi.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart' as app_user;
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

/// Alamat balik login Google di Android, Windows, iOS, dan macOS. Harus
/// terdaftar di Dashboard Supabase › Authentication › URL Configuration ›
/// Redirect URLs. Skemanya dipasang di AndroidManifest.xml, Info.plist, dan
/// windows/runner/main.cpp.
const String alamatBalikLogin = 'korelasi://login-callback';

/// Alamat balik untuk platform yang sedang berjalan. Di web, kembali ke asal
/// halaman (asal itu juga harus ada di daftar Redirect URLs).
String? get alamatBalikPlatform => kIsWeb ? Uri.base.origin : alamatBalikLogin;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Sesi login Korelasi (sejak 2.2.0, BOLT-40).
///
/// Sesi diambil dari `Supabase.auth` (akun Bolt), bukan dari
/// `SharedPreferences`. Sesudah login, baris `korelasi_login` milik akun itu
/// dicari dengan RPC `korelasi_saya()`; akun yang belum ditautkan dikeluarkan
/// lagi. Kelas ini juga yang memindahkan layar ke Login atau Beranda setiap
/// kali status login berubah, termasuk sesudah login Google lewat deep link.
class SesiKorelasi {
  SesiKorelasi._();

  static SupabaseClient get _klien => Supabase.instance.client;

  static app_user.User? _pengguna;
  static StreamSubscription<AuthState>? _langganan;

  /// `auth.users.id` yang barisnya sedang atau sudah dimuat. Mencegah muat
  /// ganda ketika `signedIn` datang lagi untuk akun yang sama (mis. sesudah
  /// [verifikasiSandi]).
  static String? _uidDimuat;

  /// Baris `korelasi_login` pengguna yang sedang login.
  static app_user.User get pengguna {
    final p = _pengguna;
    if (p == null) {
      throw StateError('Belum login. Silakan login kembali.');
    }
    return p;
  }

  static void perbarui(app_user.User pengguna) => _pengguna = pengguna;

  /// Email akun Bolt yang sedang login.
  static String? get email => _klien.auth.currentUser?.email;

  /// Benar bila akun Bolt ini punya sandi (bukan hanya login Google).
  static bool get punyaSandi =>
      _klien.auth.currentUser?.identities?.any((i) => i.provider == 'email') ??
      false;

  /// Dipanggil sekali dari splash: periksa sesi tersimpan, lalu ikuti
  /// perubahan status login.
  static void mulai() {
    if (_langganan != null) return;
    _langganan = _klien.auth.onAuthStateChange.listen(
      _tanganiPerubahan,
      onError: (Object e) => debugPrint('Galat status login: $e'),
    );
    final sesi = _klien.auth.currentSession;
    if (sesi == null) {
      _keLogin();
    } else {
      _masuk(sesi.user);
    }
  }

  static void _tanganiPerubahan(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
        final sesi = data.session;
        if (sesi != null) _masuk(sesi.user);
      case AuthChangeEvent.signedOut:
        _pengguna = null;
        _uidDimuat = null;
        _keLogin();
      default:
        break;
    }
  }

  static Future<void> _masuk(User akun) async {
    if (_uidDimuat == akun.id) return;
    _uidDimuat = akun.id;
    try {
      final baris = await _klien.rpc('korelasi_saya').maybeSingle();
      if (baris == null) {
        _uidDimuat = null;
        _pesan('Akun belum ditautkan ke Korelasi, hubungi admin.');
        await _klien.auth.signOut();
        return;
      }
      _pengguna = app_user.User.fromJson(baris);
      _keBeranda();
    } catch (e) {
      debugPrint('Gagal memuat korelasi_saya: $e');
      _uidDimuat = null;
      _pesan('Gagal memuat akun Korelasi. Periksa koneksi lalu coba lagi.');
      _keLogin();
    }
  }

  /// Memeriksa sandi akun Bolt yang sedang login dengan login ulang.
  static Future<bool> verifikasiSandi(String sandi) async {
    final e = email;
    if (e == null) return false;
    try {
      await _klien.auth.signInWithPassword(email: e, password: sandi);
      return true;
    } on AuthException {
      return false;
    }
  }

  /// Keluar dari akun Bolt; layar pindah ke Login lewat `signedOut`.
  static Future<void> keluar() => _klien.auth.signOut();

  static void _keLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static void _keBeranda() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(user: pengguna)),
      (_) => false,
    );
  }

  static void _pesan(String teks) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(teks), backgroundColor: Colors.red),
    );
  }
}
