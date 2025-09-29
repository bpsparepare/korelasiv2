// lib/models/history_order_item.dart

class HistoryOrderItem {
  final String productId;
  final String productName;
  final String gambarUrl;
  final double harga;
  final int jumlah;
  final double subtotal;
  final String satuan;

  HistoryOrderItem({
    required this.productId,
    required this.productName,
    required this.gambarUrl,
    required this.harga,
    required this.jumlah,
    required this.subtotal,
    required this.satuan,
  });

  // DIUBAH: Disesuaikan untuk membaca data join dari Supabase
  factory HistoryOrderItem.fromJson(Map<String, dynamic> json) {
    // Data dari tabel 'korelasi_master_produk' akan berada di dalam map 'korelasi_master_produk'
    final productData = json['korelasi_master_produk'] as Map<String, dynamic>? ?? {};

    return HistoryOrderItem(
      productId: json['id_produk']?.toString() ?? '',
      // Ambil nama produk dari data join jika ada, jika tidak, coba dari data pesanan
      productName: productData['nama_produk']?.toString() ?? 'Produk Dihapus',
      gambarUrl: productData['gambar_url']?.toString() ?? 'https://placehold.co/150x150?text=No+Image',
      harga: (json['harga'] as num?)?.toDouble() ?? 0.0,
      jumlah: (json['jumlah'] as int?) ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      satuan: productData['satuan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'gambarUrl': gambarUrl,
      'harga': harga,
      'jumlah': jumlah,
      'subtotal': subtotal,
      'satuan': satuan,
    };
  }
}
