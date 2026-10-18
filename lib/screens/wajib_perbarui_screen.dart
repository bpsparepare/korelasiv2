// lib/screens/wajib_perbarui_screen.dart

import 'package:flutter/material.dart';

import '../services/pembaruan_aplikasi.dart';
import '../services/sesi_korelasi.dart';

/// Layar penutup bila versi terpasang wajib diperbarui. Tidak ada jalan
/// kembali selain memasang versi baru (atau rilis wajibnya dicabut di server).
class WajibPerbaruiScreen extends StatefulWidget {
  final InfoPembaruan info;
  const WajibPerbaruiScreen({super.key, required this.info});

  @override
  State<WajibPerbaruiScreen> createState() => _WajibPerbaruiScreenState();
}

class _WajibPerbaruiScreenState extends State<WajibPerbaruiScreen> {
  bool _memeriksa = false;

  Future<void> _periksaLagi() async {
    setState(() => _memeriksa = true);
    final info = await PembaruanAplikasi.periksa();
    if (!mounted) return;
    setState(() => _memeriksa = false);
    if (info == null || !info.wajib) {
      PembaruanAplikasi.selesaiWajib();
      SesiKorelasi.lanjutkan();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Versi ini masih harus diperbarui.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color.fromARGB(255, 255, 158, 68);
    final info = widget.info;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo_korelasi_fix_300p.png',
                      width: 120),
                  const SizedBox(height: 24),
                  const Text(
                    'Korelasi perlu diperbarui',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Versi ${info.versiTerpasang} tidak bisa dipakai lagi. '
                    'Pasang versi ${info.versi} untuk melanjutkan.',
                    textAlign: TextAlign.center,
                  ),
                  if (info.catatan != null && info.catatan!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(info.catatan!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                  const SizedBox(height: 24),
                  if (info.tautan != null)
                    FilledButton.icon(
                      onPressed: () =>
                          PembaruanAplikasi.bukaTautan(info.tautan!),
                      icon: const Icon(Icons.download),
                      label: Text('Unduh versi ${info.versi}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                    )
                  else
                    const Text('Minta berkas versi baru kepada admin.',
                        textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _memeriksa ? null : _periksaLagi,
                    child: _memeriksa
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Periksa lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
