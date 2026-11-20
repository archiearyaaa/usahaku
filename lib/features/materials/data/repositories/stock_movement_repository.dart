import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/stock_movement_model.dart';

/// Repository untuk tabel `stock_movements`.
/// Setiap perubahan stok dicatat sebagai movement dan memperbarui
/// saldo bahan dalam satu transaksi database (ARCHITECTURE.md aturan 6).
class StockMovementRepository {
  final AppDatabase _appDatabase;

  StockMovementRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  /// Menambah movement dan memperbarui kuantitas bahan secara atomik.
  ///
  /// Untuk type 'in': menambah kuantitas.
  /// Untuk type 'out': mengurangi kuantitas — gagal jika stok akan negatif.
  /// Untuk type 'adjustment': menetapkan kuantitas ke nilai [movement.quantity].
  ///
  /// Mengembalikan ID movement yang baru dibuat.
  /// Throws [Exception] jika stok keluar akan membuat stok negatif.
  Future<int> addMovement(StockMovementModel movement) async {
    final db = await _db;
    late int movementId;

    await db.transaction((txn) async {
      // 1. Ambil kuantitas bahan saat ini
      final rows = await txn.query(
        'materials',
        columns: ['quantity'],
        where: 'id = ?',
        whereArgs: [movement.materialId],
      );

      if (rows.isEmpty) {
        throw Exception(
          'Bahan baku dengan ID ${movement.materialId} tidak ditemukan.',
        );
      }

      final currentQty = (rows.first['quantity'] as num).toDouble();
      double newQty;

      switch (movement.type) {
        case 'in':
          newQty = currentQty + movement.quantity;
          break;
        case 'out':
          newQty = currentQty - movement.quantity;
          if (newQty < 0) {
            throw Exception(
              'Stok tidak mencukupi. '
              'Tersedia: ${currentQty.toStringAsFixed(2)}, '
              'diminta: ${movement.quantity.toStringAsFixed(2)}.',
            );
          }
          break;
        case 'adjustment':
          newQty = movement.quantity;
          break;
        default:
          throw Exception(
            'Tipe movement tidak valid: "${movement.type}". '
            'Gunakan "in", "out", atau "adjustment".',
          );
      }

      // 2. Update kuantitas bahan
      await txn.update(
        'materials',
        {'quantity': newQty, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [movement.materialId],
      );

      // 3. Simpan movement
      movementId = await txn.insert('stock_movements', movement.toMap());
    });

    return movementId;
  }

  /// Mengambil riwayat movement untuk bahan tertentu, terbaru di atas
  Future<List<StockMovementModel>> getByMaterialId(int materialId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        sm.*,
        m.name AS material_name,
        m.unit AS material_unit
      FROM stock_movements sm
      INNER JOIN materials m ON sm.material_id = m.id
      WHERE sm.material_id = ?
      ORDER BY sm.movement_date DESC, sm.id DESC
    ''',
      [materialId],
    );
    return maps.map((map) => StockMovementModel.fromMap(map)).toList();
  }

  /// Mengambil semua movement terbaru (lintas bahan), dengan limit
  Future<List<StockMovementModel>> getRecent({int limit = 20}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        sm.*,
        m.name AS material_name,
        m.unit AS material_unit
      FROM stock_movements sm
      INNER JOIN materials m ON sm.material_id = m.id
      ORDER BY sm.movement_date DESC, sm.id DESC
      LIMIT ?
    ''',
      [limit],
    );
    return maps.map((map) => StockMovementModel.fromMap(map)).toList();
  }
}
