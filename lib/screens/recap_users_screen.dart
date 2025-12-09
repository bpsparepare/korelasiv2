import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;

import 'user_history_detail_screen.dart';

class UserRecap {
  final String id;
  final String nama;
  final double totalSpending;

  UserRecap({
    required this.id,
    required this.nama,
    required this.totalSpending,
  });
}

class RecapUsersScreen extends StatefulWidget {
  const RecapUsersScreen({super.key});

  @override
  State<RecapUsersScreen> createState() => _RecapUsersScreenState();
}

class _RecapUsersScreenState extends State<RecapUsersScreen> {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<UserRecap> _currentRecap = [];
  List<UserRecap> _filteredRecap = [];

  List<String> _availableMonths = [];
  String? _selectedMonth;
  bool _isLoading = true;
  bool _isExporting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAvailableMonthsAndInitialData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableMonthsAndInitialData() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('mv_korelasi_available_months')
          .select('month_start')
          .order('month_start', ascending: false)
          .range(0, 99999);
      final uniqueMonths = <String>{};

      for (var item in (response as List)) {
        final date = DateTime.parse(item['month_start']);
        uniqueMonths.add(DateFormat('MMMM yyyy', 'id_ID').format(date));
      }

      _availableMonths =
          uniqueMonths.toList()..sort((a, b) {
            final da = DateFormat('MMMM yyyy', 'id_ID').parse(a);
            final db = DateFormat('MMMM yyyy', 'id_ID').parse(b);
            return db.compareTo(da);
          });

      // ✅ Pilih bulan sekarang secara default jika tersedia
      final currentMonth = DateFormat(
        'MMMM yyyy',
        'id_ID',
      ).format(DateTime.now());
      if (_availableMonths.contains(currentMonth)) {
        _selectedMonth = currentMonth;
      } else if (_availableMonths.isNotEmpty) {
        _selectedMonth = _availableMonths.first;
      } else {
        _selectedMonth = 'Semua Waktu';
      }

      await _fetchUserRecapsForMonth(_selectedMonth);
    } catch (e) {
      if (mounted)
        setState(() => _errorMessage = 'Gagal memuat daftar bulan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserRecapsForMonth(String? month) async {
    setState(() => _isLoading = true);
    _currentRecap.clear();
    _filteredRecap.clear();

    try {
      PostgrestFilterBuilder query = supabase
          .from('korelasi_data_pesanan')
          .select('id_pelanggan, nama_pembeli, subtotal, tanggal_pesanan');

      if (month != null && month != 'Semua Waktu') {
        final monthDate = DateFormat('MMMM yyyy', 'id_ID').parse(month);
        final firstDay = DateTime(monthDate.year, monthDate.month, 1);
        final lastDay = DateTime(
          monthDate.year,
          monthDate.month + 1,
          0,
          23,
          59,
          59,
        );
        query = query
            .gte('tanggal_pesanan', firstDay.toIso8601String())
            .lte('tanggal_pesanan', lastDay.toIso8601String());
      }

      final response = await query;
      final Map<String, UserRecap> userRecapMap = {};

      for (var orderItem in (response as List)) {
        final userId = orderItem['id_pelanggan'].toString();
        final userName = orderItem['nama_pembeli'].toString();
        final subtotal = (orderItem['subtotal'] as num).toDouble();

        userRecapMap.update(
          userId,
          (existing) => UserRecap(
            id: userId,
            nama: userName,
            totalSpending: existing.totalSpending + subtotal,
          ),
          ifAbsent:
              () => UserRecap(
                id: userId,
                nama: userName,
                totalSpending: subtotal,
              ),
        );
      }

      _currentRecap =
          userRecapMap.values.toList()
            ..sort((a, b) => b.totalSpending.compareTo(a.totalSpending));

      _filterUsers();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal memuat rekap: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecap =
          _currentRecap
              .where((user) => user.nama.toLowerCase().contains(query))
              .toList();
    });
  }

  Future<void> _exportCurrentRecapToXlsx() async {
    if (_filteredRecap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Hapus sheet lain (kalau ada)
      excel.sheets.keys
          .where((s) => s != 'Sheet1')
          .toList()
          .forEach(excel.delete);

      // Header
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue('Nama Pengguna');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = TextCellValue(
        'Total Belanja (${_selectedMonth ?? 'Semua Waktu'})',
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .cellStyle = headerStyle;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .cellStyle = headerStyle;

      // Data isi
      double totalKeseluruhan = 0;
      for (int i = 0; i < _filteredRecap.length; i++) {
        final recap = _filteredRecap[i];
        totalKeseluruhan += recap.totalSpending;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
            .value = TextCellValue(recap.nama);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
            .value = DoubleCellValue(recap.totalSpending);
      }

      // Baris total di paling bawah
      final totalRow = _filteredRecap.length + 2;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
          .value = TextCellValue('Total Keseluruhan');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRow))
          .value = DoubleCellValue(totalKeseluruhan);

      // File name
      final monthName = (_selectedMonth ?? 'Semua_Waktu').replaceAll(' ', '_');
      final fileName = 'Rekap_Belanja_Korelasi_$monthName.xlsx';

      final fileBytes = excel.encode();

      // Unduh hanya di web
      if (kIsWeb && fileBytes != null) {
        final blob = html.Blob([
          fileBytes,
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor =
            html.AnchorElement(href: url)
              ..setAttribute('download', fileName)
              ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat file Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);
    final currencyFormatter = NumberFormat.decimalPattern('id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rekapitulasi Pengguna',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedMonth,
                                decoration: InputDecoration(
                                  labelText: 'Filter Bulan',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                items:
                                    ['Semua Waktu', ..._availableMonths].map((
                                      String month,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: month,
                                        child: Text(month),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedMonth = newValue;
                                  });
                                  _fetchUserRecapsForMonth(newValue);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (kIsWeb)
                              _isExporting
                                  ? const CircularProgressIndicator()
                                  : IconButton.filled(
                                    icon: const Icon(
                                      Icons.download_for_offline,
                                    ),
                                    tooltip: 'Ekspor rekap bulan ini (XLSX)',
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryColor,
                                    ),
                                    onPressed: _exportCurrentRecapToXlsx,
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _fetchUserRecapsForMonth(_selectedMonth),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredRecap.length,
                        itemBuilder: (context, index) {
                          final userRecap = _filteredRecap[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Text(
                                  userRecap.nama.isNotEmpty
                                      ? userRecap.nama
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                userRecap.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Total Belanja: Rp ${currencyFormatter.format(userRecap.totalSpending)}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => UserHistoryDetailScreen(
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
