import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/income_model.dart';

/// Repository CRUD untuk tabel `income` (pemasukan tambahan di luar penjualan).
class IncomeRepository {
  final AppDatabase _appDatabase;

  IncomeRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  /// Daftar kategori standar pemasukan non-penjualan
  static const List<String> defaultCategories = [
    'Modal Awal',
    'Pendapatan Lain',
    'Suntikan Dana',
    'Hadiah/Bonus',
    'Lainnya',
  ];

  /// Mengambil seluruh pemasukan dengan filter tanggal, kategori, dan pencarian
  Future<List<IncomeModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? searchQuery,
  }) async {
    final db = await _db;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('income_date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('income_date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (category != null && category.trim().isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category.trim());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(LOWER(title) LIKE ? OR LOWER(note) LIKE ?)');
      final term = '%${searchQuery.trim().toLowerCase()}%';
      whereArgs.addAll([term, term]);
    }

    final whereString = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final sql =
        '''
      SELECT * FROM income
      $whereString
      ORDER BY income_date DESC, id DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      sql,
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps.map((m) => IncomeModel.fromMap(m)).toList();
  }

  Future<IncomeModel?> getById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'income',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return IncomeModel.fromMap(maps.first);
  }

  Future<int> insert(IncomeModel income) async {
    final db = await _db;
    return await db.insert('income', income.toMap());
  }

  Future<int> update(IncomeModel income) async {
    final db = await _db;
    return await db.update(
      'income',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  /// Menghitung total pemasukan non-penjualan pada rentang periode
  Future<int> getTotalAmount({
    DateTime? startDate,
    DateTime? endDate,
    bool excludeInitialCapital = false,
  }) async {
    final db = await _db;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('income_date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('income_date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (excludeInitialCapital) {
      whereClauses.add("LOWER(category) != 'modal awal'");
    }

    final whereString = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final sql = 'SELECT SUM(amount) AS total FROM income $whereString';
    final result = await db.rawQuery(
      sql,
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    final total = result.first['total'];
    return (total as num?)?.toInt() ?? 0;
  }

  /// Menghitung total modal awal yang pernah disetor
  Future<int> getInitialCapitalTotal() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT SUM(amount) AS total FROM income
      WHERE LOWER(category) = 'modal awal'
    ''');
    final total = result.first['total'];
    return (total as num?)?.toInt() ?? 0;
  }
}
