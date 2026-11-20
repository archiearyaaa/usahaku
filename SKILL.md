# SKILL --- Reusable Prompt Library USAHAKU

Kumpulan instruksi yang dapat digunakan kembali oleh pemilik proyek atau
AI coding assistant. Prompt harus mengikuti PRD.md, ARCHITECTURE.md,
AGENTS.md, dan WORKFLOW.md.

## 1. Feature Planning

``` text
Baca AGENTS.md, PRD.md, ARCHITECTURE.md, TODO.md, dan WORKFLOW.md.
Rencanakan fitur: [NAMA FITUR].
Jelaskan tujuan, alur pengguna, file yang akan dibuat/diubah, dampak database,
validasi, empty/loading/error state, dan test yang diperlukan.
Jangan mulai perubahan berisiko atau di luar PRD tanpa meminta persetujuan.
```

## 2. Flutter Feature Implementation

``` text
Implementasikan fitur [NAMA FITUR] sesuai PRD dan arsitektur USAHAKU.
Periksa pola kode yang sudah ada terlebih dahulu.
Pisahkan UI dari akses database dan logika perhitungan.
Gunakan design system #FF2800 dan Bahasa Indonesia.
Pastikan semua tombol berfungsi, form tervalidasi, serta loading, empty,
dan error state ditangani.
Tambahkan atau perbarui test. Jalankan dart format, flutter analyze,
dan test relevan. Perbarui TODO hanya setelah verifikasi.
```

## 3. Debugging

``` text
Bantu debug masalah berikut:
[DESKRIPSI MASALAH]
[LOG ERROR]
[LANGKAH REPRODUKSI]

Periksa penyebab berdasarkan kode aktual, jangan menebak.
Jelaskan akar masalah, file terdampak, dan perbaikan paling kecil.
Jangan menghapus database atau data pengguna sebagai solusi.
Tambahkan regression test jika memungkinkan, lalu jalankan verifikasi.
```

## 4. Database Review

``` text
Tinjau perubahan database berikut: [DESKRIPSI].
Periksa foreign key, tipe data, constraint, index, transaksi atomik,
integritas histori, dan kompatibilitas migrasi.
Jangan mengubah schema atau mereset database tanpa persetujuan.
Berikan rencana migrasi yang mempertahankan data dan test upgrade.
```

## 5. Testing

``` text
Buat rencana dan test untuk fitur [NAMA FITUR].
Cakup kondisi normal, data kosong, input tidak valid, nilai batas,
kegagalan database, dan kasus regresi.
Jangan menggunakan angka dummy sebagai bukti hasil aplikasi.
Jalankan test yang tersedia dan laporkan hasil sebenarnya.
```

## 6. Code Review

``` text
Lakukan code review pada perubahan [FILE/DIFF].
Periksa correctness, keterbacaan, null safety, duplikasi,
performa, akses database, validasi, keamanan, dan kesesuaian PRD.
Kelompokkan temuan berdasarkan tingkat risiko.
Jangan mengubah kode sebelum menjelaskan temuan dan rencana perbaikannya.
```

## 7. UI/UX Review

``` text
Tinjau halaman [NAMA HALAMAN] berdasarkan design system USAHAKU.
Periksa hierarki visual, spacing, typography, kontras, konsistensi warna
#FF2800, responsivitas, aksesibilitas, navigasi, dan state interaksi.
Pertahankan alur sederhana untuk pemilik UMKM.
Jangan menambahkan fitur di luar PRD.
```

## 8. Refactoring

``` text
Refactor bagian [NAMA BAGIAN] tanpa mengubah perilaku yang terlihat pengguna.
Jelaskan manfaat dan risiko, pertahankan kompatibilitas data,
hindari perubahan schema, dan jangan menambahkan dependency tanpa alasan.
Jalankan test sebelum dan sesudah refactor serta laporkan hasilnya.
```

## 9. Security Review

``` text
Tinjau keamanan fitur [NAMA FITUR].
Periksa input SQL, penyimpanan lokal, file impor/ekspor, permission,
log sensitif, validasi, dan risiko kehilangan data.
Jangan menambahkan layanan jaringan atau tracking.
Berikan temuan dan mitigasi yang sesuai skala aplikasi offline satu pengguna.
```

## 10. Performance Review

``` text
Tinjau performa halaman/fitur [NAMA FITUR].
Periksa query SQLite, jumlah rebuild widget, pemuatan gambar,
render grafik, ukuran data, dan operasi yang berjalan di UI thread.
Jangan melakukan optimasi spekulatif; tunjukkan masalah dan dampaknya.
Verifikasi bahwa hasil optimasi tidak mengubah perilaku.
```

## 11. Release Readiness

``` text
Periksa kesiapan build APK USAHAKU.
Baca dokumentasi proyek, periksa konfigurasi Android, dependency,
izin aplikasi, database, dan hasil test.
Jangan mengubah signing atau konfigurasi rilis tanpa izin.
Jalankan flutter analyze, flutter test, dan build yang diminta.
Laporkan file APK dan hasil perintah secara akurat.
```

## 12. Aturan Penggunaan Prompt

-   Ganti semua placeholder dalam tanda kurung siku.
-   Sertakan error log atau screenshot jika relevan.
-   Jangan memberikan secret, password, atau data pribadi.
-   Semua prompt tunduk pada AGENTS.md dan WORKFLOW.md.
-   Jika instruksi prompt bertentangan dengan dokumentasi proyek, ikuti
    proses klarifikasi.
