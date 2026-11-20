# WORKFLOW --- Pengembangan USAHAKU

## 1. Tujuan

Menetapkan proses pengembangan yang aman, bertahap, mudah ditinjau, dan
sesuai ruang lingkup USAHAKU.

## 2. Siklus Pengerjaan Fitur

Untuk setiap fitur, AI mengikuti urutan: 1. **Pahami:** baca PRD,
arsitektur, TODO, dan kode terkait. 2. **Rencanakan:** jelaskan tujuan,
file yang mungkin berubah, dampak database/UI, dan test. 3. **Periksa:**
identifikasi risiko data, kompatibilitas, dan dependensi. 4.
**Implementasikan:** kerjakan perubahan terkecil yang memenuhi
kebutuhan. 5. **Verifikasi:** format, analyze, test, dan uji alur yang
relevan. 6. **Dokumentasikan:** perbarui TODO dan dokumen teknis jika
perlu. 7. **Laporkan:** jelaskan perubahan dan hasil verifikasi.

Untuk tugas kecil yang jelas dan berisiko rendah, AI boleh melakukan
perencanaan singkat lalu langsung mengerjakan tanpa meminta persetujuan
terpisah.

## 3. Kapan AI Boleh Bekerja Mandiri

AI boleh melanjutkan tanpa konfirmasi untuk: - memperbaiki typo atau
format; - memperbaiki bug lokal yang jelas tanpa mengubah perilaku
produk; - membuat widget internal sesuai design system; - menambahkan
validasi form sesuai aturan yang sudah terdokumentasi; - menulis unit
test; - memperbaiki analisis/lint yang disebabkan perubahan saat ini; -
memperbarui TODO setelah pekerjaan diverifikasi.

AI harus tetap melaporkan perubahan dan hasil test.

## 4. Kapan Harus Meminta Izin

Minta persetujuan sebelum: - mengubah ruang lingkup atau menambah modul
di luar PRD; - mengubah teknologi inti atau menambah dependency
berdampak besar; - mengubah schema database, strategi migrasi, atau
format penyimpanan; - menghapus, mereset, atau mengubah data pengguna; -
menjalankan perintah destruktif atau menghapus file; - mengubah
konfigurasi Android, permission sensitif, signing, atau rilis; -
menambahkan layanan online, cloud, analytics, iklan, atau integrasi
pihak ketiga; - mengubah aturan perhitungan keuangan, HPP, omzet, atau
laba; - mengubah navigasi utama atau design system secara menyeluruh; -
melakukan refactor besar yang menyentuh banyak fitur.

Jika ada keputusan yang belum jelas dan dapat memengaruhi data atau
hasil keuangan, berhenti dan ajukan satu pertanyaan yang paling penting.

## 5. Standar Implementasi

-   Kerjakan satu fitur atau satu bagian kecil pada satu waktu.
-   Hindari menggabungkan banyak perubahan tidak terkait.
-   Pertahankan pola penamaan dan struktur yang sudah ada.
-   UI tidak boleh menjadi sumber perhitungan bisnis.
-   Data dashboard/laporan harus berasal dari database.
-   Operasi multi-tabel harus atomik.
-   Semua nominal uang memakai integer Rupiah.
-   Form harus memvalidasi input.
-   Berikan empty, loading, dan error state.
-   Jangan menganggap placeholder sebagai fitur selesai.

## 6. Definition of Done

Fitur dinyatakan selesai jika: - kebutuhan sesuai PRD; - alur utama
berfungsi; - data tersimpan dan dapat dibaca kembali jika relevan; -
validasi dan error state tersedia; - UI konsisten dengan design
system; - tidak ada error analisis baru; - test relevan lulus; - tidak
merusak fitur lain; - TODO diperbarui; - keterbatasan yang tersisa
dicatat.

Untuk fitur laporan, angka harus cocok dengan data sumber. Untuk fitur
transaksi, data header dan detail harus tersimpan secara konsisten.

## 7. Database Change Workflow

1.  Jelaskan alasan perubahan schema.
2.  Identifikasi tabel/kolom terdampak.
3.  Rancang migrasi yang mempertahankan data.
4.  Minta persetujuan pemilik proyek.
5.  Implementasikan migrasi versi.
6.  Uji upgrade dari schema sebelumnya dan database baru.
7.  Perbarui ARCHITECTURE.md dan TODO.md.

Jangan menggunakan penghapusan database sebagai strategi migrasi.

## 8. Testing Workflow

Setelah perubahan kode:

``` bash
dart format .
flutter analyze
flutter test
```

Jalankan perintah yang relevan terhadap perubahan; jika proyek belum
memiliki test, buat test dasar untuk logika baru. Untuk perubahan UI,
lakukan uji pada emulator/perangkat Android. Untuk perubahan database,
uji database baru dan migrasi.

Jangan mengklaim perintah berhasil jika tidak dijalankan.

## 9. Git Workflow

-   Gunakan perubahan kecil dan mudah ditinjau.
-   Periksa `git status` sebelum dan sesudah pekerjaan.
-   Jangan menghapus perubahan lokal pengguna.
-   Jangan melakukan commit atau push kecuali diminta.
-   Jangan memasukkan file database pengguna, secret, atau file build
    yang tidak perlu ke Git.
-   Pastikan `.gitignore` sesuai proyek Flutter.

## 10. Komunikasi dan Persetujuan

Sebelum pekerjaan berisiko, jelaskan: - apa yang akan diubah; - mengapa
perubahan diperlukan; - dampaknya; - apakah ada risiko data; - bagaimana
verifikasinya.

Jika aman dan sudah tercakup dalam dokumen, AI dapat langsung bekerja.
Jangan meminta persetujuan untuk setiap perubahan kecil yang rutin.
