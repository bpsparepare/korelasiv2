// lib/models/order_history.dart
import 'package:intl/intl.dart';
import 'history_order_item.dart';

class OrderHistory {
  final String orderId;
  final String orderDate;
  final double totalOrderPrice;
  final List<HistoryOrderItem> items;

  OrderHistory({
    required this.orderId,
    required this.orderDate,
    required this.totalOrderPrice,
    required this.items,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    return OrderHistory(
      orderId: json['id_pesanan']?.toString() ?? '',
      // DIUBAH: Menggunakan huruf kecil
      orderDate: DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(json['tanggal_pesanan'])),
      totalOrderPrice: (json['totalOrderPrice'] as num?)?.toDouble() ?? 0.0,
      items: (json['items'] as List? ?? [])
          .map((itemJson) => HistoryOrderItem.fromJson(itemJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderDate': orderDate,
      'totalOrderPrice': totalOrderPrice,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
