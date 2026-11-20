import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:usahaku/core/database/app_database.dart';
import 'package:usahaku/features/reports/data/repositories/report_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ReportRepository SQLite Tests', () {
    late Database db;
    late ReportRepository reportRepo;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            final batch = db.batch();
            batch.execute('''
              CREATE TABLE sales (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                invoice_number TEXT NOT NULL UNIQUE,
                sale_date TEXT NOT NULL,
                subtotal INTEGER NOT NULL,
                discount INTEGER NOT NULL DEFAULT 0,
                total INTEGER NOT NULL,
                payment_method TEXT NOT NULL,
                amount_paid INTEGER NOT NULL,
                change_amount INTEGER NOT NULL DEFAULT 0,
                note TEXT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            batch.execute('''
              CREATE TABLE sale_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sale_id INTEGER NOT NULL,
                product_id INTEGER NULL,
                product_name TEXT NOT NULL,
                quantity INTEGER NOT NULL,
                unit_price INTEGER NOT NULL,
                unit_cost INTEGER NOT NULL DEFAULT 0,
                line_total INTEGER NOT NULL
              )
            ''');
            batch.execute('''
              CREATE TABLE expenses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                category TEXT NOT NULL,
                amount INTEGER NOT NULL,
                expense_date TEXT NOT NULL,
                note TEXT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            batch.execute('''
              CREATE TABLE income (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                category TEXT NOT NULL,
                amount INTEGER NOT NULL,
                income_date TEXT NOT NULL,
                note TEXT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            await batch.commit(noResult: true);
          },
        ),
      );

      AppDatabase.instance.setDatabaseForTesting(db);
      reportRepo = ReportRepository();
    });

    tearDown(() async {
      await db.close();
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test(
      'Rekapitulasi laba rugi sederhana, HPP, omzet, dan biaya usaha per rentang tanggal',
      () async {
        final now = DateTime(2026, 11, 20, 10, 0);

        // Transaksi 1 (dalam periode): Omzet 60.000, HPP 20.000
        final s1 = await db.insert('sales', {
          'invoice_number': 'INV-001',
          'sale_date': now.toIso8601String(),
          'subtotal': 60000,
          'discount': 0,
          'total': 60000,
          'payment_method': 'Tunai',
          'amount_paid': 60000,
          'created_at': now.toIso8601String(),
        });
        await db.insert('sale_items', {
          'sale_id': s1,
          'product_name': 'Kopi Susu',
          'quantity': 3,
          'unit_price': 20000,
          'unit_cost': 6666,
          'line_total': 60000,
        });

        // Transaksi 2 (di luar periode: bulan lalu): tidak boleh ikut dihitung
        await db.insert('sales', {
          'invoice_number': 'INV-OLD',
          'sale_date': DateTime(2026, 10, 15).toIso8601String(),
          'subtotal': 100000,
          'total': 100000,
          'payment_method': 'Tunai',
          'amount_paid': 100000,
          'created_at': DateTime(2026, 10, 15).toIso8601String(),
        });

        // Pengeluaran (dalam periode): 25.000
        await db.insert('expenses', {
          'title': 'Gula dan Susu',
          'category': 'Bahan Baku',
          'amount': 25000,
          'expense_date': now.toIso8601String(),
          'created_at': now.toIso8601String(),
        });

        final report = await reportRepo.getReportData(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 30, 23, 59, 59),
        );

        // Total Omzet hanya INV-001 = 60.000
        expect(report.totalSales, equals(60000));
        expect(report.totalSalesTransactions, equals(1));
        // HPP = 3 x 6.666 = 19.998
        expect(report.totalHpp, equals(19998));
        // Total Pengeluaran = 25.000
        expect(report.totalExpenses, equals(25000));
        // Laba Kotor = 60.000 - 19.998 = 40.002
        expect(report.grossProfit, equals(40002));
        // Laba Bersih Sederhana = 40.002 - 25.000 = 15.002
        expect(report.netProfit, equals(15002));
        expect(report.isProfitable, isTrue);
      },
    );
  });
}
