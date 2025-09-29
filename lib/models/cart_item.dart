// lib/models/cart_item.dart
import 'product.dart'; // Import model Product

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // Untuk persistensi menggunakan shared_preferences
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(), // Pastikan Product juga memiliki toJson()
      'quantity': quantity,
    };
  }

  // Untuk memuat dari shared_preferences
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] as int,
    );
  }
}
