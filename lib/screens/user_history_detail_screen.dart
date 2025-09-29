// lib/screens/user_history_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order_history.dart';
import '../models/history_order_item.dart';

class UserHistoryDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const UserHistoryDetailScreen({super.key, required this.userId, required this.userName});

  @override
  State<UserHistoryDetailScreen> createState() => _UserHistoryDetailScreenState();
}

class _UserHistoryDetailScreenState extends State<UserHistoryDetailScreen> {
  List<OrderHistory> _allOrderHistory = [];
  bool _isLoading = true;
  String _errorMessage = '';

  List<OrderHistory> _filteredHistory = [];
  List<DateTime> _availableMonths = [];
  DateTime? _selectedMonth;
  double _monthlyTotal = 0.0;

  final supabase = Supabase.instance.client;
  final currencyFormatter = NumberFormat.decimalPattern('id_ID');

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  Future<void> _fetchOrderHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // DIUBAH: Menggunakan userId dari widget, bukan SharedPreferences
      final response = await supabase
          .from('korelasi_data_pesanan')
          .select('*, korelasi_master_produk(*)')
          .eq('id_pelanggan', widget.userId)
          .order('tanggal_pesanan', ascending: false);

      final Map<String, List<HistoryOrderItem>> groupedItems = {};
      for (var itemData in (response as List)) {
        final orderId = itemData['id_pesanan'].toString();
        if (!groupedItems.containsKey(orderId)) {
          groupedItems[orderId] = [];
        }
        groupedItems[orderId]!.add(HistoryOrderItem.fromJson(itemData));
      }

      final List<OrderHistory> fetchedHistory = [];
      final Set<DateTime> uniqueMonths = {};

      groupedItems.forEach((orderId, items) {
        final rawDateString = (response as List).firstWhere((e) => e['id_pesanan'] == orderId)['tanggal_pesanan'];
        final orderDateTime = DateTime.parse(rawDateString);

        uniqueMonths.add(DateTime(orderDateTime.year, orderDateTime.month));

        final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(orderDateTime);
        final double total = items.fold(0, (sum, item) => sum + item.subtotal);

        fetchedHistory.add(OrderHistory(
          orderId: orderId,
          orderDate: formattedDate,
          totalOrderPrice: total,
          items: items,
        ));
      });

      if (!mounted) return;

      setState(() {
        _allOrderHistory = fetchedHistory;
        _availableMonths = uniqueMonths.toList()..sort((a, b) => b.compareTo(a));
        if (_availableMonths.isNotEmpty) {
          _selectedMonth = _availableMonths.first;
          _filterOrdersByMonth();
        } else {
          _errorMessage = 'Pengguna ini belum memiliki riwayat pembelian.';
        }
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat riwayat pesanan: $e';
        _isLoading = false;
      });
    }
  }

  void _filterOrdersByMonth() {
    if (_selectedMonth == null) return;

    final filtered = _allOrderHistory.where((order) {
      final orderDateTime = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').parse(order.orderDate);
      return orderDateTime.year == _selectedMonth!.year && orderDateTime.month == _selectedMonth!.month;
    }).toList();

    final total = filtered.fold<double>(0, (sum, order) => sum + order.totalOrderPrice);

    setState(() {
      _filteredHistory = filtered;
      _monthlyTotal = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return Scaffold(
      appBar: AppBar(
        // DIUBAH: Menampilkan nama pengguna yang dipilih
        title: Text('Riwayat: ${widget.userName}', style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _allOrderHistory.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<DateTime>(
                  value: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Filter Berdasarkan Bulan',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _availableMonths.map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(DateFormat('MMMM yyyy', 'id_ID').format(month)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMonth = value;
                        _filterOrdersByMonth();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.receipt_long, color: primaryColor),
                    title: const Text('Total Pengeluaran :'),
                    trailing: Text(
                      'Rp ${currencyFormatter.format(_monthlyTotal)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchOrderHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _filteredHistory.length,
                itemBuilder: (context, index) {
                  final order = _filteredHistory[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal: ${order.orderDate}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Pesanan: Rp ${currencyFormatter.format(order.totalOrderPrice)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: primaryColor,
                            ),
                          ),
                          const Divider(height: 20),
                          const Text('Detail Item:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          ...order.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: item.gambarUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.productName} (${item.jumlah} ${item.satuan})',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                        Text(
                                          'Harga: Rp ${currencyFormatter.format(item.harga)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                                        ),
                                        Text(
                                          'Subtotal: Rp ${currencyFormatter.format(item.subtotal)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
