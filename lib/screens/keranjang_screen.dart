// lib/screens/keranjang_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // BARU: Import untuk format angka
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../providers/cart_provider.dart';
import '../models/cart_item.dart';

class KeranjangScreen extends StatefulWidget {
  final VoidCallback onCheckoutSuccess;
  const KeranjangScreen({super.key, required this.onCheckoutSuccess});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  bool _isCheckingOut = false;
  final supabase = Supabase.instance.client;
  // BARU: Formatter untuk harga
  final currencyFormatter = NumberFormat.decimalPattern('id_ID');

  Future<void> _showConfirmationDialog() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang Anda kosong.')),
      );
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembelian'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Anda akan membeli ${cart.totalItemsInCart} jenis barang.'),
                // DIUBAH: Menggunakan formatter
                Text('Total: Rp ${currencyFormatter.format(cart.totalPrice)}'),
                const SizedBox(height: 10),
                const Text('Lanjutkan pembayaran?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton(
              child: const Text('Ya, Beli'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleCheckout(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCheckout(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    setState(() {
      _isCheckingOut = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('userId');
      final customerName = prefs.getString('namaLengkap');

      if (customerId == null || customerName == null) {
        throw Exception('Informasi pelanggan tidak ditemukan.');
      }

      const uuid = Uuid();
      final orderId = uuid.v4();
      final orderTimestamp = DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> orderItemsToInsert = [];
      for (var item in cart.items) {
        orderItemsToInsert.add({
          'id_pesanan': orderId,
          'id_pelanggan': customerId,
          'nama_pembeli': customerName,
          'tanggal_pesanan': orderTimestamp,
          'id_produk': item.product.id,
          'nama_produk': item.product.nama,
          'harga': item.product.harga,
          'jumlah': item.quantity,
          'subtotal': item.product.harga * item.quantity,
          'satuan': item.product.satuan,
        });
      }

      await supabase.from('korelasi_data_pesanan').insert(orderItemsToInsert);

      for (var item in cart.items) {
        await supabase.rpc('update_stock', params: {
          'product_id_to_update': item.product.id,
          'quantity_to_decrease': item.quantity,
        });
      }

      cart.clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembelian berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCheckoutSuccess();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);
    final cart = Provider.of<CartProvider>(context);

    return Column(
      children: [
        Expanded(
          child: cart.items.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                const Text('Keranjang Anda kosong.', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final CartItem item = cart.items[index];
              final bool canIncreaseQuantity = item.quantity < item.product.stok;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.gambarUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                    ),
                  ),
                  title: Text(item.product.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // DIUBAH: Menggunakan formatter
                  subtitle: Text('Rp ${currencyFormatter.format(item.product.harga)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => cart.decreaseQuantity(item.product.id),
                      ),
                      Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: canIncreaseQuantity ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        onPressed: canIncreaseQuantity
                            ? () => cart.increaseQuantity(item.product.id)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      // DIUBAH: Menggunakan formatter
                      'Rp ${currencyFormatter.format(cart.totalPrice)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isCheckingOut ? null : _showConfirmationDialog,
                  icon: _isCheckingOut
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                      : const Icon(Icons.payment),
                  label: Text(_isCheckingOut ? 'Memproses...' : 'Beli'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
