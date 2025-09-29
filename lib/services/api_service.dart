// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order_history.dart';
import 'dart:developer' as developer;

class ApiService {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbwJZhBbmJ-Z71ldKkvdyMk1uNKtctqKAtu0iOLgp3y2FchNyXBxi4G3joVmxX7clc-R/exec'; // Pastikan ini URL /exec Anda!
  static const String _productsCacheKey =
      'cached_products'; // Kunci untuk cache produk
  static const String _orderHistoryCacheKeyPrefix =
      'cached_order_history_'; // Kunci untuk cache riwayat pesanan (ditambah customer ID)

  // Metode untuk menyimpan daftar produk ke cache
  Future<void> _saveProductsToCache(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String productsJson = json.encode(
        products.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_productsCacheKey, productsJson);
      developer.log('Products saved to cache.');
    } catch (e) {
      developer.log('Error saving products to cache: $e');
    }
  }

  // Metode untuk memuat daftar produk dari cache
  Future<List<Product>?> _loadProductsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? productsJson = prefs.getString(_productsCacheKey);
      if (productsJson != null) {
        final List<dynamic> decodedJson = json.decode(productsJson);
        final List<Product> cachedProducts =
            decodedJson.map((item) => Product.fromJson(item)).toList();
        developer.log(
          'Products loaded from cache: ${cachedProducts.length} items.',
        );
        return cachedProducts;
      }
    } catch (e) {
      developer.log('Error loading products from cache: $e');
    }
    return null;
  }

  // Metode untuk menyimpan riwayat pesanan ke cache (spesifik per pengguna)
  Future<void> _saveOrderHistoryToCache(
    String customerId,
    List<OrderHistory> orders,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String ordersJson = json.encode(
        orders.map((o) => o.toJson()).toList(),
      );
      await prefs.setString(
        '$_orderHistoryCacheKeyPrefix$customerId',
        ordersJson,
      );
      developer.log('Order history saved to cache for customer $customerId.');
    } catch (e) {
      developer.log('Error saving order history to cache: $e');
    }
  }

  // Metode untuk memuat riwayat pesanan dari cache (spesifik per pengguna)
  Future<List<OrderHistory>?> _loadOrderHistoryFromCache(
    String customerId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ordersJson = prefs.getString(
        '$_orderHistoryCacheKeyPrefix$customerId',
      );
      if (ordersJson != null) {
        final List<dynamic> decodedJson = json.decode(ordersJson);
        final List<OrderHistory> cachedOrders =
            decodedJson.map((item) => OrderHistory.fromJson(item)).toList();
        developer.log(
          'Order history loaded from cache for customer $customerId: ${cachedOrders.length} orders.',
        );
        return cachedOrders;
      }
    } catch (e) {
      developer.log('Error loading order history from cache: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=checkUsername&username=$username'),
      );
      return _handleResponse(response);
    } catch (e) {
      developer.log('API Error in checkUsername: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?action=login&username=$username&password=$password',
        ),
      );
      return _handleResponse(response);
    } catch (e) {
      developer.log('API Error in login: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String namaLengkap,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'register',
          'namaLengkap': namaLengkap,
          'username': username,
          'password': password,
        },
      );
      return _handleResponse(response);
    } catch (e) {
      developer.log('API Error in register: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // Fungsi untuk mengambil semua produk (GET Request)
  // Menambahkan parameter forceRefresh
  Future<List<Product>> getAllProducts({bool forceRefresh = false}) async {
    // Jika forceRefresh true, langsung ambil dari jaringan
    if (forceRefresh) {
      developer.log('Forcing refresh of products from network.');
      return _fetchAndCacheLatestProducts();
    }

    // 1. Coba muat dari cache terlebih dahulu
    final List<Product>? cachedProducts = await _loadProductsFromCache();
    if (cachedProducts != null && cachedProducts.isNotEmpty) {
      developer.log('Returning cached products.');
      // Jika ada data di cache, kembalikan data cache dengan cepat
      // dan kemudian secara asinkron muat data terbaru dari jaringan
      // untuk memperbarui cache di latar belakang.
      _fetchAndCacheLatestProducts(); // Jangan tunggu hasil ini
      return cachedProducts;
    }

    // 2. Jika tidak ada cache atau cache kosong, muat dari jaringan
    developer.log('No cache found, fetching products from network.');
    return _fetchAndCacheLatestProducts();
  }

  // Metode terpisah untuk mengambil data terbaru dari jaringan dan menyimpannya ke cache
  Future<List<Product>> _fetchAndCacheLatestProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getAllProducts'),
      );
      final Map<String, dynamic> data = _handleResponse(response);

      if (data['status'] == 'success' && data['products'] != null) {
        List<Product> parsedProducts = [];
        for (var jsonItem in data['products']) {
          try {
            parsedProducts.add(Product.fromJson(jsonItem));
          } catch (e) {
            developer.log(
              'Product parsing error for item: $jsonItem, Error: $e',
            );
          }
        }
        // Simpan data terbaru ke cache
        _saveProductsToCache(parsedProducts);
        return parsedProducts;
      } else {
        developer.log(
          'Failed to fetch products from network: ${data['message']}',
        );
        return [];
      }
    } catch (e) {
      developer.log(
        'API Error in _fetchAndCacheLatestProducts (network/general): $e',
      );
      return [];
    }
  }

  Future<List<String>> getUniqueCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getUniqueCategories'),
      );
      final Map<String, dynamic> data = _handleResponse(response);

      if (data['status'] == 'success' && data['categories'] != null) {
        return (data['categories'] as List).map((e) => e.toString()).toList();
      } else {
        developer.log('Failed to fetch categories: ${data['message']}');
        return [];
      }
    } catch (e) {
      developer.log('API Error in getUniqueCategories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> placeOrder({
    required String customerId,
    required String customerName,
    required List<CartItem> orderItems,
  }) async {
    final List<Map<String, dynamic>> itemsToSend =
        orderItems
            .map(
              (item) => {
                'productId': item.product.id,
                'productName': item.product.nama,
                'jumlah': item.quantity,
                'harga': item.product.harga,
              },
            )
            .toList();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'placeOrder',
          'customerId': customerId,
          'customerName': customerName,
          'orderItems': json.encode(itemsToSend),
        },
      );
      // Setelah order berhasil, muat ulang cache produk dan riwayat pesanan (jika ada customerId)
      _fetchAndCacheLatestProducts(); // Refresh cache produk setelah stok berubah
      if (customerId.isNotEmpty) {
        _fetchAndCacheLatestOrderHistory(
          customerId,
        ); // Refresh cache riwayat pesanan
      }
      return _handleResponse(response);
    } catch (e) {
      developer.log('API Error in placeOrder: $e');
      return {
        'status': 'error',
        'message': 'Network error during order placement: $e',
      };
    }
  }

  // Fungsi untuk mendapatkan riwayat pesanan (dengan dukungan cache)
  Future<List<OrderHistory>> getOrderHistory(
    String customerId, {
    bool forceRefresh = false,
  }) async {
    // Jika forceRefresh true, langsung ambil dari jaringan
    if (forceRefresh) {
      developer.log('Forcing refresh of order history from network.');
      return _fetchAndCacheLatestOrderHistory(customerId);
    }

    // 1. Coba muat dari cache terlebih dahulu
    final List<OrderHistory>? cachedOrders = await _loadOrderHistoryFromCache(
      customerId,
    );
    if (cachedOrders != null && cachedOrders.isNotEmpty) {
      developer.log('Returning cached order history.');
      _fetchAndCacheLatestOrderHistory(
        customerId,
      ); // Muat ulang di latar belakang
      return cachedOrders;
    }
    // 2. Jika tidak ada cache, muat dari jaringan
    developer.log('No cached order history found, fetching from network.');
    return _fetchAndCacheLatestOrderHistory(customerId);
  }

  // Metode terpisah untuk mengambil riwayat pesanan terbaru dari jaringan dan menyimpannya ke cache
  Future<List<OrderHistory>> _fetchAndCacheLatestOrderHistory(
    String customerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getOrderHistory&customerId=$customerId'),
      );
      final Map<String, dynamic> data = _handleResponse(response);

      if (data['status'] == 'success' && data['orders'] != null) {
        List<OrderHistory> parsedOrders = [];
        for (var jsonItem in data['orders']) {
          try {
            parsedOrders.add(OrderHistory.fromJson(jsonItem));
          } catch (e) {
            developer.log(
              'Order History parsing error for order: $jsonItem, Error: $e',
            );
          }
        }
        _saveOrderHistoryToCache(customerId, parsedOrders); // Simpan ke cache
        return parsedOrders;
      } else {
        developer.log(
          'Failed to fetch order history from network: ${data['message']}',
        );
        return [];
      }
    } catch (e) {
      developer.log(
        'API Error in _fetchAndCacheLatestOrderHistory (network/general): $e',
      );
      return [];
    }
  }

  Future<Product?> getProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getProductById&productId=$productId'),
      );
      final Map<String, dynamic> data = _handleResponse(response);

      if (data['status'] == 'success' && data['product'] != null) {
        return Product.fromJson(data['product']);
      } else {
        developer.log(
          'Failed to fetch product by ID $productId: ${data['message']}',
        );
        return null;
      }
    } catch (e) {
      developer.log('API Error in getProductById: $e');
      return null;
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      developer.log(
        'API Success Response: ${response.statusCode}, Body: ${response.body}',
      );
      return data;
    } else {
      developer.log('API Error Response: ${response.statusCode}');
      developer.log('Headers: ${response.headers}');
      developer.log('Body: ${response.body}');
      return {
        'status': 'error',
        'message':
            'Server error: ${response.statusCode}. Body: ${response.body}',
      };
    }
  }
}
