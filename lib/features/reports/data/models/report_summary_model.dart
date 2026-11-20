import '../../../finance/data/models/expense_model.dart';
import '../../../finance/data/models/income_model.dart';
import '../../../sales/data/models/sale_model.dart';

/// Model rekapitulasi data laporan untuk suatu periode tertentu.
class ReportSummaryModel {
  final DateTime startDate;
  final DateTime endDate;

  final int totalSales; // Total omzet penjualan
  final int totalSalesTransactions; // Jumlah transaksi
  final int totalHpp; // Total harga pokok penjualan dari sale_items
  final int totalExpenses; // Total biaya usaha
  final int totalOtherIncome; // Pemasukan tambahan non-penjualan

  final List<SaleModel> sales;
  final List<ExpenseModel> expenses;
  final List<IncomeModel> otherIncomes;

  const ReportSummaryModel({
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.totalSalesTransactions,
    required this.totalHpp,
    required this.totalExpenses,
    required this.totalOtherIncome,
    this.sales = const [],
    this.expenses = const [],
    this.otherIncomes = const [],
  });

  /// Laba Kotor = Omzet Penjualan - HPP
  int get grossProfit => totalSales - totalHpp;

  /// Laba Bersih Sederhana = Laba Kotor - Total Biaya Usaha
  int get netProfit => grossProfit - totalExpenses;

  /// Arus Kas Bersih = Total Kas Masuk - Total Pengeluaran
  int get netCashFlow => (totalSales + totalOtherIncome) - totalExpenses;

  /// Apakah periode ini menghasilkan laba bersih positif
  bool get isProfitable => netProfit >= 0;

  /// Apakah produk yang terjual memiliki data HPP tercatat
  bool get hasHpp => totalHpp > 0;
}
