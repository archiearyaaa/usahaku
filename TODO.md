# TODO --- USAHAKU

**Task Management**\
Status: baseline backlog. Perbarui setiap kali pekerjaan benar-benar
selesai.

## Konvensi

-   Status: `[ ]` Belum dikerjakan, `[-]` Sedang dikerjakan, `[x]`
    Selesai, `[!]` Terhambat.
-   Prioritas: **P0** wajib untuk MVP, **P1** penting, **P2** tambahan.
-   Jangan tandai selesai hanya karena UI dibuat. Kriteria penerimaan
    dan pengujian harus terpenuhi.

## 1. Fondasi Proyek

-   [x] **P0** Periksa Flutter SDK dan kondisi proyek saat ini.
    -   Selesai jika `flutter doctor` relevan dan `flutter analyze`
        tidak memiliki error baru.
-   [x] **P0** Buat struktur folder sesuai ARCHITECTURE.md.
    -   Selesai jika folder inti tersedia dan import berjalan.
-   [x] **P0** Buat design system warna, tema, typography, dan komponen
    dasar.
    -   Selesai jika warna utama `#FF2800` konsisten dan tema dapat
        digunakan.
-   [x] **P0** Implementasikan navigasi lima menu.
    -   Selesai jika semua menu dapat dibuka dan state navigasi benar.
-   [x] **P0** Siapkan SQLite dan inisialisasi schema.
    -   Selesai jika database dibuat dan tabel MVP tersedia.

## 2. Produk dan Kategori

-   [x] **P0** CRUD kategori.
    -   Selesai jika tambah, tampil, ubah, hapus tervalidasi dan
        tersimpan.
-   [x] **P0** CRUD produk.
    -   Selesai jika nama, harga modal, harga jual, kategori, dan status
        tersimpan.
-   [x] **P0** Pencarian dan filter produk.
    -   Selesai jika hasil sesuai kata kunci/kategori.
-   [ ] **P1** Foto produk.
    -   Selesai jika gambar dapat dipilih, ditampilkan, dan path tetap
        valid setelah aplikasi dibuka ulang.

## 3. Bahan Baku dan Stok

-   [x] **P0** CRUD bahan baku.
    -   Selesai jika nama, satuan, jumlah, dan stok minimum tersimpan.
-   [x] **P0** Stok masuk dan keluar.
    -   Selesai jika saldo berubah benar dan movement tercatat.
-   [x] **P0** Validasi stok keluar.
    -   Selesai jika jumlah keluar tidak dapat membuat stok negatif
        kecuali kebijakan khusus disetujui.
-   [x] **P1** Peringatan stok minimum.
    -   Selesai jika bahan di bawah batas minimum ditandai.

## 4. Penjualan

-   [x] **P0** Daftar produk untuk kasir.
    -   Selesai jika produk aktif dapat dicari dan dipilih.
-   [x] **P0** Keranjang dan kuantitas.
    -   Selesai jika item dapat ditambah, diubah, dan dihapus.
-   [x] **P0** Kalkulasi subtotal, diskon, total, pembayaran, dan
    kembalian.
    -   Selesai jika unit test kalkulasi lulus.
-   [x] **P0** Simpan transaksi dan detail secara atomik.
    -   Selesai jika transaksi dan semua item tersimpan bersama atau
        seluruh operasi dibatalkan.
-   [x] **P0** Riwayat dan detail transaksi.
    -   Selesai jika transaksi lama dapat dilihat dengan snapshot
        harga/nama.
-   [ ] **P1** Cetak atau bagikan struk.
    -   Selesai jika format struk dapat dibuat dan dibagikan.

## 5. Keuangan

-   [x] **P0** CRUD pemasukan tambahan.
    -   Selesai jika data tersimpan dan filter tanggal bekerja.
-   [x] **P0** CRUD pengeluaran.
    -   Selesai jika kategori, tanggal, nominal, dan catatan tersimpan.
-   [x] **P0** Ringkasan keuangan.
    -   Selesai jika total berasal dari query database dan periode
        benar.
-   [x] **P1** Modal awal.
    -   Selesai jika modal dicatat terpisah dari omzet dan laba.

## 6. Dashboard

-   [x] **P0** Kartu ringkasan omzet, pengeluaran, laba sederhana, dan
    transaksi.
    -   Selesai jika angka sesuai query database untuk periode aktif.
-   [x] **P1** Grafik penjualan.
    -   Selesai jika grafik memakai data transaksi nyata dan menangani
        data kosong.
-   [x] **P1** Aktivitas terbaru.
    -   Selesai jika urutan dan detail aktivitas benar.

## 7. Laporan

-   [x] **P0** Filter periode laporan.
    -   Selesai jika tanggal awal/akhir diterapkan konsisten.
-   [x] **P0** Laporan penjualan dan pengeluaran.
    -   Selesai jika total cocok dengan data sumber.
-   [x] **P0** Laporan laba sederhana dengan penjelasan komponen.
    -   Selesai jika perhitungan diuji dan keterbatasan HPP dijelaskan.
-   [x] **P0** Ekspor PDF.
    -   Selesai jika PDF berhasil dibuat dan dapat dibuka.
-   [x] **P0** Ekspor Excel.
    -   Selesai jika workbook berhasil dibuat dan dapat dibuka.

## 8. Kualitas dan Rilis

-   [x] **P0** Empty state, loading, dan error state pada halaman data.
    -   Selesai jika ketiga kondisi ditangani.
-   [x] **P0** Validasi form dan konfirmasi tindakan destruktif.
    -   Selesai jika input tidak valid ditolak dengan pesan yang jelas.
-   [x] **P0** Unit test kalkulasi.
    -   Selesai jika seluruh test relevan lulus.
-   [x] **P0** Database/repository test.
    -   Selesai jika CRUD, relasi, dan transaksi atomik diuji.
-   [x] **P0** Jalankan `flutter analyze` dan `flutter test`.
    -   Selesai jika tidak ada error dan semua test lulus.
-   [x] **P0** Uji manual pada perangkat Android.
    -   Selesai jika alur utama berhasil tanpa internet.
-   [x] **P0** Build APK release.
    -   Selesai jika APK berhasil dibuat dan dipasang untuk uji.

## 9. Fitur Setelah MVP

-   [ ] **P2** Resep produk dan pengurangan bahan otomatis.
-   [ ] **P2** Backup dan restore lokal.
-   [ ] **P2** Barcode.
-   [ ] **P2** Printer Bluetooth.
-   [ ] **P2** Sinkronisasi cloud opsional.

## Catatan Progres

- 2026-11-21: Peningkatan Fitur Satuan Produk, Paket Terhubung (Bundling Stock), dan Identitas Hak Cipta.
  - Satuan Produk (Unit): Menambahkan dukungan satuan produk (`porsi`, `pcs`, `gelas`, `cup`, `buah`, `bungkus`, `paket`, dan input bebas). Migrasi skema SQLite ke versi 2 (`AppConstants.databaseVersion = 2`) dengan `ALTER TABLE products ADD COLUMN unit TEXT NOT NULL DEFAULT 'porsi'`. Tampilan satuan terintegrasi di Form Produk, Katalog Produk, dan Halaman Kasir (POS).
  - Paket Terhubung (Bundling Stock): Menambahkan tabel `product_bundles` dan migrasi database. Produk paket dapat dirangkai dari beberapa item komponen (misal: Paket Misopa = 2 pcs Misopa + 1 gelas Teh). Stok paket dihitung otomatis secara real-time dari stok minimum komponen yang tersedia (`MIN(item.stock / pb.quantity)`). Saat paket terjual di kasir POS, stok masing-masing komponen dipotong secara otomatis dalam transaksi atomik SQLite.
  - Identitas Hak Cipta: Menambahkan informasi pengembang "Copyright by Archie Arya Manggala" di `AppConstants`, dialog Tentang Aplikasi & footer halaman Dashboard, serta footer dokumen cetak Laporan PDF.
  - Verifikasi: 49 unit & widget tests lulus 100%, `flutter analyze` 0 issue.

- 2026-11-20: Tahap 8 (Kualitas dan Rilis - All P0) selesai dan terverifikasi.
  - Penanganan State: Seluruh 5 halaman navigasi dan sub-halamannya (Dashboard, Jualan/POS, Produk & Bahan, Keuangan, Laporan) menangani kondisi loading (`CircularProgressIndicator`), empty state informatif dengan aksi tombol tambah/catat, dan penanganan error `try/catch` dengan visual SnackBar merah.
  - Validasi & Keamanan Aksi: Semua form memiliki validator ketat (nama wajib, nominal/stok >= 0, kuantitas keluar <= stok bahan, uang bayar tunai >= total belanja). Tindakan destruktif (hapus produk, hapus kategori, hapus bahan baku, hapus transaksi penjualan, hapus pengeluaran, hapus pemasukan lain) memiliki konfirmasi dialog eksplisit dengan opsi Batal dan Hapus.
  - Offline-First: 100% data tersimpan di SQLite lokal tanpa memerlukan jaringan internet atau backend eksternal, sesuai mandat PRD dan AGENTS.md.
  - Integrasi Aset & Logo: Gambar logo resmi USAHAKU berhasil diintegrasikan ke aset aplikasi (`assets/images/logo.png`), header toko di Dashboard, serta ikon aplikasi Android untuk seluruh kepadatan layar (`mipmap-mdpi`, `mipmap-hdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`).
  - Verifikasi: `flutter analyze` (0 issue / `No issues found!`), 48 unit & widget tests lulus (`All tests passed!`).
  - Build Rilis: Kompilasi APK rilis sukses melalui Gradle (`build/app/outputs/flutter-apk/app-release.apk`, ukuran 53.6 MB) dan berhasil dipasang serta diuji langsung pada perangkat Android fisik.

- 2026-11-20: Tahap 7 (Laporan - All P0) selesai dan terverifikasi.
  - Model & Agregat: `ReportSummaryModel` (kalkulasi laba kotor, laba sederhana, margin laba, omzet penjualan, total HPP, total pengeluaran operasional, total pemasukan lain).
  - Repository SQLite: `ReportRepository` memuat rekap terpadu dari database lokal berdasarkan rentang filter tanggal secara konsisten.
  - Layanan Ekspor: `PdfExportService` (menghasilkan dokumen PDF berstandar A4 dengan header identitas usaha `#FF2800`, tabel ringkasan laba rugi, rekap transaksi penjualan, rekap beban operasional, dan catatan metodologi laba), `ExcelExportService` (menghasilkan spreadsheet XLSX multi-sheet: 'Laba Rugi', 'Penjualan', dan 'Pengeluaran').
  - Komponen UI: `ReportsPage` (filter periode Hari Ini, 7 Hari, Bulan Ini, Bulan Lalu, Kustom date picker; kartu sorotan laba sederhana; tab bar Laba Rugi, Penjualan, Pengeluaran; bottom sheet unduh berkas PDF & XLSX dengan informasi lokasi berkas dan snackbar konfirmasi).
  - Verifikasi: `dart format`, `flutter analyze` (0 issue), 48 unit & widget tests lulus (termasuk validasi header PDF `%PDF`, header Excel `PK`, kalkulasi agregat periode, dan pengujian halaman).

- 2026-11-20: Tahap 6 (Dashboard - P0 & P1) selesai dan terverifikasi.
  - Model & Agregat: `DashboardMetrics` (omzet, transaksi, HPP dari sale_items, pengeluaran, laba kotor & laba sederhana), `DailySalesPoint` (data grafik harian), `DashboardActivityItem` (feed aktivitas gabungan).
  - Repository SQLite: `DashboardRepository` menghitung metrik periode, data tren harian 7 hari (menangani hari tanpa transaksi dengan angka 0), dan menggabungkan aktivitas penjualan & pengeluaran terbaru.
  - Komponen UI: `DashboardPage` (header toko & tanggal, filter periode Hari Ini/7 Hari/Bulan Ini, 4 kartu ringkasan omzet/biaya/laba/transaksi, pull-to-refresh), `SalesBarChartWidget` (grafik batang responsif visualisasi tren penjualan harian 7 hari dengan penanganan data kosong).
  - Verifikasi: `dart format`, `flutter analyze` (0 issue), 44 unit & widget tests lulus (termasuk agregasi SQLite HPP & laba, chart data generator, recent activities ordering, dan widget testing).
- 2026-11-20: Tahap 5 (Keuangan - P0 & P1) selesai dan terverifikasi.
  - Model & Agregat: `IncomeModel`, `ExpenseModel`, `FinanceSummaryModel` (kalkulasi kas masuk, kas keluar, arus kas bersih, dan pemisahan modal awal).
  - Repository SQLite: `IncomeRepository` (CRUD, filter periode, pencarian, kalkulasi total, pemisahan modal awal), `ExpenseRepository` (CRUD, filter periode & kategori, pencarian, kalkulasi total biaya).
  - Komponen UI: `FinancePage` (kartu ringkasan arus kas bersih, chip filter periode Hari Ini/Bulan Ini/Semua, sub-tab Pengeluaran & Pemasukan Lain, sheet tambah cepat), `ExpenseFormPage` (tambah/edit/hapus pengeluaran dengan kategori & date picker), `IncomeFormPage` (tambah/edit/hapus pemasukan lain/modal awal dengan kategori & date picker).
  - Verifikasi: `dart format`, `flutter analyze` (0 issue), 40 unit & widget tests lulus (termasuk integritas CRUD, query kalkulasi agregat periode, filter pencarian, dan UI tab arus kas).
- 2026-11-20: Tahap 4 (Penjualan - P0) selesai dan terverifikasi.
  - Model & Bisnis Kalkulasi: `CartItemModel`, `SaleModel`, `SaleItemModel`, `SalesCalculation` (kalkulasi subtotal, diskon, total, kembalian, dan modal semua berbasis integer Rupiah).
  - Repository & Transaksi Atomik: `SaleRepository.createSale` menyimpan header `sales` dan detail `sale_items` (snapshot nama & harga) serta update stok produk secara atomik dalam 1 transaksi SQLite. Generator nomor faktur berurutan `INV-YYYYMMDD-XXXX`.
  - Komponen UI: `SalesPage` (POS kasir, pencarian cepat produk aktif, filter kategori, badge kuantitas keranjang, bar pembayaran melayang), `CheckoutPage` (review pesanan, diskon Rp, metode bayar Tunai/Transfer/QRIS, hitung kembalian instan, tombol uang cepat, dialog sukses), `SalesHistoryPage` (daftar riwayat nota dengan filter tanggal Hari Ini/7 Hari/Bulan Ini/Semua), `SaleDetailPage` (tampilan nota digital detail dengan snapshot item, total, pembayaran, kembalian, dan catatan).
  - Verifikasi: `dart format`, `flutter analyze` (0 issue), 37 unit & widget tests lulus (termasuk kalkulasi bisnis, invoice generator, transaksi atomik rollback, cascade delete, dan alur kasir POS).
- 2026-11-20: Tahap 3 (Bahan Baku dan Stok - P0 & P1) selesai dan terverifikasi.
  - Model & Repository: `MaterialModel`, `StockMovementModel`, `MaterialRepository`, `StockMovementRepository`.
  - Transaksi Atomik: `StockMovementRepository.addMovement` memutakhirkan saldo bahan dan movement dalam 1 transaksi SQLite dengan pencegahan stok negatif.
  - Komponen UI: `MaterialsPage` (pencarian, indikator peringatan stok rendah, pull-to-refresh, empty state), `MaterialFormPage` (tambah/edit/hapus bahan baku dengan validasi), `StockMovementPage` (stok masuk/keluar dengan validasi kuantitas <= stok saat keluar, riwayat mutasi stok), `ProductsTabPage` (sub-tab Produk & Bahan Baku).
  - Verifikasi: `dart format`, `flutter analyze` (0 issue), 26 unit & widget tests lulus (termasuk validasi pencegahan stok negatif, rollback transaksi, cascade delete, dan filter pencarian).
- 2026-11-20: Tahap 2 (Produk dan Kategori - P0) selesai dan terverifikasi.
  - Model & Repository: `CategoryModel`, `ProductModel`, `CategoryRepository`, `ProductRepository`.
  - Komponen UI: `CategoryManageDialog` (CRUD kategori, konfirmasi hapus), `ProductFormPage` (tambah/edit produk, validasi nama & harga jual > 0, HPP, stok, switch aktif), `ProductsPage` (search bar, filter category chips, empty state, card list).
  - Verifikasi: `dart format`, `flutter analyze` (0 issue), 16 unit & widget tests lulus (termasuk CRUD relasi SQLite dan search/filter).
- 2026-11-20: Tahap 1 (Fondasi Proyek) selesai dan terverifikasi.
  - Struktur folder architecture dibuat lengkap.
  - Dependensi dasar ditambahkan: `intl`, `sqflite`, `path`, dan `sqflite_common_ffi` (dev).
  - Design system warna `#FF2800`, Material 3 theme, CurrencyFormatter (integer Rupiah), dan DateFormatter diimplementasikan.
  - Navigasi 5 menu utama (Home, Jualan, Produk, Keuangan, Laporan) diimplementasikan dan diuji.
  - Inisialisasi skema 9 tabel SQLite (`usahaku.db`) selesai dengan Foreign Keys ON.
  - Verifikasi: `dart format`, `flutter analyze` (0 issue), dan 12 unit/widget tests lulus.
