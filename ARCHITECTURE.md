# ARCHITECTURE --- USAHAKU

**Technical Architecture**\
Versi: 1.0 \| Status: Baseline rancangan

## 1. Gambaran Arsitektur

USAHAKU adalah aplikasi Flutter Android offline-first dengan SQLite
lokal. Untuk skala proyek ini, gunakan arsitektur fitur sederhana: UI,
layanan/domain seperlunya, dan repository/database. Hindari abstraksi
berlebihan.

Aliran umum:

`Screen/Widget → Provider/Controller sederhana → Repository → SQLite`

Pada tahap awal, `setState` dapat digunakan untuk state lokal yang
kecil. Untuk data lintas halaman, gunakan pola state yang konsisten;
jangan memperkenalkan state-management library baru tanpa alasan dan
persetujuan.

## 2. Teknologi

-   Flutter dan Dart: aplikasi Android.
-   Material 3: komponen UI.
-   SQLite melalui `sqflite`: penyimpanan lokal.
-   `path`: penentuan lokasi file database.
-   `intl`: format Rupiah dan tanggal.
-   `fl_chart`: grafik.
-   `image_picker`: foto produk opsional.
-   `pdf`: pembuatan PDF.
-   `excel`: pembuatan file Excel.

Tambahkan dependency hanya ketika fitur terkait akan dikerjakan. Periksa
kompatibilitas versi dengan Flutter SDK proyek sebelum mengubah
`pubspec.yaml`.

## 3. Struktur Folder yang Disarankan

``` text
lib/
├── main.dart
├── app/
│   └── app.dart
├── core/
│   ├── constants/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── database_helper.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   └── date_formatter.dart
│   └── widgets/
├── features/
│   ├── dashboard/
│   │   ├── data/
│   │   └── presentation/
│   ├── products/
│   │   ├── data/
│   │   └── presentation/
│   ├── sales/
│   │   ├── data/
│   │   └── presentation/
│   ├── materials/
│   │   ├── data/
│   │   └── presentation/
│   ├── finance/
│   │   ├── data/
│   │   └── presentation/
│   └── reports/
│       ├── data/
│       └── presentation/
└── shared/
    └── widgets/
test/
```

Setiap fitur boleh dimulai sederhana. Buat folder atau layer tambahan
hanya jika memang dibutuhkan.

## 4. Navigasi dan Hubungan Fitur

Navigasi utama: 1. Home --- ringkasan data. 2. Jualan --- membuat
transaksi dan melihat riwayat. 3. Produk --- produk, kategori, dan bahan
baku. 4. Keuangan --- pemasukan dan pengeluaran. 5. Laporan --- rekap
dan ekspor.

Hubungan data: - Kategori memiliki banyak produk. - Penjualan memiliki
banyak item penjualan. - Item penjualan mengacu pada produk. - Bahan
baku memiliki banyak pergerakan stok. - Pemasukan dan pengeluaran
menjadi sumber data dashboard/laporan. - Dashboard dan laporan membaca
data dari repository; keduanya tidak menyimpan salinan angka agregat
yang bisa berbeda dari transaksi sumber.

## 5. Rancangan Database SQLite

Nama database yang disarankan: `usahaku.db`. Gunakan foreign key dan
transaksi database untuk operasi multi-tabel.

### 5.1 Tabel `categories`

-   `id` INTEGER PRIMARY KEY AUTOINCREMENT
-   `name` TEXT NOT NULL
-   `created_at` TEXT NOT NULL

### 5.2 Tabel `products`

-   `id` INTEGER PRIMARY KEY AUTOINCREMENT
-   `category_id` INTEGER NULL, FK ke categories
-   `name` TEXT NOT NULL
-   `description` TEXT NULL
-   `cost_price` INTEGER NOT NULL DEFAULT 0
-   `selling_price` INTEGER NOT NULL
-   `stock` INTEGER NOT NULL DEFAULT 0
-   `is_active` INTEGER NOT NULL DEFAULT 1
-   `image_path` TEXT NULL
-   `created_at` TEXT NOT NULL
-   `updated_at` TEXT NOT NULL

`stock` produk dapat digunakan jika pemilik memang mencatat stok produk
jadi. Jangan menganggap stok bahan baku otomatis terhubung ke produk
sebelum fitur resep dibuat.

### 5.3 Tabel `materials`

-   `id` INTEGER PRIMARY KEY AUTOINCREMENT
-   `name` TEXT NOT NULL
-   `unit` TEXT NOT NULL
-   `quantity` REAL NOT NULL DEFAULT 0
-   `minimum_stock` REAL NULL
-   `created_at` TEXT NOT NULL
-   `updated_at` TEXT NOT NULL

Gunakan satuan yang konsisten per bahan. Konversi otomatis antar satuan
belum termasuk MVP.

### 5.4 Tabel `stock_movements`

-   `id` INTEGER PRIMARY KEY AUTOINCREMENT
-   `material_id` INTEGER NOT NULL, FK ke materials
-   `type` TEXT NOT NULL (`in`, `out`, `adjustment`)
-   `quantity` REAL NOT NULL
-   `note` TEXT NULL
-   `movement_date` TEXT NOT NULL
-   `created_at` TEXT NOT NULL

Setiap perubahan stok bahan dicatat sebagai movement dan memperbarui
saldo bahan dalam satu transaksi database.

### 5.5 Tabel `sales`

-   `id` INTEGER PRIMARY KEY AUTOINCREMENT
-   `invoice_number` TEXT NOT NULL UNIQUE
-   `sale_date` TEXT NOT NULL
-   `subtotal` INTEGER NOT NULL
-   `discount` INTEGER NOT NULL DEFAULT 0
-   `total` INTEGER NOT NULL
-   `payment_method` TEXT NOT NULL
-   `amount_paid` INTEGER NOT NULL
-   `change_amount` INTEGER NOT NULL DEFAULT 0
-   `note` TEXT NULL
-   `created_at` TEXT NOT NULL

### 5.6 Tabel `sale_items`

-   `id` INTEGER PRIMARY KEY AUTOINCREMENT
-   `sale_id` INTEGER NOT NULL, FK ke sales
-   `product_id` INTEGER NULL, FK ke products
-   `product_name` TEXT NOT NULL
-   `quantity` INTEGER NOT NULL
-   `unit_price` INTEGER NOT NULL
-   `unit_cost` INTEGER NOT NULL DEFAULT 0
-   `line_total` INTEGER NOT NULL

Simpan nama, harga jual, dan biaya per unit sebagai snapshot agar
perubahan data produk tidak mengubah transaksi lama.

### 5.7 Tabel `expenses`

-   `id` INTEGER PRIMARY KEY AUTOINCREMENT
-   `title` TEXT NOT NULL
-   `category` TEXT NOT NULL
-   `amount` INTEGER NOT NULL
-   `expense_date` TEXT NOT NULL
-   `note` TEXT NULL
-   `created_at` TEXT NOT NULL

### 5.8 Tabel `income`

-   `id` INTEGER PRIMARY KEY AUTOINCREMENT
-   `title` TEXT NOT NULL
-   `category` TEXT NOT NULL
-   `amount` INTEGER NOT NULL
-   `income_date` TEXT NOT NULL
-   `note` TEXT NULL
-   `created_at` TEXT NOT NULL

Pemasukan non-penjualan dipisahkan dari transaksi penjualan.

### 5.9 Tabel `settings`

-   `key` TEXT PRIMARY KEY
-   `value` TEXT NULL

Simpan profil usaha dan preferensi sederhana sebagai pasangan key-value.

## 6. Aturan Database

-   Aktifkan `PRAGMA foreign_keys = ON`.
-   Gunakan integer untuk nominal Rupiah.
-   Gunakan format tanggal ISO 8601 yang konsisten.
-   Gunakan parameterized query, bukan menggabungkan input pengguna ke
    SQL.
-   Gunakan database transaction untuk menyimpan penjualan dan itemnya.
-   Jangan menghapus transaksi historis secara permanen tanpa alur
    koreksi yang disetujui.
-   Terapkan `onUpgrade`/migrasi ketika schema berubah.
-   Jangan mengubah database produksi dengan menghapus file database
    sebagai jalan pintas.
-   Tambahkan index pada kolom tanggal dan foreign key jika query
    memerlukannya.

## 7. Perhitungan dan Konsistensi

-   Total item = kuantitas × harga satuan.
-   Subtotal = jumlah seluruh total item.
-   Total transaksi = subtotal − diskon.
-   Kembalian = jumlah dibayar − total, tidak boleh negatif untuk
    transaksi lunas.
-   Omzet dihitung dari transaksi penjualan pada periode.
-   Pemasukan tambahan terpisah dari omzet.
-   Laba harus diberi label sesuai data yang tersedia. Laba sederhana
    dapat dihitung dari total penjualan dikurangi HPP item dan biaya
    usaha yang relevan.
-   Pembelian bahan dan HPP harus diperlakukan konsisten agar tidak
    dihitung dua kali.
-   Operasi yang mengubah transaksi, item, dan stok terkait harus
    atomik.

## 8. Design System

-   Primary: `#FF2800`.
-   Background: `#FFFFFF`.
-   Surface: `#F7F7F7`.
-   Text utama: `#292D35`.
-   Text sekunder: `#858585`.
-   Success: `#16A36A`.
-   Danger: `#E53935`.
-   Bahasa UI: Indonesia.
-   Gaya: modern, minimalis, whitespace cukup, kartu dengan radius
    konsisten, navigasi bawah.

## 9. Testing

-   Unit test untuk formatter dan kalkulasi.
-   Test repository/database untuk CRUD dan relasi.
-   Widget test untuk form dan navigasi penting.
-   Integration test untuk alur: tambah produk → transaksi → riwayat →
    laporan.
-   Uji data kosong, input tidak valid, dan nominal besar.
