import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

/// Pengelola koneksi dan skema SQLite USAHAKU sesuai ARCHITECTURE.md.
/// - Database offline-first: `usahaku.db`
/// - Foreign key diaktifkan (`PRAGMA foreign_keys = ON`)
/// - Seluruh nominal uang disimpan dalam tipe INTEGER Rupiah
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  /// Memperbolehkan injeksi database untuk keperluan pengujian (in-memory SQLite)
  void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Wajib aktifkan foreign keys sesuai aturan ARCHITECTURE.md
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Tambah kolom unit pada tabel products jika belum ada
      try {
        await db.execute(
          "ALTER TABLE products ADD COLUMN unit TEXT NOT NULL DEFAULT 'porsi'",
        );
      } catch (_) {}

      // 2. Buat tabel product_bundles untuk fitur paket terhubung / bundling stock
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_bundles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bundle_product_id INTEGER NOT NULL,
          item_product_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (bundle_product_id) REFERENCES products (id) ON DELETE CASCADE,
          FOREIGN KEY (item_product_id) REFERENCES products (id) ON DELETE CASCADE,
          UNIQUE(bundle_product_id, item_product_id)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_product_bundles_bundle ON product_bundles(bundle_product_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_product_bundles_item ON product_bundles(item_product_id)',
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Tabel categories
    batch.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Tabel products
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
    batch.execute(
      'CREATE INDEX idx_products_category ON products(category_id)',
    );

    // 3. Tabel materials
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

    // 4. Tabel stock_movements
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
    batch.execute(
      'CREATE INDEX idx_stock_movements_material ON stock_movements(material_id)',
    );
    batch.execute(
      'CREATE INDEX idx_stock_movements_date ON stock_movements(movement_date)',
    );

    // 5. Tabel sales
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
    batch.execute('CREATE INDEX idx_sales_date ON sales(sale_date)');

    // 6. Tabel sale_items (snapshot nama dan harga per unit)
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
    batch.execute('CREATE INDEX idx_sale_items_sale ON sale_items(sale_id)');
    batch.execute(
      'CREATE INDEX idx_sale_items_product ON sale_items(product_id)',
    );

    // 7. Tabel expenses
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
    batch.execute('CREATE INDEX idx_expenses_date ON expenses(expense_date)');

    // 8. Tabel income
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
    batch.execute('CREATE INDEX idx_income_date ON income(income_date)');

    // 9. Tabel settings
    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NULL
      )
    ''');

    // 10. Tabel product_bundles (Paket Terhubung / Bundling Stock)
    batch.execute('''
      CREATE TABLE product_bundles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bundle_product_id INTEGER NOT NULL,
        item_product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (bundle_product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (item_product_id) REFERENCES products (id) ON DELETE CASCADE,
        UNIQUE(bundle_product_id, item_product_id)
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_product_bundles_bundle ON product_bundles(bundle_product_id)',
    );
    batch.execute(
      'CREATE INDEX idx_product_bundles_item ON product_bundles(item_product_id)',
    );

    await batch.commit(noResult: true);
  }

  /// Menutup koneksi database jika terbuka
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
