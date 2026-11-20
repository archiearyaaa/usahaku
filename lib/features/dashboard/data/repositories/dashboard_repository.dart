import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/dashboard_models.dart';

/// Repository untuk membaca metrik agregat, tren grafik, dan aktivitas terbaru dashboard.
/// Sesuai ARCHITECTURE.md: Dashboard membaca langsung dari database tanpa menyimpan data duplikat.
class DashboardRepository {
  final AppDatabase _appDatabase;

  DashboardRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  /// Menghitung metrik ringkasan (omzet, transaksi, biaya, HPP, laba) untuk periode tertentu
  Future<DashboardMetrics> getMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    final salesWhere = <String>[];
    final salesArgs = <dynamic>[];

    final expensesWhere = <String>[];
    final expensesArgs = <dynamic>[];

    final incomeWhere = <String>[];
    final incomeArgs = <dynamic>[];

    if (startDate != null) {
      final startIso = startDate.toIso8601String();
      salesWhere.add('sale_date >= ?');
      salesArgs.add(startIso);

      expensesWhere.add('expense_date >= ?');
      expensesArgs.add(startIso);

      incomeWhere.add('income_date >= ?');
      incomeArgs.add(startIso);
    }

    if (endDate != null) {
      final endIso = endDate.toIso8601String();
      salesWhere.add('sale_date <= ?');
      salesArgs.add(endIso);

      expensesWhere.add('expense_date <= ?');
      expensesArgs.add(endIso);

      incomeWhere.add('income_date <= ?');
      incomeArgs.add(endIso);
    }

    // 1. Agregat Penjualan (omzet & count)
    final salesWhereStr = salesWhere.isNotEmpty
        ? 'WHERE ${salesWhere.join(' AND ')}'
        : '';
    final salesRes = await db.rawQuery('''
      SELECT 
        COUNT(id) AS tx_count,
        SUM(total) AS total_omzet
      FROM sales
      $salesWhereStr
    ''', salesArgs.isNotEmpty ? salesArgs : null);

    final txCount = (salesRes.first['tx_count'] as num?)?.toInt() ?? 0;
    final totalOmzet = (salesRes.first['total_omzet'] as num?)?.toInt() ?? 0;

    // 2. Agregat HPP dari sale_items terkait penjualan periode tersebut
    final hppWhereStr = salesWhere.isNotEmpty
        ? 'WHERE s.id = si.sale_id AND ${salesWhere.map((w) => 's.$w').join(' AND ')}'
        : 'WHERE s.id = si.sale_id';

    final hppRes = await db.rawQuery('''
      SELECT SUM(si.unit_cost * si.quantity) AS total_hpp
      FROM sale_items si, sales s
      $hppWhereStr
    ''', salesArgs.isNotEmpty ? salesArgs : null);

    final totalHpp = (hppRes.first['total_hpp'] as num?)?.toInt() ?? 0;

    // 3. Agregat Pengeluaran
    final expensesWhereStr = expensesWhere.isNotEmpty
        ? 'WHERE ${expensesWhere.join(' AND ')}'
        : '';
    final expRes = await db.rawQuery('''
      SELECT SUM(amount) AS total_expenses
      FROM expenses
      $expensesWhereStr
    ''', expensesArgs.isNotEmpty ? expensesArgs : null);

    final totalExpenses =
        (expRes.first['total_expenses'] as num?)?.toInt() ?? 0;

    // 4. Agregat Pemasukan Lain (non-penjualan & non-modal awal)
    final incWhere = List<String>.from(incomeWhere);
    incWhere.add("LOWER(category) != 'modal awal'");
    final incWhereStr = 'WHERE ${incWhere.join(' AND ')}';

    final incRes = await db.rawQuery('''
      SELECT SUM(amount) AS total_income
      FROM income
      $incWhereStr
    ''', incomeArgs.isNotEmpty ? incomeArgs : null);

    final totalOtherIncome =
        (incRes.first['total_income'] as num?)?.toInt() ?? 0;

    return DashboardMetrics(
      omzet: totalOmzet,
      transactionCount: txCount,
      totalExpenses: totalExpenses,
      totalHpp: totalHpp,
      totalOtherIncome: totalOtherIncome,
    );
  }

  /// Mengambil data omzet harian untuk N hari terakhir (default: 7 hari).
  /// Mengisi nilai 0 untuk hari-hari yang tidak memiliki transaksi.
  Future<List<DailySalesPoint>> getDailySalesChartData({int days = 7}) async {
    final db = await _db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: days - 1));

    final res = await db.rawQuery(
      '''
      SELECT 
        DATE(sale_date) AS day_str,
        SUM(total) AS daily_total,
        COUNT(id) AS daily_count
      FROM sales
      WHERE sale_date >= ?
      GROUP BY DATE(sale_date)
      ORDER BY DATE(sale_date) ASC
    ''',
      [startDate.toIso8601String()],
    );

    final dataMap = <String, Map<String, dynamic>>{};
    for (final row in res) {
      final dayStr = row['day_str'] as String?;
      if (dayStr != null) {
        dataMap[dayStr] = row;
      }
    }

    final points = <DailySalesPoint>[];
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (int i = 0; i < days; i++) {
      final d = startDate.add(Duration(days: i));
      final key = dateFormat.format(d);
      final row = dataMap[key];

      final amount = (row?['daily_total'] as num?)?.toInt() ?? 0;
      final count = (row?['daily_count'] as num?)?.toInt() ?? 0;

      points.add(
        DailySalesPoint(date: d, amount: amount, transactionCount: count),
      );
    }

    return points;
  }

  /// Mengambil daftar aktivitas terbaru dari tabel sales, expenses, dan stock_movements
  Future<List<DashboardActivityItem>> getRecentActivities({
    int limit = 10,
  }) async {
    final db = await _db;
    final activities = <DashboardActivityItem>[];

    // 1. Ambil transaksi penjualan terbaru
    final sales = await db.query(
      'sales',
      orderBy: 'sale_date DESC, id DESC',
      limit: limit,
    );
    for (final s in sales) {
      activities.add(
        DashboardActivityItem(
          id: 'sale_${s['id']}',
          title: s['invoice_number'] as String,
          subtitle: 'Penjualan • ${s['payment_method']}',
          amount: (s['total'] as num).toInt(),
          type: 'sale',
          timestamp: DateTime.parse(s['sale_date'] as String),
        ),
      );
    }

    // 2. Ambil pengeluaran terbaru
    final expenses = await db.query(
      'expenses',
      orderBy: 'expense_date DESC, id DESC',
      limit: limit,
    );
    for (final e in expenses) {
      activities.add(
        DashboardActivityItem(
          id: 'expense_${e['id']}',
          title: e['title'] as String,
          subtitle: 'Pengeluaran • ${e['category']}',
          amount: (e['amount'] as num).toInt(),
          type: 'expense',
          timestamp: DateTime.parse(e['expense_date'] as String),
        ),
      );
    }

    // 3. Urutkan seluruh aktivitas berdasarkan waktu terbaru
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (activities.length > limit) {
      return activities.sublist(0, limit);
    }
    return activities;
  }
}
