// lib/screens/admin_screen.dart

import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'manage_stock_screen.dart';
import 'edit_delete_product_screen.dart';
import 'recap_users_screen.dart';
import 'manage_users_screen.dart'; // BARU: Import halaman kelola pengguna

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text('Tambah Produk Baru'),
            subtitle: const Text('Mendaftarkan item baru ke dalam katalog.'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductScreen()),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Kelola Stok Produk'),
            subtitle: const Text('Menambah atau mengubah stok produk.'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageStockScreen()),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.edit_document),
            title: const Text('Edit & Hapus Produk'),
            subtitle: const Text('Mengubah detail atau menghapus produk.'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditDeleteProductScreen()),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Rekapitulasi Penjualan'),
            subtitle: const Text('Melihat riwayat pembelian per pengguna.'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecapUsersScreen()),
              );
            },
          ),
        ),
        // --- MENU BARU DI SINI ---
        Card(
          child: ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Kelola Akun Pengguna'),
            subtitle: const Text('Melihat detail dan password akun.'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
              );
            },
          ),
        ),
        // --- AKHIR MENU BARU ---
      ],
    );
  }
}

