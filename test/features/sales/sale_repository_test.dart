import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:usahaku/core/database/app_database.dart';
import 'package:usahaku/features/sales/data/models/sale_item_model.dart';
import 'package:usahaku/features/sales/data/models/sale_model.dart';
import 'package:usahaku/features/sales/data/repositories/sale_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SaleRepository SQLite Integration Tests', () {
    late Database db;
    late SaleRepository saleRepo;

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
                updated_at TEXT NOT NULL
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
            await batch.commit(noResult: true);
          },
        ),
      );

      AppDatabase.instance.setDatabaseForTesting(db);
      saleRepo = SaleRepository();
    });

    tearDown(() async {
      await db.close();
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test('Format nomor invoice otomatis berurutan INV-YYYYMMDD-XXXX', () async {
      final now = DateTime(2026, 11, 20);

      // Invoice pertama
      final inv1 = await saleRepo.generateInvoiceNumber(now);
      expect(inv1, equals('INV-20261120-0001'));

      // Simpan satu penjualan
      await saleRepo.createSale(
        sale: SaleModel(
          invoiceNumber: inv1,
          saleDate: now,
          subtotal: 10000,
          total: 10000,
          paymentMethod: 'Tunai',
          amountPaid: 10000,
          createdAt: now,
        ),
        items: const [
          SaleItemModel(
            productName: 'Kopi',
            quantity: 1,
            unitPrice: 10000,
            lineTotal: 10000,
          ),
        ],
      );

      // Invoice kedua harus naik 1 nomor
      final inv2 = await saleRepo.generateInvoiceNumber(now);
      expect(inv2, equals('INV-20261120-0002'));
    });

    test(
      'Menyimpan transaksi dan detail item secara atomik serta mengurangi stok produk',
      () async {
        final now = DateTime.now();

        // Buat produk di database dengan stok 20
        final prodId = await db.insert('products', {
          'name': 'Ayam Geprek',
          'cost_price': 10000,
          'selling_price': 15000,
          'stock': 20,
          'is_active': 1,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        final invoice = await saleRepo.generateInvoiceNumber(now);
        final sale = SaleModel(
          invoiceNumber: invoice,
          saleDate: now,
          subtotal: 30000,
          discount: 5000,
          total: 25000,
          paymentMethod: 'Tunai',
          amountPaid: 30000,
          changeAmount: 5000,
          note: 'Pedas level 5',
          createdAt: now,
        );

        final items = [
          SaleItemModel(
            productId: prodId,
            productName: 'Ayam Geprek',
            quantity: 2,
            unitPrice: 15000,
            unitCost: 10000,
            lineTotal: 30000,
          ),
        ];

        final created = await saleRepo.createSale(sale: sale, items: items);
        expect(created.id, isPositive);
        expect(created.items.length, equals(1));
        expect(created.items.first.id, isPositive);

        // Cek stok produk berkurang dari 20 menjadi 18
        final prodRows = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [prodId],
        );
        expect(prodRows.first['stock'], equals(18));

        // Ambil transaksi by ID beserta snapshot item
        final fetched = await saleRepo.getById(created.id!);
        expect(fetched, isNotNull);
        expect(fetched?.invoiceNumber, equals(invoice));
        expect(fetched?.items.length, equals(1));
        expect(fetched?.items.first.productName, equals('Ayam Geprek'));
        expect(fetched?.items.first.unitPrice, equals(15000));
      },
    );

    test(
      'Transaksi ditolak jika item kosong atau pembayaran kurang (atomik rollback)',
      () async {
        final now = DateTime.now();
        final invoice = await saleRepo.generateInvoiceNumber(now);

        // 1. Ditolak jika item kosong
        expect(
          () async => await saleRepo.createSale(
            sale: SaleModel(
              invoiceNumber: invoice,
              saleDate: now,
              subtotal: 10000,
              total: 10000,
              paymentMethod: 'Tunai',
              amountPaid: 10000,
              createdAt: now,
            ),
            items: const [],
          ),
          throwsA(isA<Exception>()),
        );

        // 2. Ditolak jika uang dibayar < total belanja
        expect(
          () async => await saleRepo.createSale(
            sale: SaleModel(
              invoiceNumber: invoice,
              saleDate: now,
              subtotal: 10000,
              total: 10000,
              paymentMethod: 'Tunai',
              amountPaid: 8000, // Kurang 2000
              createdAt: now,
            ),
            items: const [
              SaleItemModel(
                productName: 'Teh',
                quantity: 1,
                unitPrice: 10000,
                lineTotal: 10000,
              ),
            ],
          ),
          throwsA(isA<Exception>()),
        );

        // Pastikan tabel sales tetap kosong (rollback berhasil)
        final allSales = await saleRepo.getAll();
        expect(allSales.isEmpty, isTrue);
      },
    );

    test(
      'Cascade delete: menghapus sale otomatis menghapus sale_items',
      () async {
        final now = DateTime.now();
        final created = await saleRepo.createSale(
          sale: SaleModel(
            invoiceNumber: 'INV-TEST-001',
            saleDate: now,
            subtotal: 10000,
            total: 10000,
            paymentMethod: 'QRIS',
            amountPaid: 10000,
            createdAt: now,
          ),
          items: const [
            SaleItemModel(
              productName: 'Kopi Susu',
              quantity: 1,
              unitPrice: 10000,
              lineTotal: 10000,
            ),
          ],
        );

        await saleRepo.delete(created.id!);

        final afterDelete = await saleRepo.getById(created.id!);
        expect(afterDelete, isNull);

        final items = await db.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [created.id],
        );
        expect(items.isEmpty, isTrue);
      },
    );

    test(
      'Penjualan produk paket secara atomik memotong stok produk komponennya (Bundling Stock)',
      () async {
        final now = DateTime.now();
        // 1. Tambah produk fisik Misopa (stok 120 pcs)
        final misopaId = await db.insert('products', {
          'name': 'Misopa',
          'cost_price': 5000,
          'selling_price': 10000,
          'stock': 120,
          'is_active': 1,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        // 2. Tambah produk Paket Misopa Komplit
        final paketId = await db.insert('products', {
          'name': 'Paket Misopa Komplit',
          'cost_price': 7000,
          'selling_price': 15000,
          'stock': 0, // Stok dihitung dari komponen
          'is_active': 1,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        // 3. Hubungkan paket ke Misopa (1 paket = 1 pcs Misopa)
        await db.insert('product_bundles', {
          'bundle_product_id': paketId,
          'item_product_id': misopaId,
          'quantity': 1,
          'created_at': now.toIso8601String(),
        });

        // 4. Jual 2 Paket Misopa Komplit di kasir
        await saleRepo.createSale(
          sale: SaleModel(
            invoiceNumber: 'INV-PAKET-001',
            saleDate: now,
            subtotal: 30000,
            total: 30000,
            paymentMethod: 'Tunai',
            amountPaid: 50000,
            changeAmount: 20000,
            createdAt: now,
          ),
          items: [
            SaleItemModel(
              productId: paketId,
              productName: 'Paket Misopa Komplit',
              quantity: 2,
              unitPrice: 15000,
              lineTotal: 30000,
            ),
          ],
        );

        // 5. Pastikan stok fisik Misopa berkurang dari 120 menjadi 118 pcs!
        final updatedMisopa = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [misopaId],
        );
        expect(updatedMisopa.first['stock'], equals(118));
      },
    );
  });
}
