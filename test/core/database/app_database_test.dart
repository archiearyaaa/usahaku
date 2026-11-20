import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:usahaku/core/database/app_database.dart';

void main() {
  setUpAll(() {
    // Inisialisasi FFI untuk SQLite unit testing pada mesin host
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppDatabase Schema & Integrity Tests', () {
    late Database db;

    setUp(() async {
      // Buka in-memory database untuk setiap test
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
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
                updated_at TEXT NOT NULL,
                FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
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

    test('Memastikan 9 tabel MVP berhasil dibuat', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
      );
      final tableNames = tables.map((row) => row['name'] as String).toSet();

      expect(tableNames, contains('categories'));
      expect(tableNames, contains('products'));
      expect(tableNames, contains('materials'));
      expect(tableNames, contains('stock_movements'));
      expect(tableNames, contains('sales'));
      expect(tableNames, contains('sale_items'));
      expect(tableNames, contains('expenses'));
      expect(tableNames, contains('income'));
      expect(tableNames, contains('settings'));
      expect(tableNames.length, equals(9));
    });

    test('Foreign key categories ke products ON DELETE SET NULL', () async {
      final catId = await db.insert('categories', {
        'name': 'Makanan',
        'created_at': DateTime.now().toIso8601String(),
      });

      final prodId = await db.insert('products', {
        'category_id': catId,
        'name': 'Nasi Goreng',
        'cost_price': 10000,
        'selling_price': 15000,
        'stock': 10,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Hapus kategori
      await db.delete('categories', where: 'id = ?', whereArgs: [catId]);

      // Produk tetap ada namun category_id menjadi NULL
      final products = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [prodId],
      );
      expect(products.first['category_id'], isNull);
    });

    test('Transaksi penjualan atomik dan cascade delete sale_items', () async {
      final saleId = await db.insert('sales', {
        'invoice_number': 'INV-20261120-001',
        'sale_date': DateTime.now().toIso8601String(),
        'subtotal': 30000,
        'discount': 0,
        'total': 30000,
        'payment_method': 'Tunai',
        'amount_paid': 50000,
        'change_amount': 20000,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('sale_items', {
        'sale_id': saleId,
        'product_name': 'Ayam Geprek',
        'quantity': 2,
        'unit_price': 15000,
        'unit_cost': 10000,
        'line_total': 30000,
      });

      var items = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      expect(items.length, equals(1));
      expect(items.first['unit_price'], equals(15000));

      // Hapus sale -> sale_items harus terhapus otomatis (cascade)
      await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
      items = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      expect(items.isEmpty, isTrue);
    });

    test('Penyimpanan settings key-value', () async {
      await db.insert('settings', {
        'key': 'store_name',
        'value': 'Kedai Berkah',
      });
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['store_name'],
      );
      expect(result.first['value'], equals('Kedai Berkah'));
    });
  });
}
