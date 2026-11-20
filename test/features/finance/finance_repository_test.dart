import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:usahaku/core/database/app_database.dart';
import 'package:usahaku/features/finance/data/models/expense_model.dart';
import 'package:usahaku/features/finance/data/models/income_model.dart';
import 'package:usahaku/features/finance/data/repositories/expense_repository.dart';
import 'package:usahaku/features/finance/data/repositories/income_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('IncomeRepository & ExpenseRepository SQLite Tests', () {
    late Database db;
    late IncomeRepository incomeRepo;
    late ExpenseRepository expenseRepo;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            final batch = db.batch();
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
            await batch.commit(noResult: true);
          },
        ),
      );

      AppDatabase.instance.setDatabaseForTesting(db);
      incomeRepo = IncomeRepository();
      expenseRepo = ExpenseRepository();
    });

    tearDown(() async {
      await db.close();
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test('CRUD Pemasukan (Income) dan pemisahan Modal Awal', () async {
      final now = DateTime.now();

      // 1. Simpan modal awal
      final idModal = await incomeRepo.insert(
        IncomeModel(
          title: 'Modal Tabungan Pribadi',
          category: 'Modal Awal',
          amount: 5000000,
          incomeDate: now,
          createdAt: now,
        ),
      );
      expect(idModal, isPositive);

      // 2. Simpan pendapatan lain
      await incomeRepo.insert(
        IncomeModel(
          title: 'Hadiah Lomba KWU',
          category: 'Hadiah/Bonus',
          amount: 1000000,
          incomeDate: now,
          createdAt: now,
        ),
      );

      // 3. Ambil semua pemasukan
      final all = await incomeRepo.getAll();
      expect(all.length, equals(2));

      // 4. Modal awal terpisah
      final modalTotal = await incomeRepo.getInitialCapitalTotal();
      expect(modalTotal, equals(5000000));

      final totalAll = await incomeRepo.getTotalAmount();
      expect(totalAll, equals(6000000));

      // 5. Update & Delete
      final item = await incomeRepo.getById(idModal);
      expect(item, isNotNull);
      await incomeRepo.update(item!.copyWith(amount: 5500000));
      final updated = await incomeRepo.getById(idModal);
      expect(updated?.amount, equals(5500000));

      await incomeRepo.delete(idModal);
      final afterDelete = await incomeRepo.getAll();
      expect(afterDelete.length, equals(1));
    });

    test(
      'CRUD Pengeluaran (Expense) dan kalkulasi total per periode',
      () async {
        final now = DateTime.now();

        // 1. Tambah pengeluaran
        final id1 = await expenseRepo.insert(
          ExpenseModel(
            title: 'Beli Gula dan Kopi',
            category: 'Bahan Baku',
            amount: 150000,
            expenseDate: now,
            createdAt: now,
          ),
        );
        expect(id1, isPositive);

        final id2 = await expenseRepo.insert(
          ExpenseModel(
            title: 'Sewa Tenda Bazar',
            category: 'Sewa Tempat',
            amount: 300000,
            expenseDate: now,
            createdAt: now,
          ),
        );
        expect(id2, isPositive);

        // 2. Ambil list pengeluaran
        final all = await expenseRepo.getAll();
        expect(all.length, equals(2));

        // 3. Filter kategori
        final bahanBakuOnly = await expenseRepo.getAll(category: 'Bahan Baku');
        expect(bahanBakuOnly.length, equals(1));
        expect(bahanBakuOnly.first.title, equals('Beli Gula dan Kopi'));

        // 4. Filter search query
        final searchResult = await expenseRepo.getAll(searchQuery: 'tenda');
        expect(searchResult.length, equals(1));
        expect(searchResult.first.category, equals('Sewa Tempat'));

        // 5. Total pengeluaran
        final total = await expenseRepo.getTotalAmount();
        expect(total, equals(450000));

        // 6. Delete
        await expenseRepo.delete(id1);
        final remaining = await expenseRepo.getAll();
        expect(remaining.length, equals(1));
      },
    );
  });
}
