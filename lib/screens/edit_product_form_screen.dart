// lib/screens/edit_product_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '/models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProductFormScreen extends StatefulWidget {
  final Product product;
  const EditProductFormScreen({super.key, required this.product});

  @override
  State<EditProductFormScreen> createState() => _EditProductFormScreenState();
}

class _EditProductFormScreenState extends State<EditProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _stokController;
  late TextEditingController _hargaController;
  late TextEditingController _satuanBaruController;
  late TextEditingController _kategoriBaruController;

  String? _selectedSatuan;
  String? _selectedKategori;

  bool _isLoading = false;
  File? _selectedImage;
  String? _currentImageUrl;

  final supabase = Supabase.instance.client;

  List<String> _satuanOptions = [];
  List<String> _kategoriOptions = [];
  bool _showSatuanBaruField = false;
  bool _showKategoriBaruField = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.product.nama);
    _stokController = TextEditingController(text: widget.product.stok.toString());
    _hargaController = TextEditingController(text: widget.product.harga.toStringAsFixed(0));
    _currentImageUrl = widget.product.gambarUrl;

    _satuanBaruController = TextEditingController();
    _kategoriBaruController = TextEditingController();

    _fetchDropdownOptions();
  }

  Future<void> _fetchDropdownOptions() async {
    try {
      final satuanResponse = await supabase.rpc('get_unique_satuan');
      final kategoriResponse = await supabase.rpc('get_unique_kategori');

      final uniqueSatuan = (satuanResponse as List).map((e) => e['satuan'].toString()).toList();
      final uniqueKategori = (kategoriResponse as List).map((e) => e['kategori'].toString()).toList();

      setState(() {
        _satuanOptions = [...uniqueSatuan, 'Lainnya...'];
        _kategoriOptions = [...uniqueKategori, 'Lainnya...'];

        if (uniqueSatuan.contains(widget.product.satuan)) {
          _selectedSatuan = widget.product.satuan;
        }
        if (uniqueKategori.contains(widget.product.kategori)) {
          _selectedKategori = widget.product.kategori;
        }
      });
    } catch (e) {
      debugPrint("Gagal mengambil opsi dropdown: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat opsi: $e')),
        );
      }
    }
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = _currentImageUrl!;
      final bucketName = 'gambar-produk';

      if (_selectedImage != null) {
        try {
          final oldFileName = Uri.parse(_currentImageUrl!).pathSegments.last;
          await supabase.storage.from(bucketName).remove([oldFileName]);
        } catch (e) {
          debugPrint("Gagal menghapus gambar lama (mungkin tidak ada atau URL salah): $e");
        }

        final imageFile = _selectedImage!;
        final imageExtension = imageFile.path.split('.').last.toLowerCase();
        final newFileName = '${const Uuid().v4()}.$imageExtension';

        await supabase.storage.from(bucketName).upload(newFileName, imageFile);
        imageUrl = supabase.storage.from(bucketName).getPublicUrl(newFileName);
      }

      final String satuanToSave = _showSatuanBaruField ? _satuanBaruController.text.trim() : _selectedSatuan!;
      final String kategoriToSave = _showKategoriBaruField ? _kategoriBaruController.text.trim() : _selectedKategori!;

      await supabase.from('korelasi_master_produk').update({
        'nama_produk': _namaController.text.trim(),
        'gambar_url': imageUrl,
        'stok': int.parse(_stokController.text.trim()),
        'harga': int.parse(_hargaController.text.trim().replaceAll('.', '')),
        'satuan': satuanToSave,
        'kategori': kategoriToSave,
      }).eq('id_produk', widget.product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perubahan berhasil disimpan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _stokController.dispose();
    _hargaController.dispose();
    _satuanBaruController.dispose();
    _kategoriBaruController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Produk', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _showImageSourceActionSheet,
                child: SizedBox(
                  height: 150,
                  width: 150,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400)
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _currentImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Ketuk gambar untuk mengganti', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.product.id,
              decoration: const InputDecoration(labelText: 'ID Produk (Barcode)', border: OutlineInputBorder(), enabled: false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stokController,
                    decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Stok tidak boleh kosong' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _hargaController,
                    decoration: const InputDecoration(labelText: 'Harga', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Harga tidak boleh kosong' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSatuan,
                    hint: const Text('Satuan'),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _satuanOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSatuan = newValue;
                        _showSatuanBaruField = newValue == 'Lainnya...';
                      });
                    },
                    validator: (value) => value == null ? 'Satuan harus dipilih' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedKategori,
                    hint: const Text('Kategori'),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _kategoriOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedKategori = newValue;
                        _showKategoriBaruField = newValue == 'Lainnya...';
                      });
                    },
                    validator: (value) => value == null ? 'Kategori harus dipilih' : null,
                  ),
                ),
              ],
            ),
            if (_showSatuanBaruField) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _satuanBaruController,
                decoration: const InputDecoration(labelText: 'Masukkan Satuan Baru', border: OutlineInputBorder()),
                validator: (value) => _showSatuanBaruField && value!.isEmpty ? 'Satuan baru tidak boleh kosong' : null,
              ),
            ],
            if (_showKategoriBaruField) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _kategoriBaruController,
                decoration: const InputDecoration(labelText: 'Masukkan Kategori Baru', border: OutlineInputBorder()),
                validator: (value) => _showKategoriBaruField && value!.isEmpty ? 'Kategori baru tidak boleh kosong' : null,
              ),
            ],
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Perubahan'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, color: Colors.grey[600], size: 40),
        const SizedBox(height: 8),
        Text('Ganti Gambar', style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}
