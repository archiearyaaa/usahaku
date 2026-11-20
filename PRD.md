# PRD --- USAHAKU

**Product Requirements Document**\
Versi: 1.0 \| Status: Baseline rancangan \| Platform: Android

## 1. Ringkasan Produk

USAHAKU adalah aplikasi Android sederhana untuk membantu pemilik usaha
makanan dan minuman mencatat produk, stok bahan baku, penjualan,
pemasukan, pengeluaran, dan laporan usaha. Aplikasi dibuat menggunakan
Flutter dan SQLite serta mengutamakan penggunaan offline.

Aplikasi ini dikembangkan untuk mendukung kegiatan jualan dalam tugas
mata kuliah Kewirausahaan (KWU), bukan sebagai sistem ERP atau platform
multi-tenant komersial.

## 2. Latar Belakang dan Masalah

Pencatatan usaha kecil sering tersebar di buku, kalkulator, atau pesan.
Hal tersebut dapat menyulitkan pemilik untuk: - mengetahui total
penjualan dalam periode tertentu; - mengetahui pengeluaran dan
keuntungan; - menjaga catatan produk dan stok bahan baku; - menelusuri
transaksi sebelumnya; dan - membuat rekap untuk evaluasi atau tugas KWU.

USAHAKU menyatukan pencatatan inti tersebut dalam satu aplikasi lokal.

## 3. Tujuan

1.  Mempermudah pencatatan penjualan.
2.  Menyediakan data produk dan bahan baku.
3.  Mencatat pemasukan serta pengeluaran.
4.  Menampilkan ringkasan usaha dan laporan berdasarkan periode.
5.  Menghasilkan laporan PDF dan Excel.
6.  Tetap dapat digunakan tanpa koneksi internet.

## 4. Target Pengguna

-   Pengguna utama: satu pemilik/pengelola usaha.
-   Jenis usaha: usaha kecil makanan dan minuman dengan variasi produk.
-   Kemampuan teknis: pengguna umum yang membutuhkan alur sederhana.
-   Perangkat: ponsel Android.

Tidak termasuk akun karyawan, role/permission, cabang usaha, atau
penggunaan banyak perangkat pada versi 1.0.

## 5. Prinsip Produk dan UI

-   Bahasa antarmuka: Bahasa Indonesia.
-   Gaya: modern, minimalis, mudah dipahami, terinspirasi pola visual
    aplikasi modern tanpa menyalin produk lain.
-   Warna utama: `#FF2800`.
-   Latar dominan putih atau abu-abu sangat muda.
-   Gunakan ruang kosong, kartu sederhana, radius konsisten, tipografi
    jelas, dan navigasi bawah.
-   Format mata uang: Rupiah (IDR).
-   Data inti disimpan lokal.

## 6. Modul dan Fitur Utama

### 6.1 Dashboard

-   Ringkasan omzet/penjualan pada periode terpilih.
-   Ringkasan pengeluaran dan estimasi laba.
-   Jumlah transaksi.
-   Grafik penjualan sederhana.
-   Aktivitas/transaksi terbaru.
-   Filter periode: hari ini, 7 hari terakhir, bulan ini, dan rentang
    tanggal jika memungkinkan.

### 6.2 Produk

-   Tambah, lihat, ubah, dan hapus produk.
-   Nama, kategori, harga modal/HPP sederhana, harga jual, foto
    opsional, dan status aktif.
-   Pencarian dan filter kategori.
-   Stok produk jadi dapat dicatat jika usaha mengelola produk jadi.
-   Validasi harga dan nama produk.

### 6.3 Penjualan

-   Memilih satu atau beberapa produk.
-   Mengubah kuantitas dan menghapus item dari keranjang.
-   Menghitung subtotal dan total otomatis.
-   Mencatat metode pembayaran dan jumlah dibayar.
-   Menyimpan transaksi dan detail item.
-   Melihat riwayat serta detail transaksi.
-   Pengembalian/pembatalan kompleks tidak termasuk MVP; jika
    diperlukan, transaksi dikoreksi melalui alur yang tercatat, bukan
    menghapus histori diam-diam.

### 6.4 Bahan Baku dan Stok

-   Mencatat bahan baku, satuan, jumlah stok, dan batas minimum
    opsional.
-   Mencatat stok masuk dan stok keluar secara manual.
-   Melihat riwayat pergerakan stok.
-   Menampilkan peringatan stok rendah.
-   Konversi satuan otomatis dan resep belum termasuk MVP.

### 6.5 Keuangan

-   Mencatat pemasukan tambahan/non-penjualan.
-   Mencatat pengeluaran beserta kategori, tanggal, nominal, dan
    catatan.
-   Mencatat modal awal sebagai informasi modal, bukan omzet penjualan.
-   Melihat riwayat pemasukan dan pengeluaran.

### 6.6 Laporan

-   Rekap penjualan, pengeluaran, dan pemasukan berdasarkan periode.
-   Ringkasan laba sederhana berdasarkan data yang tersedia.
-   Laporan stok bahan baku.
-   Ekspor PDF dan Excel.
-   Laporan menjelaskan periode dan waktu pembuatan.

### 6.7 Pengaturan

-   Nama usaha dan informasi dasar.
-   Preferensi sederhana aplikasi.
-   Backup dan restore lokal sebagai fitur setelah MVP, jika waktu
    memungkinkan.

## 7. Definisi dan Aturan Perhitungan

-   **Omzet penjualan** = jumlah nilai penjualan yang tercatat pada
    periode, setelah diskon jika diskon diterapkan.
-   **Pemasukan non-penjualan** dicatat terpisah dan tidak digabung
    sebagai omzet.
-   **Pengeluaran** = biaya yang dicatat pengguna.
-   **Laba sederhana** = omzet penjualan − HPP/biaya modal barang
    terjual − biaya usaha yang dicatat. Jika HPP belum diisi, aplikasi
    harus memberi label bahwa laba belum lengkap atau menggunakan
    perhitungan sementara yang dijelaskan.
-   **Modal pemilik** bukan pendapatan penjualan.
-   Pembelian bahan baku tidak boleh dihitung ganda sebagai pengeluaran
    dan HPP pada laporan laba. Pada versi awal, aplikasi harus
    menetapkan perlakuan pencatatan yang konsisten dan menjelaskan
    batasannya.
-   Nilai uang disimpan sebagai integer satuan Rupiah, bukan floating
    point.

## 8. MVP dan Prioritas

### MVP --- wajib untuk versi pertama

1.  Navigasi lima menu: Home, Jualan, Produk, Keuangan, Laporan.
2.  CRUD produk dan kategori.
3.  CRUD bahan baku serta pencatatan stok masuk/keluar.
4.  Pencatatan penjualan dengan item transaksi.
5.  Pencatatan pemasukan dan pengeluaran.
6.  Dashboard dari data SQLite sebenarnya.
7.  Laporan periode dasar.
8.  Ekspor PDF dan Excel.
9.  Validasi input dan penanganan error.
10. Pengujian alur utama.

### Setelah MVP --- jika waktu dan kebutuhan mendukung

-   Foto produk.
-   Backup/restore file lokal.
-   Resep dan pengurangan bahan otomatis.
-   Barcode dan printer Bluetooth.
-   Grafik atau analisis tambahan.
-   Sinkronisasi cloud.

## 9. Di Luar Ruang Lingkup

-   Multi-user, login online, dan hak akses karyawan.
-   Payroll, absensi, shift, dan HR.
-   Multi-cabang dan multi-gudang.
-   Integrasi pembayaran/QRIS langsung.
-   Integrasi marketplace atau layanan pesan antar.
-   Akuntansi penuh, pajak kompleks, dan laporan standar perusahaan.
-   AI rekomendasi bisnis.
-   Sinkronisasi cloud wajib.

## 10. Kriteria Keberhasilan

-   Pengguna dapat menambah dan mengubah produk.
-   Pengguna dapat mencatat transaksi dengan beberapa item.
-   Data tetap tersedia setelah aplikasi ditutup dan dibuka kembali.
-   Stok bahan berubah sesuai catatan stok masuk/keluar.
-   Dashboard dan laporan mengambil data dari database, bukan angka
    contoh.
-   Total transaksi dan rekap periode sesuai dengan data uji.
-   PDF dan Excel dapat dibuat dan dibuka.
-   Aplikasi dapat menjalankan alur utama tanpa internet.

## 11. Asumsi dan Risiko

-   Aplikasi digunakan pada satu perangkat Android oleh satu pemilik.
-   Pengguna bertanggung jawab memasukkan data yang benar.
-   Backup manual diperlukan untuk mengurangi risiko kehilangan data.
-   Perhitungan laba bergantung pada kelengkapan HPP dan pengeluaran
    yang dicatat.
-   Foto dan file ekspor harus disimpan pada lokasi yang dapat diakses
    aplikasi dengan izin yang sesuai.

## 12. Keputusan yang Belum Dikunci

-   Apakah stok produk jadi juga perlu dikelola selain stok bahan baku.
-   Apakah transaksi penjualan mengurangi stok produk jadi.
-   Format dan isi struk.
-   Kategori pengeluaran bawaan.
-   Detail formula laba yang akan dipakai pada implementasi final.

Keputusan yang belum dikunci harus dikonfirmasi sebelum implementasi
yang bergantung padanya.
