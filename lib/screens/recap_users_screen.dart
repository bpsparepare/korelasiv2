// lib/screens/recap_users_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // BARU: Import untuk format angka
import '/screens/user_history_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Model sederhana untuk menampung data rekap pengguna
class UserRecap {
  final String id;
  final String nama;
  final double totalSpending;

  UserRecap({required this.id, required this.nama, required this.totalSpending});
}

class RecapUsersScreen extends StatefulWidget {
  const RecapUsersScreen({super.key});

  @override
  State<RecapUsersScreen> createState() => _RecapUsersScreenState();
}

class _RecapUsersScreenState extends State<RecapUsersScreen> {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<UserRecap> _allUsersRecap = [];
  List<UserRecap> _filteredUsersRecap = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserRecaps();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRecaps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Ambil semua data pesanan untuk diolah
      final response = await supabase.from('korelasi_data_pesanan').select('id_pelanggan, nama_pembeli, subtotal');

      final Map<String, UserRecap> userRecapMap = {};

      for (var orderItem in (response as List)) {
        final userId = orderItem['id_pelanggan'].toString();
        final userName = orderItem['nama_pembeli'].toString();
        final subtotal = (orderItem['subtotal'] as num).toDouble();

        if (userRecapMap.containsKey(userId)) {
          // Jika user sudah ada di map, tambahkan total belanjanya
          final existingRecap = userRecapMap[userId]!;
          userRecapMap[userId] = UserRecap(
            id: userId,
            nama: userName,
            totalSpending: existingRecap.totalSpending + subtotal,
          );
        } else {
          // Jika user baru, buat entri baru di map
          userRecapMap[userId] = UserRecap(
            id: userId,
            nama: userName,
            totalSpending: subtotal,
          );
        }
      }

      _allUsersRecap = userRecapMap.values.toList()
        ..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));

      _filterUsers();

    } catch (e) {
      _errorMessage = 'Gagal memuat data rekap: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsersRecap = _allUsersRecap
          .where((user) => user.nama.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapitulasi Pengguna', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama pengguna...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchUserRecaps,
              child: ListView.builder(
                itemCount: _filteredUsersRecap.length,
                itemBuilder: (context, index) {
                  final userRecap = _filteredUsersRecap[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(userRecap.nama.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(userRecap.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Total Belanja: Rp ${NumberFormat.decimalPattern('id_ID').format(userRecap.totalSpending)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserHistoryDetailScreen(
                              userId: userRecap.id,
                              userName: userRecap.nama,
                            ),
                          ),
                        );
                      },
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
