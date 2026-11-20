/// Model agregat ringkasan arus kas keuangan
class FinanceSummaryModel {
  final int totalSales; // Omzet penjualan
  final int totalOtherIncome; // Pemasukan tambahan non-penjualan
  final int totalExpenses; // Total pengeluaran
  final int initialCapital; // Modal awal (informasi modal)

  const FinanceSummaryModel({
    this.totalSales = 0,
    this.totalOtherIncome = 0,
    this.totalExpenses = 0,
    this.initialCapital = 0,
  });

  /// Total seluruh kas masuk (Penjualan + Pemasukan Lain)
  int get totalInflow => totalSales + totalOtherIncome;

  /// Arus kas bersih (Kas Masuk - Pengeluaran)
  int get netCashFlow => totalInflow - totalExpenses;

  /// Apakah periode ini mengalami surplus
  bool get isSurplus => netCashFlow >= 0;
}
