# AGENTS.md --- Instruksi AI Coding untuk USAHAKU

Dokumen ini menjadi aturan kerja bagi AI coding assistant yang membantu
proyek USAHAKU.

## 1. Sumber Kebenaran

Sebelum mengerjakan tugas: 1. Baca `AGENTS.md`. 2. Baca bagian relevan
di `PRD.md` dan `ARCHITECTURE.md`. 3. Periksa `TODO.md` untuk status
aktual. 4. Ikuti `WORKFLOW.md`.

Jika instruksi bertentangan, jangan menebak. Jelaskan konflik dan minta
keputusan pemilik proyek. PRD menentukan kebutuhan produk; ARCHITECTURE
menentukan keputusan teknis yang telah disetujui.

## 2. Konteks Proyek

-   Nama: USAHAKU.
-   Tujuan: aplikasi pencatatan usaha makanan/minuman untuk tugas KWU.
-   Platform: Android.
-   Framework: Flutter/Dart.
-   Penyimpanan: SQLite lokal, offline-first.
-   Pengguna: satu pemilik usaha.
-   UI: Bahasa Indonesia.
-   Warna utama: `#FF2800`.
-   Fokus: sederhana, mudah digunakan, tidak over-engineered.

Jangan memperluas aplikasi menjadi ERP, SaaS, multi-user, atau sistem
komersial kompleks tanpa persetujuan.

## 3. Aturan Sebelum Mengubah Kode

-   Periksa file dan pola yang sudah ada sebelum membuat file baru.
-   Jangan menimpa pekerjaan pengguna.
-   Buat perubahan sekecil mungkin dan relevan dengan tugas.
-   Jangan membuat ulang proyek atau mengganti struktur besar tanpa
    izin.
-   Jangan menambahkan dependency jika fungsi dapat dicapai dengan
    dependency yang sudah ada.
-   Pastikan versi package kompatibel dengan Flutter SDK proyek.
-   Jangan mengarang API, field database, atau fitur yang belum
    disepakati.

## 4. Standar Kode Flutter/Dart

-   Gunakan null safety.
-   Ikuti `dart format`.
-   Gunakan nama class PascalCase, variabel/function lowerCamelCase, dan
    file snake_case.
-   Pecah widget jika meningkatkan keterbacaan atau dapat digunakan
    ulang.
-   Hindari satu file yang menampung seluruh logika aplikasi.
-   Pisahkan UI dari query database dan kalkulasi bisnis.
-   Hindari duplikasi kalkulasi.
-   Gunakan `const` jika memungkinkan.
-   Tangani loading, empty state, error, dan input tidak valid.
-   Jangan menelan exception tanpa penanganan atau logging yang sesuai.
-   Jangan menyimpan nominal Rupiah menggunakan `double`; gunakan
    integer.

## 5. Aturan UI/UX

-   Ikuti design system: primary `#FF2800`, latar putih/abu muda, teks
    gelap.
-   Gunakan Bahasa Indonesia pada label dan pesan pengguna.
-   Jaga konsistensi spacing, radius, typography, ikon, dan komponen.
-   Prioritaskan layout responsif dan aksesibilitas.
-   Jangan menambahkan tombol dekoratif yang tidak memiliki aksi.
-   Setiap aksi berbahaya harus memiliki konfirmasi.
-   Tampilkan format Rupiah dengan benar.
-   Jangan memakai angka dummy pada dashboard/laporan setelah integrasi
    database; data contoh hanya boleh dipakai dalam preview/test yang
    diberi label.

## 6. Aturan Database

-   Gunakan schema di `ARCHITECTURE.md`.
-   Aktifkan foreign key.
-   Gunakan parameterized query.
-   Gunakan transaksi database untuk operasi multi-tabel.
-   Jangan menghapus database atau menghapus data pengguna untuk
    menyelesaikan bug.
-   Jangan mengubah schema tanpa memperbarui dokumentasi dan strategi
    migrasi.
-   Tambahkan migrasi versi database untuk perubahan schema.
-   Jaga histori transaksi dan snapshot harga/nama.
-   Pastikan operasi stok dan transaksi konsisten.
-   Hindari stok negatif kecuali aturan bisnis disetujui.
-   Jangan menghitung pembelian bahan sekaligus sebagai biaya dan HPP
    secara ganda.

## 7. Keamanan dan Privasi

-   Jangan menaruh password, token, atau secret di source code.
-   Jangan mengirim data usaha ke internet; aplikasi inti harus offline.
-   Minta izin platform sebelum mengakses foto/file yang memerlukannya.
-   Jangan menambahkan analytics, iklan, tracking, atau koneksi pihak
    ketiga tanpa persetujuan.
-   Jangan mengekspos data pribadi dalam log.
-   Validasi file impor sebelum digunakan.
-   Jangan menghapus atau menimpa backup tanpa persetujuan.

## 8. Testing dan Verifikasi

Setelah perubahan: 1. Jalankan `dart format` pada file yang diubah. 2.
Jalankan `flutter analyze`. 3. Jalankan test terkait atau
`flutter test`. 4. Tambahkan test untuk kalkulasi dan aturan bisnis
baru. 5. Jelaskan test yang dijalankan dan hasilnya. 6. Jika test tidak
dapat dijalankan, sebutkan alasannya; jangan mengklaim berhasil.

Uji khusus untuk: - kalkulasi harga dan total; - format Rupiah; -
tanggal dan rentang laporan; - CRUD dan foreign key; - transaksi
penjualan atomik; - stok masuk/keluar; - data kosong dan input tidak
valid.

## 9. Dokumentasi dan TODO

-   Perbarui `TODO.md` hanya setelah pekerjaan diverifikasi.
-   Jika keputusan teknis berubah, perbarui `ARCHITECTURE.md`.
-   Jika cakupan produk berubah, usulkan perubahan `PRD.md`.
-   Catat migrasi database dan keputusan penting.
-   Jangan mengklaim fitur selesai jika baru berupa UI placeholder.

## 10. Larangan

-   Jangan menghapus file atau data yang tidak terkait.
-   Jangan menjalankan perintah destruktif tanpa izin.
-   Jangan mengganti package utama tanpa izin.
-   Jangan menambahkan fitur di luar PRD secara diam-diam.
-   Jangan membuat data palsu untuk laporan nyata.
-   Jangan menyatakan build/test berhasil tanpa menjalankannya.
-   Jangan mengubah konfigurasi signing atau rilis tanpa persetujuan.

## 11. Format Laporan Setelah Bekerja

Sampaikan secara ringkas: - file yang dibuat/diubah; - perilaku yang
ditambahkan; - keputusan atau asumsi; - test yang dijalankan dan
hasilnya; - TODO yang diperbarui; - hal yang masih perlu persetujuan.
