import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/product_bundle_item_model.dart';
import '../models/product_model.dart';

class ProductRepository {
  final AppDatabase _appDatabase;

  ProductRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  /// Mengambil daftar produk dengan filter opsional kategori, kata kunci, dan status aktif
  Future<List<ProductModel>> getAll({
    int? categoryId,
    String? searchQuery,
    bool? activeOnly,
  }) async {
    final db = await _db;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (categoryId != null) {
      whereClauses.add('p.category_id = ?');
      whereArgs.add(categoryId);
    }

    if (activeOnly == true) {
      whereClauses.add('p.is_active = 1');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('LOWER(p.name) LIKE ?');
      whereArgs.add('%${searchQuery.trim().toLowerCase()}%');
    }

    final whereString = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final sqlWithBundles =
        '''
      SELECT 
        p.*, 
        c.name AS category_name,
        (SELECT COUNT(*) FROM product_bundles pb WHERE pb.bundle_product_id = p.id) AS bundle_count,
        (SELECT MIN(item.stock / pb.quantity) 
         FROM product_bundles pb 
         JOIN products item ON pb.item_product_id = item.id 
         WHERE pb.bundle_product_id = p.id) AS bundle_available_stock
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      $whereString
      ORDER BY p.name ASC
    ''';

    final sqlFallback =
        '''
      SELECT 
        p.*, 
        c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      $whereString
      ORDER BY p.name ASC
    ''';

    List<Map<String, dynamic>> maps;
    try {
      maps = await db.rawQuery(
        sqlWithBundles,
        whereArgs.isNotEmpty ? whereArgs : null,
      );
    } catch (_) {
      maps = await db.rawQuery(
        sqlFallback,
        whereArgs.isNotEmpty ? whereArgs : null,
      );
    }

    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<ProductModel?> getById(int id) async {
    final db = await _db;
    final sqlWithBundles = '''
      SELECT 
        p.*, 
        c.name AS category_name,
        (SELECT COUNT(*) FROM product_bundles pb WHERE pb.bundle_product_id = p.id) AS bundle_count,
        (SELECT MIN(item.stock / pb.quantity) 
         FROM product_bundles pb 
         JOIN products item ON pb.item_product_id = item.id 
         WHERE pb.bundle_product_id = p.id) AS bundle_available_stock
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ?
      LIMIT 1
    ''';

    final sqlFallback = '''
      SELECT 
        p.*, 
        c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ?
      LIMIT 1
    ''';

    List<Map<String, dynamic>> maps;
    try {
      maps = await db.rawQuery(sqlWithBundles, [id]);
    } catch (_) {
      maps = await db.rawQuery(sqlFallback, [id]);
    }

    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  /// Mengambil daftar item komponen yang tergabung dalam produk paket
  Future<List<ProductBundleItemModel>> getBundleItems(
    int bundleProductId,
  ) async {
    final db = await _db;
    try {
      final sql = '''
        SELECT 
          pb.*,
          p.name AS item_name,
          p.unit AS item_unit,
          p.cost_price AS cost_price,
          p.stock AS item_stock
        FROM product_bundles pb
        JOIN products p ON pb.item_product_id = p.id
        WHERE pb.bundle_product_id = ?
      ''';
      final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [
        bundleProductId,
      ]);
      return maps.map((m) => ProductBundleItemModel.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Menyimpan komposisi produk komponen untuk suatu paket
  Future<void> saveBundleItems(
    int bundleProductId,
    List<ProductBundleItemModel> items,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'product_bundles',
        where: 'bundle_product_id = ?',
        whereArgs: [bundleProductId],
      );
      for (final item in items) {
        await txn.insert('product_bundles', {
          'bundle_product_id': bundleProductId,
          'item_product_id': item.itemProductId,
          'quantity': item.quantity,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<int> insert(ProductModel product) async {
    final db = await _db;
    return await db.insert('products', product.toMap());
  }

  Future<int> update(ProductModel product) async {
    final db = await _db;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
