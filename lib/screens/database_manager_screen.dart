// lib/screens/database_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:korelasi/screens/pluto_grid_adapter.dart';
import 'package:pluto_grid/pluto_grid.dart';

class DatabaseManagerScreen extends StatefulWidget {
  const DatabaseManagerScreen({super.key});

  @override
  State<DatabaseManagerScreen> createState() => _DatabaseManagerScreenState();
}

class _DatabaseManagerScreenState extends State<DatabaseManagerScreen> {
  final List<String> tableNames = [
    'korelasi_login',
    'korelasi_master_produk',
    'korelasi_data_pesanan',
  ];

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return DefaultTabController(
      length: tableNames.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Database Manager', style: TextStyle(color: Colors.white)),
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: tableNames.map((name) => Tab(text: name)).toList(),
          ),
        ),
        body: TabBarView(
          children: tableNames
              .map((name) => SupabasePlutoGrid(tableName: name))
              .toList(),
        ),
      ),
    );
  }
}

class SupabasePlutoGrid extends StatefulWidget {
  final String tableName;
  const SupabasePlutoGrid({super.key, required this.tableName});

  @override
  State<SupabasePlutoGrid> createState() => _SupabasePlutoGridState();
}

class _SupabasePlutoGridState extends State<SupabasePlutoGrid> {
  late final SupabasePlutoGridAdapter adapter;

  /// nama field checkbox (gunakan nama unik supaya tidak mengganggu DB columns)
  static const String _checkboxField = '__selected__';

  @override
  void initState() {
    super.initState();
    adapter = SupabasePlutoGridAdapter(
      tableName: widget.tableName,
      onSuccess: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
        }
      },
      onError: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  void _handleOnRowAdded() {
    // tambahkan baris via adapter, lalu pastikan baris baru punya checkbox cell
    adapter.addNewRow();

    // set a post frame callback supaya stateManager.rows sudah ter-update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final sm = adapter.stateManager;
        if (sm.rows.isNotEmpty) {
          final newRow = sm.rows.first;
          newRow.cells.putIfAbsent(_checkboxField, () => PlutoCell(value: false));
          sm.notifyListeners();
        }
      } catch (_) {
        // ignore jika stateManager belum siap
      }
    });
  }

  void _handleOnRowRemoved() {
    // adapter.removeSelectedRows() menggunakan adapter.stateManager.checkedRows
    adapter.removeSelectedRows();
  }

  void _handleSelectAll() {
    try {
      final sm = adapter.stateManager;
      for (final row in sm.rows) {
        final cell = row.cells[_checkboxField];
        if (cell != null) {
          cell.value = true;
          sm.setRowChecked(row, true);
        }
      }
      sm.notifyListeners();
    } catch (e) {
      // bisa tampilkan pesan kalau diperlukan
    }
  }

  void _handleUnselectAll() {
    try {
      final sm = adapter.stateManager;
      for (final row in sm.rows) {
        final cell = row.cells[_checkboxField];
        if (cell != null) {
          cell.value = false;
          sm.setRowChecked(row, false);
        }
      }
      sm.notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 255, 158, 68);

    return FutureBuilder(
      future: adapter.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // pastikan setiap row punya checkbox cell (nilai awal false)
        for (final row in adapter.rows) {
          row.cells.putIfAbsent(_checkboxField, () => PlutoCell(value: false));
        }

        // kolom checkbox manual (paling kiri)
        final checkboxColumn = PlutoColumn(
          title: '',
          field: _checkboxField,
          type: PlutoColumnType.text(),
          width: 56,
          minWidth: 56,
          enableSorting: false,
          enableFilterMenuItem: false,
          enableContextMenu: false,
          enableEditingMode: false,
          renderer: (rendererContext) {
            final cell = rendererContext.row.cells[_checkboxField]!;
            final isChecked = (cell.value ?? false) == true;

            // gunakan StatefulBuilder agar animasi Checkbox berjalan dan hanya rebuild widget cell ini
            return StatefulBuilder(
              builder: (context, localSetState) {
                return Center(
                  child: Checkbox(
                    value: isChecked,
                    onChanged: (val) {
                      final newVal = val == true;

                      // update nilai cell
                      cell.value = newVal;

                      // sinkronkan checkedRows agar adapter.removeSelectedRows dapat bekerja
                      rendererContext.stateManager.setRowChecked(rendererContext.row, newVal);

                      // beri tahu stateManager agar grid merender ulang (tanpa reload penuh)
                      rendererContext.stateManager.notifyListeners();

                      // refresh local checkbox widget (agar animasi terlihat)
                      localSetState(() {});
                    },
                  ),
                );
              },
            );
          },
        );

        // gabungkan kolom: checkbox + kolom dari adapter
        final columns = [checkboxColumn, ...adapter.columns];

        return Column(
          children: [
            Expanded(
              child: PlutoGrid(
                columns: columns,
                rows: adapter.rows,
                onLoaded: (event) {
                  // simpan stateManager ke adapter supaya adapter dapat menggunakan checkedRows dsb.
                  adapter.stateManager = event.stateManager;
                },
                onChanged: adapter.handleOnChanged,
                onRowChecked: (event) {
                  // tidak perlu panggil setState() global, stateManager.notifyListeners() mengurus render.
                },
                createHeader: (stateManager) {
                  return Container(
                    color: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.table_chart, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Tabel: ${widget.tableName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                configuration: PlutoGridConfiguration(
                  style: PlutoGridStyleConfig(
                    // gunakan properti yang aman / umum agar kompatibel
                    gridBackgroundColor: Colors.grey.shade200,
                    borderColor: Colors.grey.shade300,
                    iconColor: Colors.black87,
                    cellTextStyle: const TextStyle(fontSize: 14),
                    columnTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    columnHeight: 45,
                    activatedColor: primaryColor.withOpacity(0.1),
                    rowHeight: 40,
                    checkedColor: primaryColor.withOpacity(0.5),
                    menuBackgroundColor: Colors.white,
                  ),
                  columnFilter: const PlutoGridColumnFilterConfig(),
                ),
                mode: PlutoGridMode.normal,
              ),
            ),

            // footer dengan tombol add/select/unselect/delete
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Tambah Baris Baru',
                    child: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                      onPressed: _handleOnRowAdded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: 'Pilih Semua',
                    child: IconButton(
                      icon: const Icon(Icons.select_all, color: Colors.blue, size: 30),
                      onPressed: _handleSelectAll,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Batal Pilih Semua',
                    child: IconButton(
                      icon: const Icon(Icons.remove_done, color: Colors.grey, size: 30),
                      onPressed: _handleUnselectAll,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Tooltip(
                    message: 'Hapus Baris Terpilih',
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 30),
                      onPressed: _handleOnRowRemoved,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
