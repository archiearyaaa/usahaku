import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:usahaku/core/database/app_database.dart';
import 'package:usahaku/features/products/data/models/category_model.dart';
import 'package:usahaku/features/products/data/models/product_model.dart';
import 'package:usahaku/features/products/data/repositories/category_repository.dart';
import 'package:usahaku/features/products/data/repositories/product_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CategoryRepository & ProductRepository Tests', () {
    late Database db;
    late CategoryRepository categoryRepo;
    late ProductRepository productRepo;

    setUp(() async {
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
            await batch.commit(noResult: true);
          },
        ),
      );

      AppDatabase.instance.setDatabaseForTesting(db);
      categoryRepo = CategoryRepository();
      productRepo = ProductRepository();
    });

    tearDown(() async {
      await db.close();
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test('CRUD Kategori berjalan dengan benar', () async {
      // 1. Tambah kategori
      final catId = await categoryRepo.insert(
        CategoryModel(name: 'Minuman Segar', createdAt: DateTime.now()),
      );
      expect(catId, isPositive);

      // 2. Ambil kategori
      final list = await categoryRepo.getAll();
      expect(list.length, equals(1));
      expect(list.first.name, equals('Minuman Segar'));

      // 3. Update kategori
      await categoryRepo.update(list.first.copyWith(name: 'Minuman Dingin'));
      final updated = await categoryRepo.getById(catId);
      expect(updated?.name, equals('Minuman Dingin'));

      // 4. Hapus kategori
      await categoryRepo.delete(catId);
      final remaining = await categoryRepo.getAll();
      expect(remaining.isEmpty, isTrue);
    });

    test(
      'CRUD Produk, filter kategori, dan pencarian berjalan dengan benar',
      () async {
        // Tambah kategori untuk produk
        final catMakananId = await categoryRepo.insert(
          CategoryModel(name: 'Makanan', createdAt: DateTime.now()),
        );
        final catMinumanId = await categoryRepo.insert(
          CategoryModel(name: 'Minuman', createdAt: DateTime.now()),
        );

        // Tambah produk 1: Es Teh Manis
        final now = DateTime.now();
        final prod1Id = await productRepo.insert(
          ProductModel(
            categoryId: catMinumanId,
            name: 'Es Teh Manis',
            costPrice: 2000,
            sellingPrice: 5000,
            stock: 50,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Tambah produk 2: Nasi Goreng Spesial (non-aktif)
        await productRepo.insert(
          ProductModel(
            categoryId: catMakananId,
            name: 'Nasi Goreng Spesial',
            costPrice: 12000,
            sellingPrice: 20000,
            stock: 10,
            isActive: false,
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Ambil seluruh produk
        final all = await productRepo.getAll();
        expect(all.length, equals(2));
        expect(all.any((p) => p.categoryName == 'Minuman'), isTrue);

        // Filter kategori
        final minumanOnly = await productRepo.getAll(categoryId: catMinumanId);
        expect(minumanOnly.length, equals(1));
        expect(minumanOnly.first.name, equals('Es Teh Manis'));

        // Filter pencarian
        final searchResult = await productRepo.getAll(searchQuery: 'goreng');
        expect(searchResult.length, equals(1));
        expect(searchResult.first.name, equals('Nasi Goreng Spesial'));

        // Filter activeOnly
        final activeOnly = await productRepo.getAll(activeOnly: true);
        expect(activeOnly.length, equals(1));
        expect(activeOnly.first.name, equals('Es Teh Manis'));

        // Update produk
        final prod1 = await productRepo.getById(prod1Id);
        expect(prod1, isNotNull);
        await productRepo.update(
          prod1!.copyWith(sellingPrice: 6000, stock: 45),
        );
        final updatedProd1 = await productRepo.getById(prod1Id);
        expect(updatedProd1?.sellingPrice, equals(6000));
        expect(updatedProd1?.stock, equals(45));

        // Hapus produk
        await productRepo.delete(prod1Id);
        final afterDelete = await productRepo.getAll();
        expect(afterDelete.length, equals(1));
      },
    );
  });
}
