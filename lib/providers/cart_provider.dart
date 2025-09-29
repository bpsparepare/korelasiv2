// lib/providers/cart_provider.dart

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  int get totalItemsInCart {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (item.product.harga * item.quantity));
  }

  // BARU: Fungsi yang dibutuhkan oleh HomeScreen
  CartItem? findItemById(String productId) {
    // Menggunakan firstWhereOrNull lebih aman daripada try-catch
    return _items.firstWhereOrNull((item) => item.product.id == productId);
  }

  void addItem(Product product) {
    final existingItem = findItemById(product.id);
    if (existingItem != null) {
      // Jika sudah ada, tambah jumlahnya
      existingItem.quantity++;
    } else {
      // Jika belum ada, tambahkan item baru
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final item = findItemById(productId);
    if (item != null && item.quantity < item.product.stok) {
      item.quantity++;
      notifyListeners();
    }
  }

  void decreaseQuantity(String productId) {
    final item = findItemById(productId);
    if (item != null) {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        // Jika jumlahnya 1, hapus dari keranjang
        _items.removeWhere((cartItem) => cartItem.product.id == productId);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
