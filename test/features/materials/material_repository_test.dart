import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:usahaku/core/database/app_database.dart';
import 'package:usahaku/features/materials/data/models/material_model.dart';
import 'package:usahaku/features/materials/data/models/stock_movement_model.dart';
import 'package:usahaku/features/materials/data/repositories/material_repository.dart';
import 'package:usahaku/features/materials/data/repositories/stock_movement_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MaterialRepository & StockMovementRepository Tests', () {
    late Database db;
    late MaterialRepository materialRepo;
    late StockMovementRepository movementRepo;

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
            await batch.commit(noResult: true);
          },
        ),
      );

      AppDatabase.instance.setDatabaseForTesting(db);
      materialRepo = MaterialRepository();
      movementRepo = StockMovementRepository();
    });

    tearDown(() async {
      await db.close();
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test('CRUD Bahan Baku berjalan dengan benar', () async {
      final now = DateTime.now();

      // 1. Insert bahan baku
      final id = await materialRepo.insert(
        MaterialModel(
          name: 'Gula Pasir',
          unit: 'kg',
          quantity: 10,
          minimumStock: 2,
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(id, isPositive);

      // 2. Ambil bahan baku
      final list = await materialRepo.getAll();
      expect(list.length, equals(1));
      expect(list.first.name, equals('Gula Pasir'));
      expect(list.first.quantity, equals(10.0));
      expect(list.first.minimumStock, equals(2.0));

      // 3. Update bahan baku
      final mat = await materialRepo.getById(id);
      expect(mat, isNotNull);
      await materialRepo.update(
        mat!.copyWith(name: 'Gula Pasir Premium', minimumStock: 3),
      );
      final updated = await materialRepo.getById(id);
      expect(updated?.name, equals('Gula Pasir Premium'));
      expect(updated?.minimumStock, equals(3.0));

      // 4. Hapus bahan baku
      await materialRepo.delete(id);
      final remaining = await materialRepo.getAll();
      expect(remaining.isEmpty, isTrue);
    });

    test('Pencarian bahan baku berdasarkan kata kunci', () async {
      final now = DateTime.now();
      await materialRepo.insert(
        MaterialModel(
          name: 'Biji Kopi Robusta',
          unit: 'kg',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await materialRepo.insert(
        MaterialModel(
          name: 'Biji Kopi Arabika',
          unit: 'kg',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await materialRepo.insert(
        MaterialModel(
          name: 'Susu UHT Full Cream',
          unit: 'liter',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final coffeeList = await materialRepo.getAll(searchQuery: 'kopi');
      expect(coffeeList.length, equals(2));

      final milkList = await materialRepo.getAll(searchQuery: 'susu');
      expect(milkList.length, equals(1));
      expect(milkList.first.name, equals('Susu UHT Full Cream'));
    });

    test('Stok masuk menambah kuantitas bahan secara atomik', () async {
      final now = DateTime.now();
      final matId = await materialRepo.insert(
        MaterialModel(
          name: 'Beras',
          unit: 'kg',
          quantity: 5,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Tambah stok masuk 10 kg
      final moveId = await movementRepo.addMovement(
        StockMovementModel(
          materialId: matId,
          type: 'in',
          quantity: 10,
          note: 'Beli di pasar',
          movementDate: now,
          createdAt: now,
        ),
      );
      expect(moveId, isPositive);

      final mat = await materialRepo.getById(matId);
      expect(mat?.quantity, equals(15.0));

      final history = await movementRepo.getByMaterialId(matId);
      expect(history.length, equals(1));
      expect(history.first.type, equals('in'));
      expect(history.first.quantity, equals(10.0));
      expect(history.first.note, equals('Beli di pasar'));
      expect(history.first.materialName, equals('Beras'));
    });

    test('Stok keluar mengurangi kuantitas bahan secara atomik', () async {
      final now = DateTime.now();
      final matId = await materialRepo.insert(
        MaterialModel(
          name: 'Minyak Goreng',
          unit: 'liter',
          quantity: 10,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Stok keluar 3 liter
      await movementRepo.addMovement(
        StockMovementModel(
          materialId: matId,
          type: 'out',
          quantity: 3,
          note: 'Pemakaian dapur',
          movementDate: now,
          createdAt: now,
        ),
      );

      final mat = await materialRepo.getById(matId);
      expect(mat?.quantity, equals(7.0));
    });

    test(
      'Validasi stok keluar: menolak transaksi jika membuat stok negatif',
      () async {
        final now = DateTime.now();
        final matId = await materialRepo.insert(
          MaterialModel(
            name: 'Telur Ayam',
            unit: 'butir',
            quantity: 10,
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Mencoba mengeluarkan 15 butir saat stok hanya 10
        expect(
          () async => await movementRepo.addMovement(
            StockMovementModel(
              materialId: matId,
              type: 'out',
              quantity: 15,
              movementDate: now,
              createdAt: now,
            ),
          ),
          throwsA(isA<Exception>()),
        );

        // Pastikan kuantitas tetap 10 dan tidak ada movement tercatat (transaksi rollback)
        final mat = await materialRepo.getById(matId);
        expect(mat?.quantity, equals(10.0));

        final history = await movementRepo.getByMaterialId(matId);
        expect(history.isEmpty, isTrue);
      },
    );

    test('Stok adjustment menetapkan kuantitas secara langsung', () async {
      final now = DateTime.now();
      final matId = await materialRepo.insert(
        MaterialModel(
          name: 'Garam',
          unit: 'bungkus',
          quantity: 5,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await movementRepo.addMovement(
        StockMovementModel(
          materialId: matId,
          type: 'adjustment',
          quantity: 8,
          note: 'Opname fisik',
          movementDate: now,
          createdAt: now,
        ),
      );

      final mat = await materialRepo.getById(matId);
      expect(mat?.quantity, equals(8.0));
    });

    test('Peringatan stok minimum (getLowStock)', () async {
      final now = DateTime.now();
      // Bahan 1: stok 2, min 5 -> low stock
      await materialRepo.insert(
        MaterialModel(
          name: 'Kopi',
          unit: 'kg',
          quantity: 2,
          minimumStock: 5,
          createdAt: now,
          updatedAt: now,
        ),
      );
      // Bahan 2: stok 10, min 5 -> aman
      await materialRepo.insert(
        MaterialModel(
          name: 'Gula',
          unit: 'kg',
          quantity: 10,
          minimumStock: 5,
          createdAt: now,
          updatedAt: now,
        ),
      );
      // Bahan 3: stok 0, min null -> tidak ada batas
      await materialRepo.insert(
        MaterialModel(
          name: 'Cup Plastik',
          unit: 'pcs',
          quantity: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final lowStockList = await materialRepo.getLowStock();
      expect(lowStockList.length, equals(1));
      expect(lowStockList.first.name, equals('Kopi'));
    });

    test(
      'Cascade delete: menghapus bahan menghapus riwayat pergerakan stok',
      () async {
        final now = DateTime.now();
        final matId = await materialRepo.insert(
          MaterialModel(
            name: 'Coklat Bubuk',
            unit: 'kg',
            quantity: 5,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await movementRepo.addMovement(
          StockMovementModel(
            materialId: matId,
            type: 'in',
            quantity: 5,
            movementDate: now,
            createdAt: now,
          ),
        );

        // Hapus bahan
        await materialRepo.delete(matId);

        // Pastikan movement ikut terhapus
        final history = await movementRepo.getByMaterialId(matId);
        expect(history.isEmpty, isTrue);
      },
    );
  });
}
