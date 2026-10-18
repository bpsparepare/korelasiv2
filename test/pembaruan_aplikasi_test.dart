import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korelasi/services/pembaruan_aplikasi.dart';

void main() {
  final baris = <String, dynamic>{
    'android_url': 'https://drive/android',
    'windows_url': '',
    'ios_url': null,
    'download_url': 'https://drive/umum',
  };

  test('Android memakai android_url', () {
    expect(PembaruanAplikasi.pilihTautan(baris, TargetPlatform.android),
        'https://drive/android');
  });

  test('kolom platform kosong jatuh ke download_url', () {
    expect(PembaruanAplikasi.pilihTautan(baris, TargetPlatform.windows),
        'https://drive/umum');
    expect(PembaruanAplikasi.pilihTautan(baris, TargetPlatform.macOS),
        'https://drive/umum');
  });

  test('tanpa tautan sama sekali → null', () {
    expect(PembaruanAplikasi.pilihTautan({}, TargetPlatform.android), isNull);
  });
}
