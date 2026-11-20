import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:usahaku/app/app.dart';
import 'package:usahaku/core/database/app_database.dart';

void main() {
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          final batch = db.batch();
          batch.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          batch.execute('''
            CREATE TABLE products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category_id INTEGER NULL,
              name TEXT NOT NULL,
              description TEXT NULL,
              cost_price INTEGER NOT NULL DEFAULT 0,
              selling_price INTEGER NOT NULL,
              stock INTEGER NOT NULL DEFAULT 0,
              unit TEXT NOT NULL DEFAULT 'porsi',
              is_active INTEGER NOT NULL DEFAULT 1,
              image_path TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          batch.execute('''
            CREATE TABLE materials (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              unit TEXT NOT NULL,
              quantity REAL NOT NULL DEFAULT 0,
              minimum_stock REAL NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          batch.execute('''
            CREATE TABLE stock_movements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              material_id INTEGER NOT NULL,
              type TEXT NOT NULL,
              quantity REAL NOT NULL,
              note TEXT NULL,
              movement_date TEXT NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (material_id) REFERENCES materials (id) ON DELETE CASCADE
            )
          ''');
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
              line_total INTEGER NOT NULL,
              FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
              FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
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
          batch.execute('''
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              value TEXT NULL
            )
          ''');
          await batch.commit(noResult: true);
        },
      ),
    );
    AppDatabase.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await db.close();
    AppDatabase.instance.setDatabaseForTesting(null);
  });

  testWidgets('Navigasi 5 menu utama berfungsi dengan benar', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const UsahakuApp());
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    // Pastikan halaman awal adalah Dashboard / Home
    expect(find.text('USAHAKU'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Jualan'), findsOneWidget);
    expect(find.text('Produk'), findsOneWidget);
    expect(find.text('Keuangan'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);

    // Pindah ke tab Jualan (targetkan ikon di BottomNavigationBar)
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.point_of_sale_outlined),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.text('Jualan (Kasir)'), findsOneWidget);

    // Pindah ke tab Produk (targetkan ikon di BottomNavigationBar)
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.inventory_2_outlined),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.text('Produk & Bahan'), findsOneWidget);

    // Pindah ke tab Keuangan (targetkan ikon di BottomNavigationBar)
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.account_balance_wallet_outlined),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.text('Keuangan Usaha'), findsOneWidget);

    // Pindah ke tab Laporan (targetkan ikon di BottomNavigationBar)
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.assessment_outlined),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.text('Laporan & Rekap'), findsOneWidget);

    // Kembali ke tab Home (targetkan ikon di BottomNavigationBar)
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.home_outlined),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.text('USAHAKU'), findsWidgets);
  });
}
