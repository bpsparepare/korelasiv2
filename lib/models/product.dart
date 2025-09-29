// lib/models/product.dart

class Product {
  final String id;
  final String nama;
  final String gambarUrl;
  final int stok;
  final double harga;
  final String satuan;
  final String kategori;

  Product({
    required this.id,
    required this.nama,
    required this.gambarUrl,
    required this.stok,
    required this.harga,
    required this.satuan,
    required this.kategori,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final dynamic hargaValue = json['harga'];
    double parsedHarga = 0.0;

    if (hargaValue is num) {
      parsedHarga = hargaValue.toDouble();
    } else if (hargaValue is String) {
      parsedHarga = double.tryParse(hargaValue.replaceAll('.', '')) ?? 0.0;
    }

    return Product(
      // --- PERBAIKAN DI SINI ---
      // Mengambil data dari kolom 'id_produk' bukan 'id'
      id: json['id_produk'] ?? '',
      // --------------------------

      nama: json['nama_produk'] ?? 'Tanpa Nama',
      gambarUrl: json['gambar_url'] ?? 'https://placehold.co/150x150?text=No+Image',
      stok: (json['stok'] as int?) ?? 0,
      harga: parsedHarga,
      satuan: json['satuan'] ?? '',
      kategori: json['kategori'] ?? 'Lain-lain',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_produk': id, // Disesuaikan juga di sini untuk konsistensi
      'nama_produk': nama,
      'gambar_url': gambarUrl,
      'stok': stok,
      'harga': harga,
      'satuan': satuan,
      'kategori': kategori,
    };
  }
}
