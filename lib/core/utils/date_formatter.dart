import 'package:intl/intl.dart';

/// Utility untuk format tanggal dan waktu sesuai ISO 8601 & standar lokal Indonesia.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _dateTimeFormat = DateFormat(
    'dd MMM yyyy, HH:mm',
    'id_ID',
  );
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy', 'id_ID');

  /// Menghasilkan format tanggal (contoh: "20 Nov 2026")
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Menghasilkan format tanggal dan waktu (contoh: "20 Nov 2026, 21:00")
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Menghasilkan format jam (contoh: "21:00")
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Menghasilkan format bulan dan tahun (contoh: "November 2026")
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Menghasilkan format tanggal pendek (contoh: "20/11/2026")
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Mengonversi DateTime ke format ISO 8601 String untuk penyimpanan SQLite
  static String toIso8601(DateTime date) {
    return date.toIso8601String();
  }

  /// Mem-parsing ISO 8601 String dari SQLite menjadi DateTime
  static DateTime? parseIso8601(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    return DateTime.tryParse(isoString);
  }
}
