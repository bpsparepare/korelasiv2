# Pembaruan aplikasi (sejak 2.2.0)

Korelasi memeriksa versi terbaru dari tabel **`korelasi_versions`** (satu
baris per rilis, bentuknya sama dengan `bolt_versions` di Bolt). Kode:
`lib/services/pembaruan_aplikasi.dart`, `lib/screens/wajib_perbarui_screen.dart`.

## Kapan diperiksa

- Saat aplikasi dibuka (splash), sebelum login.
- Setiap kali aplikasi kembali ke depan, paling sering sekali per jam.
- Tidak di web (web selalu memuat versi terbaru).

## Perilaku

| Keadaan | Hasil |
|---|---|
| Tidak ada baris dengan `build_number` > build terpasang | lanjut biasa |
| Ada, semuanya `force_update = false` | dialog "Versi baru", bisa **Nanti** atau **Unduh** |
| Ada, salah satunya `force_update = true` | layar **Korelasi perlu diperbarui**; aplikasi tidak bisa dipakai sampai versi baru dipasang |
| Gagal membaca (offline, tabel belum ada) | lanjut biasa |

Wajib dihitung dari **semua** rilis di atas versi terpasang, jadi rilis wajib
yang terlewat tetap memaksa walau rilis sesudahnya tidak wajib. Tombol Unduh
membuka `android_url` (Android), `windows_url` (Windows), `ios_url`
(iOS/macOS), atau `download_url` bila kolom platform kosong.

Cek ini untuk kenyamanan pengguna, bukan pengaman data: pengamannya tetap di
server (RLS, migrasi 0016 repo Bolt). Versi 2.1.x ke bawah tidak punya cek
ini; mereka berhenti bekerja sendiri begitu akses `anon` ditutup.

## Tabel (dibuat lewat migrasi di repo Bolt)

Belum ada di produksi. Rancangan untuk sub-sesi 3 BOLT-40 (atau migrasi
tersendiri):

```sql
create table public.korelasi_versions (
  id uuid primary key default gen_random_uuid(),
  version text not null,
  build_number integer not null unique,
  force_update boolean not null default false,
  download_url text,
  android_url text,
  windows_url text,
  ios_url text,
  release_notes text,
  created_at timestamptz not null default now()
);
alter table public.korelasi_versions enable row level security;
revoke all on public.korelasi_versions from anon, authenticated;
-- dibaca sebelum login juga, supaya layar wajib muncul tanpa sesi
grant select on public.korelasi_versions to anon, authenticated;
create policy korelasi_versions_baca on public.korelasi_versions
  for select to anon, authenticated using (true);
-- ditulis hanya lewat Dashboard / service role
```

## Cara merilis

1. Naikkan `version:` di `pubspec.yaml` (mis. `2.3.0+5`), PR, merge.
2. Bangun: `flutter build apk --release --split-per-abi` dan installer
   Windows (`flutter build windows --release`, lalu Inno Setup
   `installer/korelasi_installer.iss`).
3. Unggah ke folder Drive Korelasi dengan nama berversi, mis.
   `Korelasi-2.3.0+5-arm64-v8a.apk`; bagikan "siapa saja yang punya link".
4. **Terakhir**, tambah baris di `korelasi_versions` (Dashboard › Table
   Editor):
   `version = '2.3.0'`, `build_number = 5`, `android_url`, `windows_url`,
   `release_notes`, dan `force_update = true` bila versi lama harus berhenti.
   Baris ditulis paling akhir supaya pengguna tidak diarahkan ke berkas yang
   belum ada.
