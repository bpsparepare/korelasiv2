import 'package:flutter_test/flutter_test.dart';
import 'package:korelasi/models/user.dart';

void main() {
  test('User.fromJson membaca baris korelasi_saya()', () {
    final user = User.fromJson({
      'id': 'a1',
      'nama_lengkap': 'Nama Uji',
      'username': 'uji',
      'role': 'admin',
    });

    expect(user.id, 'a1');
    expect(user.namaLengkap, 'Nama Uji');
    expect(user.username, 'uji');
    expect(user.isAdmin, isTrue);
  });

  test('User.fromJson memberi nilai bawaan untuk kolom kosong', () {
    final user = User.fromJson({'id': 'b2'});

    expect(user.namaLengkap, 'Tanpa Nama');
    expect(user.role, 'user');
    expect(user.isAdmin, isFalse);
  });

  test('copyWith hanya mengubah nama dan username', () {
    final user = User(id: 'c3', namaLengkap: 'Lama', username: 'lama', role: 'admin');
    final baru = user.copyWith(namaLengkap: 'Baru');

    expect(baru.id, 'c3');
    expect(baru.namaLengkap, 'Baru');
    expect(baru.username, 'lama');
    expect(baru.role, 'admin');
  });
}
