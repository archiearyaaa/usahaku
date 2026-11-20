import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/expense_model.dart';

/// Repository CRUD untuk tabel `expenses` (pengeluaran dan biaya usaha).
class ExpenseRepository {
  final AppDatabase _appDatabase;

  ExpenseRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  /// Daftar kategori standar pengeluaran usaha makanan/minuman
  static const List<String> defaultCategories = [
    'Bahan Baku',
    'Operasional',
    'Sewa Tempat',
    'Gaji/Upah',
    'Peralatan',
    'Listrik & Air',
    'Kemasan',
    'Lainnya',
  ];

  /// Mengambil seluruh pengeluaran dengan filter tanggal, kategori, dan pencarian
  Future<List<ExpenseModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? searchQuery,
  }) async {
    final db = await _db;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('expense_date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('expense_date <= ?');
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
      SELECT * FROM expenses
      $whereString
      ORDER BY expense_date DESC, id DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      sql,
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  Future<ExpenseModel?> getById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExpenseModel.fromMap(maps.first);
  }

  Future<int> insert(ExpenseModel expense) async {
    final db = await _db;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> update(ExpenseModel expense) async {
    final db = await _db;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Menghitung total pengeluaran pada rentang periode
  Future<int> getTotalAmount({DateTime? startDate, DateTime? endDate}) async {
    final db = await _db;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('expense_date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('expense_date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final whereString = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final sql = 'SELECT SUM(amount) AS total FROM expenses $whereString';
    final result = await db.rawQuery(
      sql,
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    final total = result.first['total'];
    return (total as num?)?.toInt() ?? 0;
  }
}
