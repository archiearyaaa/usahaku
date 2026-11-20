import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/material_model.dart';

/// Repository CRUD untuk tabel `materials`.
class MaterialRepository {
  final AppDatabase _appDatabase;

  MaterialRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  /// Mengambil semua bahan baku, opsional filter pencarian
  Future<List<MaterialModel>> getAll({String? searchQuery}) async {
    final db = await _db;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('LOWER(name) LIKE ?');
      whereArgs.add('%${searchQuery.trim().toLowerCase()}%');
    }

    final whereString = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final sql = 'SELECT * FROM materials $whereString ORDER BY name ASC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      sql,
      whereArgs.isNotEmpty ? whereArgs : null,
    );
    return maps.map((map) => MaterialModel.fromMap(map)).toList();
  }

  /// Mengambil bahan baku berdasarkan ID
  Future<MaterialModel?> getById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'materials',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MaterialModel.fromMap(maps.first);
  }

  /// Mengambil bahan baku yang stoknya di bawah minimum
  Future<List<MaterialModel>> getLowStock() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM materials
      WHERE minimum_stock IS NOT NULL
        AND minimum_stock > 0
        AND quantity < minimum_stock
      ORDER BY name ASC
    ''');
    return maps.map((map) => MaterialModel.fromMap(map)).toList();
  }

  /// Menambah bahan baku baru
  Future<int> insert(MaterialModel material) async {
    final db = await _db;
    return await db.insert('materials', material.toMap());
  }

  /// Memperbarui data bahan baku
  Future<int> update(MaterialModel material) async {
    final db = await _db;
    return await db.update(
      'materials',
      material.toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  /// Menghapus bahan baku (cascade delete movement terkait)
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }
}
