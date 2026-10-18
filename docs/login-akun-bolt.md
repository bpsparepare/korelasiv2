# Login akun Bolt (2.2.0)

Sejak **2.2.0+4** (BOLT-40 sub-sesi 2 di repo Bolt) Korelasi login memakai
**akun Bolt** (Supabase Auth, proyek `iubeqsafpibmousxvmfk`), bukan lagi
username + sandi di tabel `korelasi_login`.

## Cara login

- **Email + sandi** akun Bolt: `auth.signInWithPassword`.
- **Google**: `auth.signInWithOAuth(OAuthProvider.google, redirectTo: …)`.
  Browser membuka halaman Google, lalu kembali ke aplikasi lewat alamat balik
  di bawah; `supabase_flutter` menukar kodenya menjadi sesi.
- Akun baru **hanya** dibuat lewat Bolt (layar daftar sudah dihapus). Lupa
  sandi, atau akun yang hanya pernah login Google dan ingin sandi: atur lewat
  Bolt.

## Alamat balik (redirect URL)

`korelasi://login-callback` — konstanta `alamatBalikLogin` di
`lib/services/sesi_korelasi.dart`. Harus ada di Dashboard Supabase ›
Authentication › URL Configuration › **Redirect URLs**; tanpa itu Supabase
mengembalikan browser ke Site URL dan login Google tidak kembali ke aplikasi.

Skema `korelasi://` dipasang di:

| Platform | Tempat |
|---|---|
| Android | `android/app/src/main/AndroidManifest.xml` (intent-filter `VIEW`, host `login-callback`) |
| Windows | `windows/runner/main.cpp`: mendaftarkan `HKCU\Software\Classes\korelasi` setiap kali aplikasi jalan, dan meneruskan tautan ke jendela Korelasi yang sudah terbuka (`SendAppLink` dari `app_links`) |
| iOS, macOS | `CFBundleURLTypes` di `Info.plist` |
| Web | kembali ke asal halaman (`Uri.base.origin`); asal itu juga harus didaftarkan bila web dipakai |

## Sesi

- Sesi disimpan `supabase_flutter` (bukan `SharedPreferences`; dependensi
  `shared_preferences` sudah dibuang). `SesiKorelasi.mulai()` dipanggil dari
  splash: memeriksa `auth.currentSession`, lalu mengikuti
  `onAuthStateChange` (`signedIn` → Beranda, `signedOut` → Login).
- Sesudah login, baris `korelasi_login` dicari dengan RPC `korelasi_saya()`
  (memakai `korelasi_login.auth_user_id`, migrasi 0015 di repo Bolt). Kosong →
  "Akun belum ditautkan ke Korelasi, hubungi admin." lalu `auth.signOut()`.
- `SesiKorelasi.pengguna` (id, nama, username, peran) dipakai keranjang
  (`id_pelanggan`, `nama_pembeli`), riwayat, dan kelola stok
  (`admin_update_stock.p_user_id`). `korelasi_login.id` tetap menjadi
  `id_pelanggan` pesanan.
- Peran admin berasal dari baris yang diambil dari server setiap kali aplikasi
  dibuka, bukan dari nilai yang tersimpan di perangkat.
- Keluar = `auth.signOut()`.

## Sandi

- Kolom `korelasi_login.password` tidak lagi dibaca atau ditulis aplikasi.
- **Ganti Password** di Profil mengubah sandi akun Bolt: sandi lama diperiksa
  dengan `signInWithPassword` ulang, lalu `auth.updateUser`. Berlaku juga
  untuk login di Bolt.
- Admin tidak bisa lagi melihat sandi pengguna (konfirmasi sandi admin ikut
  dihapus karena tidak ada tindakan lain yang memakainya).

## Yang dihapus di 2.2.0

`register_screen.dart`, tampilan sandi di `user_detail_screen.dart`,
`database_manager_screen.dart` + `pluto_grid_adapter.dart` (RPC
`get_table_schema`), `lib/services/api_service.dart`, berkas sisa `*_hp.txt`,
dependensi `http`, `shared_preferences`, `pluto_grid`.

## Fitur admin

Produk, stok, rekap, dan kelola pengguna **tetap** sampai 2.3.0. Sesudah
bagian admin dipakai di Bolt (BOLT-41), 2.3.0 menghapusnya dan Korelasi jadi
aplikasi pengguna saja.

## Versi lama

Sesudah migrasi 0016 (repo Bolt) dijalankan, akses `anon` ditutup: versi
**2.1.x ke bawah tidak bisa dipakai lagi** dan pengguna harus memasang 2.2.0.
