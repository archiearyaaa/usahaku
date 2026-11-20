import 'package:flutter_test/flutter_test.dart';
import 'package:usahaku/features/products/data/models/product_model.dart';
import 'package:usahaku/features/sales/data/models/cart_item_model.dart';
import 'package:usahaku/features/sales/data/sales_calculation.dart';

void main() {
  group('SalesCalculation Business Logic Tests', () {
    final now = DateTime.now();

    final product1 = ProductModel(
      id: 1,
      name: 'Es Teh Manis',
      costPrice: 1500,
      sellingPrice: 5000,
      createdAt: now,
      updatedAt: now,
    );

    final product2 = ProductModel(
      id: 2,
      name: 'Nasi Goreng',
      costPrice: 8000,
      sellingPrice: 15000,
      createdAt: now,
      updatedAt: now,
    );

    test('Hitung subtotal dari beberapa item keranjang', () {
      final items = [
        CartItemModel(product: product1, quantity: 2), // 2 x 5.000 = 10.000
        CartItemModel(product: product2, quantity: 1), // 1 x 15.000 = 15.000
      ];

      final subtotal = SalesCalculation.calculateSubtotal(items);
      expect(subtotal, equals(25000));
    });

    test('Hitung total belanja dengan diskon valid', () {
      const subtotal = 50000;
      const discount = 5000;

      final total = SalesCalculation.calculateTotal(subtotal, discount);
      expect(total, equals(45000));
    });

    test('Diskon negatif atau melebihi subtotal otomatis di-clamp', () {
      const subtotal = 20000;

      // Diskon melebihi subtotal -> total menjadi 0
      final totalOverDiscount = SalesCalculation.calculateTotal(
        subtotal,
        25000,
      );
      expect(totalOverDiscount, equals(0));

      // Diskon negatif -> dianggap 0
      final totalNegativeDiscount = SalesCalculation.calculateTotal(
        subtotal,
        -5000,
      );
      expect(totalNegativeDiscount, equals(20000));
    });

    test('Hitung uang kembalian dengan benar', () {
      const total = 35000;

      // Uang lebih
      expect(SalesCalculation.calculateChange(total, 50000), equals(15000));

      // Uang pas
      expect(SalesCalculation.calculateChange(total, 35000), equals(0));

      // Uang kurang (tidak boleh negatif)
      expect(SalesCalculation.calculateChange(total, 20000), equals(0));
    });

    test('Validasi kelayakan pembayaran (isPaymentValid)', () {
      const total = 25000;

      expect(SalesCalculation.isPaymentValid(total, 30000), isTrue);
      expect(SalesCalculation.isPaymentValid(total, 25000), isTrue);
      expect(SalesCalculation.isPaymentValid(total, 20000), isFalse);
      expect(SalesCalculation.isPaymentValid(0, 0), isFalse);
    });

    test('Hitung total HPP/modal dari keranjang', () {
      final items = [
        CartItemModel(product: product1, quantity: 2), // 2 x 1.500 = 3.000
        CartItemModel(product: product2, quantity: 2), // 2 x 8.000 = 16.000
      ];

      final totalCost = SalesCalculation.calculateCostTotal(items);
      expect(totalCost, equals(19000));
    });
  });
}
