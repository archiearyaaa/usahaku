import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:usahaku/core/utils/currency_formatter.dart';
import 'package:usahaku/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('CurrencyFormatter Tests', () {
    test('Format nominal positif dengan benar', () {
      expect(CurrencyFormatter.format(0), contains('0'));
      expect(CurrencyFormatter.format(15000), contains('15.000'));
      expect(CurrencyFormatter.format(1000000), contains('1.000.000'));
      expect(CurrencyFormatter.format(250000000), contains('250.000.000'));
    });

    test('Format number only tanpa simbol Rp', () {
      expect(CurrencyFormatter.formatNumber(15000), equals('15.000'));
      expect(CurrencyFormatter.formatNumber(500), equals('500'));
    });

    test('Parse string Rupiah kembali menjadi integer murni', () {
      expect(CurrencyFormatter.parse('15.000'), equals(15000));
      expect(CurrencyFormatter.parse('Rp 25.000'), equals(25000));
      expect(CurrencyFormatter.parse('Rp 1.500.000'), equals(1500000));
      expect(CurrencyFormatter.parse(''), equals(0));
      expect(CurrencyFormatter.parse('abc'), equals(0));
      expect(CurrencyFormatter.parse('Rp -5.000'), equals(-5000));
    });
  });

  group('DateFormatter Tests', () {
    final testDate = DateTime(2026, 11, 20, 21, 30);

    test('Format tanggal standar indonesia', () {
      final formatted = DateFormatter.formatDate(testDate);
      expect(formatted, contains('20'));
      expect(formatted, contains('Nov'));
      expect(formatted, contains('2026'));
    });

    test('Format jam dan tanggal singkat', () {
      expect(DateFormatter.formatTime(testDate), equals('21:30'));
      expect(DateFormatter.formatShortDate(testDate), equals('20/11/2026'));
    });

    test('Konversi ISO 8601 bolak-balik', () {
      final iso = DateFormatter.toIso8601(testDate);
      final parsed = DateFormatter.parseIso8601(iso);
      expect(parsed, isNotNull);
      expect(parsed!.year, equals(2026));
      expect(parsed.month, equals(11));
      expect(parsed.day, equals(20));
      expect(parsed.hour, equals(21));
      expect(parsed.minute, equals(30));
    });

    test('Parse ISO null atau kosong menghasilkan null', () {
      expect(DateFormatter.parseIso8601(null), isNull);
      expect(DateFormatter.parseIso8601(''), isNull);
    });
  });
}
