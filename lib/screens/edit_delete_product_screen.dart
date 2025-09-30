// lib/screens/edit_delete_product_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:korelasi/models/product.dart';
import 'package:korelasi/screens/edit_product_form_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditDeleteProductScreen extends StatefulWidget {
  const EditDeleteProductScreen({super.key});

  @override
  State<EditDeleteProductScreen> createState() => _EditDeleteProductScreenState();
}

class _EditDeleteProductScreenState extends State<EditDeleteProductScreen> {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = ['Semua'];
  String _selectedCategory = 'Semua';

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await supabase.from('korelasi_master_produk').select().order('nama_produk');
      _allProducts = (response as List).map((data) => Product.fromJson(data)).toList();

      final uniqueCategories = <String>{};
      for (var product in _allProducts) {
        uniqueCategories.add(product.kategori);
      }
      _categories = ['Semua', ...uniqueCategories];

      _filterProducts();
    } catch (e) {
      _errorMessage = 'Gagal memuat produk: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterProducts() {
    List<Product> products = [];
    if (_selectedCategory == 'Semua') {
      products = _allProducts;
    } else {
      products = _allProducts.where((p) => p.kategori == _selectedCategory).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      products = products.where((p) => p.nama.toLowerCase().contains(query) || p.id.toLowerCase().contains(query)).toList();
    }

    setState(() {
      _filteredProducts = products;
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Anda yakin ingin menghapus "${product.nama}" secara permanen? Gambar produk juga akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() { _isLoading = true; });
      try {
        final bucketName = 'gambar-produk';
        if (product.gambarUrl.isNotEmpty) {
          final fileName = Uri.parse(product.gambarUrl).pathSegments.last;
          await supabase.storage.from(bucketName).remove([fileName]);
        }

        await supabase.from('korelasi_master_produk').delete().eq('id_produk', product.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil dihapus!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus produk: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        _fetchAllProducts();
      }
    }
  }

  void _navigateToEdit(Product product) async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProductFormScreen(product: product)),
    );
    if (result == true) {
      _fetchAllProducts();
    }
  }

  // --- FUNGSI BARU UNTUK MEMBUAT GRID RESPONSIVE ---
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth > 1200) return 5;
    if (screenWidth > 900) return 4;
    if (screenWidth > 600) return 3;
    return 2;
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth > 600) return 0.8; // Aspek rasio untuk desktop
    return 2 / 3.5; // Aspek rasio untuk mobile
  }
  // --- AKHIR FUNGSI BARU ---

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit & Hapus Produk', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : Column(
        children: [
          _buildSearchAndFilter(primaryColor),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAllProducts,
              // --- PERBAIKAN: Menggunakan LayoutBuilder untuk mendapatkan lebar layar ---
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                    final childAspectRatio = _getChildAspectRatio(constraints.maxWidth);

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount, // Gunakan hasil kalkulasi
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspectRatio, // Gunakan hasil kalkulasi
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return _buildProductEditCard(product);
                      },
                    );
                  }
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk atau ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _filterProducts();
                  },
                  selectedColor: primaryColor.withOpacity(0.8),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductEditCard(Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: product.gambarUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nama,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: ${product.id}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => _navigateToEdit(product),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 13),
                      SizedBox(width: 4),
                      Text('Edit', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => _deleteProduct(product),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, size: 13),
                      SizedBox(width: 4),
                      Text('Hapus', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

