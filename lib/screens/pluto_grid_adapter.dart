// lib/screens/pluto_grid_adapter.dart

import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePlutoGridAdapter {
  final String tableName;
  final Function(String) onSuccess;
  final Function(String) onError;

  late PlutoGridStateManager stateManager;
  List<PlutoColumn> columns = [];
  List<PlutoRow> rows = [];
  late String _primaryKey;

  final supabase = Supabase.instance.client;

  SupabasePlutoGridAdapter({
    required this.tableName,
    required this.onSuccess,
    required this.onError,
  });

  Future<void> initialize() async {
    await _fetchSchema();
    await _fetchData();
  }

  Future<void> _fetchSchema() async {
    try {
      final response = await supabase.rpc('get_table_schema', params: {'p_table_name': tableName});
      final List<dynamic> schemaInfo = response;

      final pkColumn = schemaInfo.firstWhere((col) => col['is_primary'] == true, orElse: () => null);
      if (pkColumn == null) {
        throw Exception('Tabel "$tableName" tidak memiliki Primary Key.');
      }
      _primaryKey = pkColumn['column_name'];

      columns = schemaInfo.map((col) {
        final colName = col['column_name'] as String;
        final colType = col['data_type'] as String;
        return PlutoColumn(
          title: colName,
          field: colName,
          type: _mapSupabaseTypeToPluto(colType),
          readOnly: col['is_primary'] == true,
          enableEditingMode: true,
        );
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil skema tabel: $e');
    }
  }

  Future<void> _fetchData() async {
    try {
      final response = await supabase.from(tableName).select();
      rows = (response as List).map((rowData) {
        return PlutoRow(
          cells: {
            for (var col in columns) col.field: PlutoCell(value: rowData[col.field]),
          },
        );
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data: $e');
    }
  }

  Future<void> handleOnChanged(PlutoGridOnChangedEvent event) async {
    try {
      final row = event.row;
      final primaryKeyValue = row.cells[_primaryKey]!.value;

      if (primaryKeyValue == null || primaryKeyValue.toString().isEmpty) {
        final newRowData = {
          for (var cell in row.cells.entries)
            if (cell.key != _primaryKey && cell.value.value != null && cell.value.value.toString().isNotEmpty)
              cell.key: cell.value.value
        };

        if (newRowData.isEmpty) {
          return;
        }

        final response = await supabase.from(tableName).insert(newRowData).select();

        final returnedData = response.first;
        stateManager.setRowChecked(row, false);
        for (var entry in returnedData.entries) {
          row.cells[entry.key]?.value = entry.value;
        }
        onSuccess('Baris baru berhasil ditambahkan!');

      } else {
        await supabase.from(tableName).update({
          event.column.field: event.value,
        }).eq(_primaryKey, primaryKeyValue);
        onSuccess('Data berhasil diperbarui!');
      }

    } catch (e) {
      onError('Gagal menyimpan perubahan: $e');
    }
  }

  void addNewRow() {
    stateManager.prependNewRows();
    final newRow = stateManager.rows.first;
    final firstCell = newRow.cells.entries.first.value;
    stateManager.setCurrentCell(firstCell, 0);
    stateManager.setEditing(true);
  }

  Future<void> removeSelectedRows() async {
    final rowsToRemove = stateManager.checkedRows;
    if (rowsToRemove.isEmpty) {
      onError('Pilih baris yang ingin dihapus terlebih dahulu.');
      return;
    }

    try {
      for (final row in rowsToRemove) {
        final primaryKeyValue = row.cells[_primaryKey]!.value;
        if (primaryKeyValue != null) {
          await supabase.from(tableName).delete().eq(_primaryKey, primaryKeyValue);
        }
      }
      stateManager.removeRows(rowsToRemove);
      onSuccess('Baris berhasil dihapus!');
    } catch (e) {
      onError('Gagal menghapus baris: $e');
    }
  }

  PlutoColumnType _mapSupabaseTypeToPluto(String supabaseType) {
    if (supabaseType.contains('int') || supabaseType.contains('numeric')) {
      return PlutoColumnType.number();
    } else if (supabaseType.contains('date') || supabaseType.contains('timestamp')) {
      return PlutoColumnType.date();
    }
    return PlutoColumnType.text();
  }
}

