# USAHAKU

Aplikasi pencatatan usaha dan kasir (*Point of Sale*) mandiri untuk UMKM kuliner / F&B (*Food & Beverage*). Didesain dengan prinsip **offline-first**, sederhana, cepat, dan akurat tanpa memerlukan koneksi internet.

Dikembangkan oleh **Archie Arya Manggala**.

---

## Fitur Utama

1. **Kasir & Transaksi Cepat (POS)**
   - Pencarian produk instan dan filter kategori.
   - Keranjang belanja interaktif dengan kalkulasi otomatis subtotal, diskon rupiah, dan hitung kembalian tunai / non-tunai.
   - Cetak dan simpan struk/nota digital dengan snapshot riwayat harga dan item.

2. **Katalog Produk, Kategori & Satuan**
   - Manajemen produk dengan harga jual, HPP (modal), dan stok.
   - Pilihan satuan fleksibel: `porsi`, `pcs`, `gelas`, `cup`, `buah`, `bungkus`, `paket`, atau satuan kustom.
   - Kategori produk default otomatis (Makanan, Minuman, Paket, Camilan).

3. **Paket Terhubung (*Bundling Stock*)**
   - Jual produk paket/kombo yang terdiri dari beberapa item sekaligus.
   - Stok paket dihitung secara dinamis mengikuti sisa stok terkecil dari komponen penyusunnya.
   - Pemotongan stok komponen terjadi otomatis secara atomik saat paket terjual di kasir.

4. **Bahan Baku & Kontrol Stok**
   - Catat stok bahan baku masuk dan keluar.
   - Validasi ketat pencegahan stok negatif.
   - Indikator peringatan dini stok menipis di bawah batas minimum.

5. **Pencatatan Keuangan & Arus Kas**
   - Pencatatan biaya operasional harian berdasarkan kategori.
   - Pencatatan pemasukan lain dan pemisahan modal awal dari omzet usaha.
   - Tampilan ringkasan arus kas bersih real-time.

6. **Dashboard Analitik**
   - Ringkasan omzet, total pengeluaran, laba sederhana, dan jumlah transaksi.
   - Grafik tren penjualan 7 hari terakhir.
   - Feed riwayat aktivitas bisnis terkini.

7. **Laporan & Ekspor Berkas**
   - Filter periode: Hari Ini, 7 Hari Terakhir, Bulan Ini, Bulan Lalu, atau rentang kustom.
   - Laporan Laba Rugi, rekapitulasi penjualan, dan rincian pengeluaran.
   - Ekspor laporan resmi ke format **PDF** dan spreadsheet **Excel (XLSX)**.

8. **Offline-First & Aman**
   - 100% data tersimpan di penyimpanan lokal perangkat menggunakan SQLite (`usahaku.db`).
   - Tidak memerlukan server luar, tidak mengirim data pribadi usaha ke internet, dan bebas biaya langganan.

---

## Teknologi yang Digunakan

- **Framework:** [Flutter](https://flutter.dev) (Dart SDK)
- **Database:** SQLite via [`sqflite`](https://pub.dev/packages/sqflite) dengan integritas *foreign key* dan transaksi atomik.
- **State & Formatting:** [`intl`](https://pub.dev/packages/intl) dengan kalkulasi moneter berbasis integer Rupiah (menghindari *floating-point error*).
- **Laporan & Dokumen:** [`pdf`](https://pub.dev/packages/pdf), [`excel`](https://pub.dev/packages/excel), [`path_provider`](https://pub.dev/packages/path_provider).

---

## Cara Menjalankan

### Prasyarat
- Flutter SDK (3.24+ disarankan)
- Android SDK & Java JDK 17+

### Menjalankan di Mode Debug
```bash
flutter pub get
flutter run
```

### Memverifikasi Kode & Menjalankan Pengujian
```bash
flutter analyze
flutter test
```

### Build APK Rilis
```bash
flutter build apk --release
```
Berkas APK rilis akan tersedia di `build/app/outputs/flutter-apk/app-release.apk`.

---

## Lisensi & Hak Cipta

© 2026 **USAHAKU** by Archie Arya Manggala. All rights reserved.
