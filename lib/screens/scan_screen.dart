// lib/screens/scan_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '/models/product.dart';
import 'package:provider/provider.dart';
import '/providers/cart_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController();
  final supabase = Supabase.instance.client;
  bool _isProcessing = false;
  final currencyFormatter = NumberFormat.decimalPattern('id_ID');

  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });
    _animationController.stop();

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) {
      setState(() {
        _isProcessing = false;
      });
      _animationController.repeat(reverse: true);
      return;
    }

    final String scannedId = barcodes.first.rawValue!;
    debugPrint('Barcode ditemukan: $scannedId');

    try {
      final response = await supabase
          .from('korelasi_master_produk')
          .select()
          .eq('id_produk', scannedId)
          .single();

      final product = Product.fromJson(response);
      await _cameraController.stop();
      if (mounted) _showProductDialog(product);
    } catch (e) {
      debugPrint('Produk tidak ditemukan: $e');
      await _cameraController.stop();
      if (mounted) _showNotFoundDialog();
    }
  }

  void _showProductDialog(Product product) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.gambarUrl,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.error, size: 50),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Stok', style: TextStyle(color: Colors.grey)),
                        Text(product.stok.toString(),
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Harga',
                            style: TextStyle(color: Colors.grey)),
                        Text(
                            'Rp ${currencyFormatter.format(product.harga)}',
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        child: const Text('Tutup'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          setState(() {
                            _isProcessing = false;
                          });
                          _cameraController.start();
                          _animationController.repeat(reverse: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: product.stok > 0
                            ? () {
                          cart.addItem(product);
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pop(true);
                        }
                            : null,
                        child: const Text('Tambah'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          icon: Icon(Icons.search_off,
              color: Colors.orange.shade700, size: 48),
          title: const Text('Produk Tidak Ditemukan',
              textAlign: TextAlign.center),
          content: const Text(
            'Barcode tidak terdaftar di database atau stok produk habis.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Scan Ulang'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _isProcessing = false;
                });
                _cameraController.start();
                _animationController.repeat(reverse: true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    // Definisikan area pindai di tengah layar
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(const Offset(0, -50)),
      width: MediaQuery.of(context).size.width * 0.7,
      height: 200,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Produk', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
            scanWindow: scanWindow,
          ),

          // Overlay putih dengan lubang
          ClipPath(
            clipper: InvertedRectClipper(scanWindow: scanWindow),
            child: Container(
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          // Teks petunjuk tepat di atas area scan
          Positioned(
            left: 0,
            right: 0,
            top: scanWindow.top - 56,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Arahkan kamera ke barcode produk',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Area animasi garis scanner
          Positioned.fromRect(
            rect: scanWindow,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    const double lineThickness = 2.0;
                    const double vPad = 6.0; // padding agar tidak mentok sudut
                    final double travelHeight =
                        scanWindow.height - lineThickness - (vPad * 2);

                    return Positioned(
                      top: vPad + _scanAnimation.value * travelHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: lineThickness,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.5),
                              blurRadius: 8.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Mencari produk...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom Clipper untuk membuat lubang pada overlay
class InvertedRectClipper extends CustomClipper<Path> {
  final Rect scanWindow;
  InvertedRectClipper({required this.scanWindow});

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        scanWindow,
        const Radius.circular(20),
      ))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
