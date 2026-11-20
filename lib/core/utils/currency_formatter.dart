import 'package:intl/intl.dart';

/// Utility untuk format Rupiah.
/// Sesuai aturan AGENTS.md dan ARCHITECTURE.md:
/// Nominal uang selalu menggunakan integer, bukan floating point.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberOnlyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  /// Memformat nilai integer rupiah menjadi string (contoh: 15000 -> "Rp 15.000")
  static String format(int amount) {
    return _formatter.format(amount).trim();
  }

  /// Memformat nilai integer rupiah tanpa simbol (contoh: 15000 -> "15.000")
  static String formatNumber(int amount) {
    return _numberOnlyFormatter.format(amount).trim();
  }

  /// Membersihkan input string angka menjadi integer
  /// Mengabaikan karakter non-digit kecuali tanda minus di awal
  static int parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9\-]'), '');
    if (cleaned.isEmpty || cleaned == '-') {
      return 0;
    }
    return int.tryParse(cleaned) ?? 0;
  }
}
