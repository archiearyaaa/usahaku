import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/sale_item_model.dart';
import '../models/sale_model.dart';

/// Repository untuk tabel `sales` dan `sale_items`.
/// Menyimpan transaksi dan detail item secara atomik dalam satu DB transaction.
class SaleRepository {
  final AppDatabase _appDatabase;

  SaleRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  /// Menghasilkan nomor nota unik: INV-YYYYMMDD-XXXX (contoh: INV-20261120-0001)
  Future<String> generateInvoiceNumber([DateTime? date]) async {
    final db = await _db;
    final targetDate = date ?? DateTime.now();
    final datePrefix = DateFormat('yyyyMMdd').format(targetDate);
    final prefix = 'INV-$datePrefix-';

    final result = await db.rawQuery(
      '''
      SELECT invoice_number FROM sales
      WHERE invoice_number LIKE ?
      ORDER BY id DESC
      LIMIT 1
    ''',
      ['$prefix%'],
    );

    int nextIndex = 1;
    if (result.isNotEmpty) {
      final lastInvoice = result.first['invoice_number'] as String;
      final parts = lastInvoice.split('-');
      if (parts.length >= 3) {
        final lastNum = int.tryParse(parts[2]);
        if (lastNum != null) {
          nextIndex = lastNum + 1;
        }
      }
    }

    return '$prefix${nextIndex.toString().padLeft(4, '0')}';
  }

  /// Menyimpan transaksi penjualan dan item-itemnya secara atomik.
  /// Jika ada item gagal disimpan, seluruh transaksi di-rollback.
  /// Juga memperbarui stok produk jika stok produk dicatat.
  Future<SaleModel> createSale({
    required SaleModel sale,
    required List<SaleItemModel> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('Keranjang penjualan tidak boleh kosong.');
    }
    if (sale.amountPaid < sale.total) {
      throw Exception('Nominal pembayaran kurang dari total belanja.');
    }

    final db = await _db;
    late SaleModel createdSale;

    await db.transaction((txn) async {
      // 1. Simpan transaksi utama ke tabel sales
      final saleMap = sale.toMap();
      final saleId = await txn.insert('sales', saleMap);

      final insertedItems = <SaleItemModel>[];

      // 2. Simpan setiap item ke tabel sale_items
      for (final item in items) {
        final itemMap = item.toMap();
        itemMap['sale_id'] = saleId;
        final itemId = await txn.insert('sale_items', itemMap);
        insertedItems.add(item.copyWith(id: itemId, saleId: saleId));

        // 3. Opsional: kurangi stok produk jika produk memiliki id
        if (item.productId != null) {
          // Periksa apakah item ini merupakan produk paket / bundling
          List<Map<String, dynamic>> bundleRows = [];
          try {
            bundleRows = await txn.rawQuery(
              'SELECT item_product_id, quantity FROM product_bundles WHERE bundle_product_id = ?',
              [item.productId],
            );
          } catch (_) {
            bundleRows = [];
          }

          if (bundleRows.isNotEmpty) {
            // Ini produk paket: kurangi stok masing-masing komponen penyusunnya (misal: Misopa)
            for (final bRow in bundleRows) {
              final compId = (bRow['item_product_id'] as num).toInt();
              final compQty = (bRow['quantity'] as num).toInt() * item.quantity;
              await txn.rawUpdate(
                '''
                UPDATE products
                SET stock = MAX(0, stock - ?),
                    updated_at = ?
                WHERE id = ?
              ''',
                [compQty, DateTime.now().toIso8601String(), compId],
              );
            }
          } else {
            // Produk standar: kurangi stok produk itu sendiri
            await txn.rawUpdate(
              '''
              UPDATE products
              SET stock = MAX(0, stock - ?),
                  updated_at = ?
              WHERE id = ?
            ''',
              [item.quantity, DateTime.now().toIso8601String(), item.productId],
            );
          }
        }
      }

      createdSale = sale.copyWith(id: saleId, items: insertedItems);
    });

    return createdSale;
  }

  /// Mengambil daftar riwayat penjualan dengan opsi rentang tanggal dan pencarian nomor nota
  Future<List<SaleModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    final db = await _db;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('sale_date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('sale_date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('LOWER(invoice_number) LIKE ?');
      whereArgs.add('%${searchQuery.trim().toLowerCase()}%');
    }

    final whereString = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final sql =
        '''
      SELECT * FROM sales
      $whereString
      ORDER BY sale_date DESC, id DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      sql,
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps.map((m) => SaleModel.fromMap(m)).toList();
  }

  /// Mengambil satu transaksi penjualan beserta seluruh item snapshot-nya
  Future<SaleModel?> getById(int id) async {
    final db = await _db;

    final saleRows = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (saleRows.isEmpty) return null;

    final itemRows = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );

    final items = itemRows.map((m) => SaleItemModel.fromMap(m)).toList();
    return SaleModel.fromMap(saleRows.first, items: items);
  }

  /// Menghapus transaksi (sale_items otomatis terhapus via CASCADE delete)
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }
}
