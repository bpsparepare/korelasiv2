# Kunci Supabase

Proyek Supabase: `iubeqsafpibmousxvmfk` (dipakai bersama Bolt dan aplikasi BPS
Parepare lain).

## 2026-10-18 · Pindah ke API keys baru (BOLT-32 di repo Bolt)

Kunci *legacy* (`anon` dan `service_role`, berbentuk JWT `eyJ…`) dimatikan
karena `service_role` pernah bocor. Penggantinya:

- **Publishable key** (`sb_publishable_…`): untuk aplikasi/klien, boleh ikut
  dibundel. Sama untuk semua aplikasi.
- **Secret key** (`sb_secret_…`): hanya untuk server. Satu kunci per
  aplikasi supaya bisa dicabut sendiri-sendiri. **Jangan** taruh di kode
  klien, di variabel `VITE_…`, atau di chat.

Kunci yang sama boleh dikirim di header `apikey` **dan**
`Authorization: Bearer …`; Supabase menerimanya selama keduanya sama.
Panggilan Edge Function dengan `verify_jwt` tetap butuh sesi login pengguna.

## Di Korelasi

- `lib/main.dart`: `Supabase.initialize(anonKey: …)` memakai publishable key.
- Rilis pertama dengan kunci baru: **2.1.3+3** (APK split per ABI di folder
  Drive Korelasi). Versi sebelumnya tidak bisa terhubung lagi.
- APK ditandatangani kunci **debug** di Mac pembangun; APK dari Mac lain tidak
  bisa menimpa instalasi lama (hapus aplikasi dulu).
- Build: `flutter build apk --release --split-per-abi`.
