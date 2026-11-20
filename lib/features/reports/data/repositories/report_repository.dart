import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../finance/data/models/expense_model.dart';
import '../../../finance/data/models/income_model.dart';
import '../../../sales/data/models/sale_item_model.dart';
import '../../../sales/data/models/sale_model.dart';
import '../models/report_summary_model.dart';

/// Repository untuk menarik seluruh data sumber laporan periode secara konsisten dari SQLite.
class ReportRepository {
  final AppDatabase _appDatabase;

  ReportRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  /// Mengambil data laporan terpadu berdasarkan rentang tanggal [startDate] dan [endDate].
  Future<ReportSummaryModel> getReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;
    final startIso = startDate.toIso8601String();
    final endIso = endDate.toIso8601String();

    // 1. Ambil Penjualan beserta Item Snapshot
    final saleMaps = await db.rawQuery(
      '''
      SELECT * FROM sales
      WHERE sale_date >= ? AND sale_date <= ?
      ORDER BY sale_date DESC, id DESC
    ''',
      [startIso, endIso],
    );

    final salesList = <SaleModel>[];
    int totalHpp = 0;

    for (final sm in saleMaps) {
      final saleId = sm['id'] as int;
      final itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final items = itemMaps.map((im) {
        final item = SaleItemModel.fromMap(im);
        totalHpp += (item.unitCost * item.quantity);
        return item;
      }).toList();

      salesList.add(SaleModel.fromMap(sm, items: items));
    }

    final totalSales = salesList.fold<int>(0, (sum, s) => sum + s.total);

    // 2. Ambil Pengeluaran
    final expenseMaps = await db.rawQuery(
      '''
      SELECT * FROM expenses
      WHERE expense_date >= ? AND expense_date <= ?
      ORDER BY expense_date DESC, id DESC
    ''',
      [startIso, endIso],
    );

    final expensesList = expenseMaps
        .map((em) => ExpenseModel.fromMap(em))
        .toList();
    final totalExpenses = expensesList.fold<int>(0, (sum, e) => sum + e.amount);

    // 3. Ambil Pemasukan Non-Penjualan
    final incomeMaps = await db.rawQuery(
      '''
      SELECT * FROM income
      WHERE income_date >= ? AND income_date <= ?
      ORDER BY income_date DESC, id DESC
    ''',
      [startIso, endIso],
    );

    final incomeList = incomeMaps.map((im) => IncomeModel.fromMap(im)).toList();
    final totalOtherIncome = incomeList.fold<int>(
      0,
      (sum, i) => sum + i.amount,
    );

    return ReportSummaryModel(
      startDate: startDate,
      endDate: endDate,
      totalSales: totalSales,
      totalSalesTransactions: salesList.length,
      totalHpp: totalHpp,
      totalExpenses: totalExpenses,
      totalOtherIncome: totalOtherIncome,
      sales: salesList,
      expenses: expensesList,
      otherIncomes: incomeList,
    );
  }
}
