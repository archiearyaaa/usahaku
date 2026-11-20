import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final AppDatabase _appDatabase;

  CategoryRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  Future<List<CategoryModel>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name ASC',
    );
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<CategoryModel?> getById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  Future<int> insert(CategoryModel category) async {
    final db = await _db;
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(CategoryModel category) async {
    final db = await _db;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  /// Memasukkan kategori starter default (Makanan, Minuman, Paket, Camilan) jika tabel categories masih kosong.
  Future<void> seedDefaultCategoriesIfEmpty() async {
    try {
      final db = await _db;
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM categories'),
          ) ??
          0;
      if (count == 0) {
        final now = DateTime.now().toIso8601String();
        final batch = db.batch();
        for (final name in ['Makanan', 'Minuman', 'Paket', 'Camilan']) {
          batch.insert('categories', {'name': name, 'created_at': now});
        }
        await batch.commit(noResult: true);
      }
    } catch (_) {
      // Abaikan jika database belum siap atau mock
    }
  }
}
