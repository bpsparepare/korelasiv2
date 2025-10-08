// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/user.dart' as app_user;
import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'history_screen.dart';
import 'keranjang_screen.dart';
import 'login_screen.dart';
import 'scan_screen.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final app_user.User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  late final List<String> _appBarTitles;
  final GlobalKey<_HomePageContentState> _homePageKey = GlobalKey<_HomePageContentState>();


  @override
  void initState() {
    super.initState();

    final bool isAdmin = widget.user.role == 'admin';

    _pages = [
      HomePageContent(key: _homePageKey, user: widget.user),
      const HistoryScreen(),
      KeranjangScreen(
        onCheckoutSuccess: () {
          setState(() {
            _selectedIndex = 0;
          });
          _homePageKey.currentState?.refreshData();
        },
      ),
      if (isAdmin) const AdminScreen(),
    ];

    _appBarTitles = [
      'Hi, ${widget.user.namaLengkap}!',
      'Riwayat Pembelian',
      'Keranjang Belanja',
      if (isAdmin) 'Panel Admin',
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);
    final cart = Provider.of<CartProvider>(context);
    final bool isAdmin = widget.user.role == 'admin';

    final List<BottomNavigationBarItem> navBarItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'History',
      ),
      BottomNavigationBarItem(
        icon: Badge(
          label: Text('${cart.totalItemsInCart}'),
          isLabelVisible: cart.totalItemsInCart > 0,
          child: const Icon(Icons.shopping_cart),
        ),
        label: 'Keranjang',
      ),
    ];

    if (isAdmin) {
      navBarItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(_appBarTitles[_selectedIndex]),
        automaticallyImplyLeading: false,
        actions: _selectedIndex == 0
            ? [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final bool? shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanScreen()),
              );
              if (shouldRefresh == true) {
                _homePageKey.currentState?.refreshData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user)),
              );
            },
          ),
        ]
            : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryColor,
        items: navBarItems,
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  final app_user.User user;
  const HomePageContent({super.key, required this.user});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  final currencyFormatter = NumberFormat.decimalPattern('id_ID');

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = ['Semua'];
  String _selectedCategory = 'Semua';

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await supabase
          .from('korelasi_master_produk')
          .select()
          .gt('stok', 0);

      _allProducts = (response as List)
          .map((data) => Product.fromJson(data))
          .toList();

      final uniqueCategories = <String>{};
      for (var product in _allProducts) {
        uniqueCategories.add(product.kategori);
      }
      _categories = ['Semua', ...uniqueCategories];

      _filterProducts();
    } catch (e) {
      _errorMessage = 'Gagal memuat data: $e';
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

  // --- FUNGSI BARU UNTUK MEMBUAT GRID RESPONSIVE ---
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth > 1200) return 5; // Layar sangat besar
    if (screenWidth > 900) return 4;  // Layar besar / tablet landscape
    if (screenWidth > 600) return 3;  // Layar kecil / tablet portrait
    return 2; // Layar HP
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth > 600) return 0.75; // Aspek rasio untuk desktop
    return 2 / 3.5; // Aspek rasio untuk mobile
  }
  // --- AKHIR FUNGSI BARU ---


  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    return Column(
      children: [
        _buildSearchAndFilter(primaryColor),
        const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchData,
            child: _filteredProducts.isEmpty
                ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 100),
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Produk tidak ditemukan',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
                : LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                final childAspectRatio = _getChildAspectRatio(constraints.maxWidth);

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(product);
                  },
                );
              },
            ),
          ),
        ),
      ],
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

  Widget _buildProductCard(Product product) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final cartItem = cart.findItemById(product.id);
        final quantityInCart = cartItem?.quantity ?? 0;

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
                      'Stok: ${product.stok}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Rp ${currencyFormatter.format(product.harga)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: quantityInCart == 0
                          ? SizedBox(
                        key: ValueKey('add_button_${product.id}'),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: product.stok > 0 ? () {
                            HapticFeedback.lightImpact();
                            cart.addItem(product);
                          } : null,
                          child: const Text('Tambah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      )
                          : Container(
                        key: ValueKey('counter_${product.id}'),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, size: 18, color: Colors.grey.shade700),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                cart.decreaseQuantity(product.id);
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            Text('$quantityInCart', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: Icon(Icons.add, size: 18, color: quantityInCart < product.stok ? primaryColor : Colors.grey),
                              onPressed: quantityInCart < product.stok
                                  ? () {
                                HapticFeedback.lightImpact();
                                cart.increaseQuantity(product.id);
                              }
                                  : null,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

