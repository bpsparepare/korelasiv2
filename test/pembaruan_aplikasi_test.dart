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

  test('APK split-per-abi: versionCode 2004/1004 dibaca build 4', () {
    expect(PembaruanAplikasi.nomorBuild('2004', '2.2.0', TargetPlatform.android), 4);
    expect(PembaruanAplikasi.nomorBuild('1004', '2.2.0', TargetPlatform.android), 4);
    expect(PembaruanAplikasi.nomorBuild('4', '2.2.0', TargetPlatform.android), 4);
  });

  test('desktop memakai nomor build apa adanya, atau dari versi', () {
    expect(PembaruanAplikasi.nomorBuild('4', '2.2.0', TargetPlatform.macOS), 4);
    expect(PembaruanAplikasi.nomorBuild('', '2.2.0+4', TargetPlatform.windows), 4);
    expect(PembaruanAplikasi.nomorBuild('', '2.2.0', TargetPlatform.windows), isNull);
  });
}
