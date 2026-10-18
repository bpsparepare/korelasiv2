// lib/services/pembaruan_aplikasi.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/wajib_perbarui_screen.dart';
import 'sesi_korelasi.dart';

/// Versi yang lebih baru dari yang terpasang.
class InfoPembaruan {
  final String versi;
  final int nomorBuild;
  final String versiTerpasang;

  /// Benar bila ada rilis di atas versi terpasang yang `force_update`: versi
  /// ini tidak boleh dipakai lagi.
  final bool wajib;
  final String? tautan;
  final String? catatan;

  const InfoPembaruan({
    required this.versi,
    required this.nomorBuild,
    required this.versiTerpasang,
    required this.wajib,
    this.tautan,
    this.catatan,
  });
}

/// Cek versi dari tabel `korelasi_versions` (satu baris per rilis, seperti
/// `bolt_versions` di Bolt).
///
/// - Ada baris dengan `build_number` lebih besar → tawarkan pembaruan.
/// - Salah satu baris itu `force_update` → wajib, aplikasi tidak bisa dipakai
///   sampai diperbarui.
/// - Gagal membaca (offline, tabel belum ada) → dianggap tidak ada pembaruan.
///   Keamanan data tetap dijaga server (RLS), cek ini hanya untuk pengguna.
class PembaruanAplikasi with WidgetsBindingObserver {
  PembaruanAplikasi._();

  static final PembaruanAplikasi _instans = PembaruanAplikasi._();
  static DateTime? _terakhirDiperiksa;
  static bool _sedangWajib = false;

  /// Jarak minimal antar-pemeriksaan saat aplikasi kembali dibuka.
  static const Duration _jedaPeriksa = Duration(hours: 1);

  /// Mulai memeriksa lagi setiap kali aplikasi kembali ke depan.
  static void pantau() {
    WidgetsBinding.instance.addObserver(_instans);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _sedangWajib) return;
    final terakhir = _terakhirDiperiksa;
    if (terakhir != null &&
        DateTime.now().difference(terakhir) < _jedaPeriksa) {
      return;
    }
    periksa().then((info) {
      if (info != null && info.wajib) bukaLayarWajib(info);
    });
  }

  static Future<InfoPembaruan?> periksa() async {
    if (kIsWeb) return null; // web selalu memuat versi terbaru dari server
    _terakhirDiperiksa = DateTime.now();
    try {
      final paket = await PackageInfo.fromPlatform();
      final buildTerpasang = nomorBuild(
          paket.buildNumber, paket.version, defaultTargetPlatform);
      if (buildTerpasang == null) return null;

      final List<dynamic> baris = await Supabase.instance.client
          .from('korelasi_versions')
          .select(
              'version, build_number, force_update, android_url, windows_url, ios_url, download_url, release_notes')
          .gt('build_number', buildTerpasang)
          .order('build_number', ascending: false);
      if (baris.isEmpty) return null;

      final terbaru = baris.first as Map<String, dynamic>;
      return InfoPembaruan(
        versi: '${terbaru['version']}',
        nomorBuild: terbaru['build_number'] as int,
        versiTerpasang: '${paket.version}+$buildTerpasang',
        wajib: baris.any((b) => (b as Map)['force_update'] == true),
        tautan: pilihTautan(terbaru, defaultTargetPlatform),
        catatan: terbaru['release_notes'] as String?,
      );
    } catch (e) {
      debugPrint('Cek pembaruan dilewati: $e');
      return null;
    }
  }

  /// Nomor build (angka sesudah `+` di pubspec) dari versi terpasang.
  ///
  /// APK `--split-per-abi` memakai versionCode `kodeAbi * 1000 + build`
  /// (arm64-v8a 2.2.0+4 → 2004, armeabi-v7a → 1004), jadi di Android
  /// diambil sisa bagi 1000. Nomor build harus tetap di bawah 1000.
  @visibleForTesting
  static int? nomorBuild(
      String buildNumber, String version, TargetPlatform platform) {
    var build = int.tryParse(buildNumber);
    if (build == null) {
      final bagian = version.split('+');
      build = bagian.length == 2 ? int.tryParse(bagian[1]) : null;
    }
    if (build != null && platform == TargetPlatform.android) {
      build = build % 1000;
    }
    return build;
  }

  /// Tautan unduh untuk [platform]; kolom kosong jatuh ke `download_url`.
  @visibleForTesting
  static String? pilihTautan(
      Map<String, dynamic> baris, TargetPlatform platform) {
    String? kolom;
    switch (platform) {
      case TargetPlatform.android:
        kolom = baris['android_url'] as String?;
      case TargetPlatform.windows:
        kolom = baris['windows_url'] as String?;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        kolom = baris['ios_url'] as String?;
      default:
        break;
    }
    final tautan = (kolom == null || kolom.isEmpty)
        ? baris['download_url'] as String?
        : kolom;
    return (tautan == null || tautan.isEmpty) ? null : tautan;
  }

  static Future<bool> bukaTautan(String tautan) {
    return launchUrl(Uri.parse(tautan), mode: LaunchMode.externalApplication);
  }

  /// Ganti semua layar dengan layar "wajib perbarui".
  static void bukaLayarWajib(InfoPembaruan info) {
    _sedangWajib = true;
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => WajibPerbaruiScreen(info: info)),
      (_) => false,
    );
  }

  static bool get sedangWajib => _sedangWajib;

  /// Dipanggil layar wajib bila pemeriksaan ulang tidak lagi mewajibkan.
  static void selesaiWajib() => _sedangWajib = false;

  /// Dialog pembaruan yang boleh ditunda.
  static Future<void> tawarkan(BuildContext context, InfoPembaruan info) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Versi baru ${info.versi}'),
        content: SingleChildScrollView(
          child: Text(
            [
              'Terpasang: ${info.versiTerpasang}.',
              if (info.catatan != null && info.catatan!.isNotEmpty)
                info.catatan!,
            ].join('\n\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Nanti'),
          ),
          if (info.tautan != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                bukaTautan(info.tautan!);
              },
              child: const Text('Unduh'),
            ),
        ],
      ),
    );
  }
}
