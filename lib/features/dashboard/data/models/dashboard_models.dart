/// Model metrik ringkasan untuk dashboard usaha.
class DashboardMetrics {
  final int omzet; // Total nilai penjualan bersih
  final int transactionCount; // Jumlah transaksi
  final int totalExpenses; // Total biaya usaha
  final int totalHpp; // Total harga pokok penjualan (HPP barang terjual)
  final int totalOtherIncome; // Pemasukan tambahan non-penjualan

  const DashboardMetrics({
    this.omzet = 0,
    this.transactionCount = 0,
    this.totalExpenses = 0,
    this.totalHpp = 0,
    this.totalOtherIncome = 0,
  });

  /// Laba kotor = Omzet - HPP
  int get grossProfit => omzet - totalHpp;

  /// Laba sederhana = Omzet - HPP - Biaya Usaha
  int get estimatedProfit => omzet - totalHpp - totalExpenses;

  /// Apakah periode ini menguntungkan
  bool get isProfitable => estimatedProfit >= 0;

  /// Apakah data HPP tersedia (> 0)
  bool get hasHpp => totalHpp > 0;
}

/// Model titik data grafik penjualan harian
class DailySalesPoint {
  final DateTime date;
  final int amount; // Total omzet pada hari tersebut
  final int transactionCount;

  const DailySalesPoint({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });
}

/// Model aktivitas gabungan terbaru untuk feed dashboard
class DashboardActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final int? amount;
  final String type; // 'sale', 'expense', 'stock'
  final DateTime timestamp;

  const DashboardActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.amount,
    required this.type,
    required this.timestamp,
  });
}
