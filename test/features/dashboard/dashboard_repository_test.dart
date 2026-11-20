import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:usahaku/core/database/app_database.dart';
import 'package:usahaku/features/dashboard/data/repositories/dashboard_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DashboardRepository SQLite Integration Tests', () {
    late Database db;
    late DashboardRepository dashboardRepo;

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
      dashboardRepo = DashboardRepository();
    });

    tearDown(() async {
      await db.close();
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test(
      'Hitung metrik ringkasan dashboard (omzet, transaksi, HPP, pengeluaran, laba)',
      () async {
        final now = DateTime.now();

        // Transaksi 1: Omzet 50.000, HPP 20.000 (2 x 10.000)
        final saleId1 = await db.insert('sales', {
          'invoice_number': 'INV-20261120-0001',
          'sale_date': now.toIso8601String(),
          'subtotal': 50000,
          'discount': 0,
          'total': 50000,
          'payment_method': 'Tunai',
          'amount_paid': 50000,
          'change_amount': 0,
          'created_at': now.toIso8601String(),
        });
        await db.insert('sale_items', {
          'sale_id': saleId1,
          'product_name': 'Nasi Ayam',
          'quantity': 2,
          'unit_price': 25000,
          'unit_cost': 10000,
          'line_total': 50000,
        });

        // Transaksi 2: Omzet 30.000, HPP 10.000 (1 x 10.000)
        final saleId2 = await db.insert('sales', {
          'invoice_number': 'INV-20261120-0002',
          'sale_date': now.toIso8601String(),
          'subtotal': 30000,
          'discount': 0,
          'total': 30000,
          'payment_method': 'QRIS',
          'amount_paid': 30000,
          'change_amount': 0,
          'created_at': now.toIso8601String(),
        });
        await db.insert('sale_items', {
          'sale_id': saleId2,
          'product_name': 'Kopi',
          'quantity': 2,
          'unit_price': 15000,
          'unit_cost': 5000,
          'line_total': 30000,
        });

        // Biaya Usaha (Pengeluaran): 15.000
        await db.insert('expenses', {
          'title': 'Plastik Kemasan',
          'category': 'Kemasan',
          'amount': 15000,
          'expense_date': now.toIso8601String(),
          'created_at': now.toIso8601String(),
        });

        final metrics = await dashboardRepo.getMetrics();

        // Total Omzet = 50.000 + 30.000 = 80.000
        expect(metrics.omzet, equals(80000));
        // Jumlah Transaksi = 2
        expect(metrics.transactionCount, equals(2));
        // Total HPP = 20.000 + 10.000 = 30.000
        expect(metrics.totalHpp, equals(30000));
        // Total Pengeluaran = 15.000
        expect(metrics.totalExpenses, equals(15000));
        // Laba Kotor = 80.000 - 30.000 = 50.000
        expect(metrics.grossProfit, equals(50000));
        // Laba Sederhana = 80.000 - 30.000 - 15.000 = 35.000
        expect(metrics.estimatedProfit, equals(35000));
        expect(metrics.isProfitable, isTrue);
      },
    );

    test(
      'Data grafik 7 hari terakhir mengisi 0 untuk hari tanpa transaksi',
      () async {
        final now = DateTime.now();

        // Tambahkan 1 transaksi hari ini
        await db.insert('sales', {
          'invoice_number': 'INV-TEST-CHART',
          'sale_date': now.toIso8601String(),
          'subtotal': 25000,
          'discount': 0,
          'total': 25000,
          'payment_method': 'Tunai',
          'amount_paid': 25000,
          'created_at': now.toIso8601String(),
        });

        final chartData = await dashboardRepo.getDailySalesChartData(days: 7);
        expect(chartData.length, equals(7));

        // Hari terakhir (hari ini) harus bernilai 25.000
        expect(chartData.last.amount, equals(25000));
        expect(chartData.last.transactionCount, equals(1));

        // Hari-hari sebelumnya bernilai 0
        for (int i = 0; i < 6; i++) {
          expect(chartData[i].amount, equals(0));
        }
      },
    );

    test(
      'Mengambil daftar aktivitas terbaru dan mengurutkan secara descending',
      () async {
        final now = DateTime.now();

        await db.insert('sales', {
          'invoice_number': 'INV-ACT-1',
          'sale_date': now.subtract(const Duration(hours: 2)).toIso8601String(),
          'subtotal': 20000,
          'total': 20000,
          'payment_method': 'Tunai',
          'amount_paid': 20000,
          'created_at': now.toIso8601String(),
        });

        await db.insert('expenses', {
          'title': 'Beli Es Batu',
          'category': 'Bahan Baku',
          'amount': 5000,
          'expense_date': now
              .subtract(const Duration(minutes: 30))
              .toIso8601String(),
          'created_at': now.toIso8601String(),
        });

        final activities = await dashboardRepo.getRecentActivities();
        expect(activities.length, equals(2));

        // Aktivitas paling baru (30 menit lalu) harus di urutan pertama
        expect(activities.first.title, equals('Beli Es Batu'));
        expect(activities.first.type, equals('expense'));
        expect(activities.last.title, equals('INV-ACT-1'));
        expect(activities.last.type, equals('sale'));
      },
    );
  });
}
