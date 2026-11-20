import 'models/cart_item_model.dart';

/// Helper kalkulasi bisnis penjualan sesuai ARCHITECTURE.md Bagian 7:
/// - Total item = kuantitas × harga satuan
/// - Subtotal = jumlah seluruh total item
/// - Total transaksi = subtotal − diskon
/// - Kembalian = jumlah dibayar − total, tidak boleh negatif untuk transaksi lunas
/// - Seluruh nominal uang bertipe integer Rupiah (tidak menggunakan floating point/double)
class SalesCalculation {
  SalesCalculation._();

  /// Menghitung subtotal dari daftar item keranjang belanja
  static int calculateSubtotal(List<CartItemModel> items) {
    return items.fold<int>(0, (sum, item) => sum + item.lineTotal);
  }

  /// Menghitung total setelah diskon
  /// Diskon tidak boleh kurang dari 0 atau melebihi subtotal
  static int calculateTotal(int subtotal, int discount) {
    if (subtotal < 0) return 0;
    final validDiscount = discount.clamp(0, subtotal);
    return subtotal - validDiscount;
  }

  /// Menghitung uang kembalian
  /// Mengembalikan nilai kembalian (amountPaid - total)
  static int calculateChange(int total, int amountPaid) {
    final change = amountPaid - total;
    return change < 0 ? 0 : change;
  }

  /// Memeriksa apakah pembayaran lunas (amountPaid >= total)
  static bool isPaymentValid(int total, int amountPaid) {
    if (total <= 0) return false;
    return amountPaid >= total;
  }

  /// Menghitung estimasi HPP/modal dari keranjang
  static int calculateCostTotal(List<CartItemModel> items) {
    return items.fold<int>(0, (sum, item) => sum + item.lineCost);
  }
}
