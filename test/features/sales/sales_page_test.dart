import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:usahaku/core/theme/app_theme.dart';
import 'package:usahaku/features/products/data/models/category_model.dart';
import 'package:usahaku/features/products/data/models/product_model.dart';
import 'package:usahaku/features/products/data/repositories/category_repository.dart';
import 'package:usahaku/features/products/data/repositories/product_repository.dart';
import 'package:usahaku/features/sales/data/models/sale_item_model.dart';
import 'package:usahaku/features/sales/data/models/sale_model.dart';
import 'package:usahaku/features/sales/data/repositories/sale_repository.dart';
import 'package:usahaku/features/sales/presentation/sales_page.dart';

class FakeSaleProductRepository extends ProductRepository {
  final List<ProductModel> _items;

  FakeSaleProductRepository([List<ProductModel>? items])
    : _items = items != null ? List.from(items) : [];

  @override
  Future<List<ProductModel>> getAll({
    int? categoryId,
    String? searchQuery,
    bool? activeOnly,
  }) async {
    return _items.where((p) {
      if (activeOnly == true && !p.isActive) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        if (!p.name.toLowerCase().contains(searchQuery.trim().toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}

class FakeSaleCategoryRepository extends CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll() async => [];

  @override
  Future<void> seedDefaultCategoriesIfEmpty() async {}
}

class FakeSaleRepository extends SaleRepository {
  final List<SaleModel> _sales = [];

  @override
  Future<String> generateInvoiceNumber([DateTime? date]) async {
    return 'INV-20261120-0001';
  }

  @override
  Future<SaleModel> createSale({
    required SaleModel sale,
    required List<SaleItemModel> items,
  }) async {
    final newSale = sale.copyWith(id: _sales.length + 1, items: items);
    _sales.add(newSale);
    return newSale;
  }

  @override
  Future<List<SaleModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async => List.unmodifiable(_sales);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('SalesPage Widget Tests', () {
    testWidgets(
      'Menampilkan daftar produk aktif dan menambah ke keranjang belanja',
      (WidgetTester tester) async {
        final now = DateTime.now();
        final fakeProdRepo = FakeSaleProductRepository([
          ProductModel(
            id: 1,
            name: 'Es Kopi Gula Aren',
            costPrice: 5000,
            sellingPrice: 15000,
            stock: 20,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
          ProductModel(
            id: 2,
            name: 'Kentang Goreng',
            costPrice: 6000,
            sellingPrice: 12000,
            stock: 15,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: SalesPage(
              productRepository: fakeProdRepo,
              categoryRepository: FakeSaleCategoryRepository(),
              saleRepository: FakeSaleRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi produk muncul di kasir
        expect(find.text('Es Kopi Gula Aren'), findsOneWidget);
        expect(find.text('Kentang Goreng'), findsOneWidget);

        // Awalnya keranjang belum muncul (tidak ada bottomSheet)
        expect(find.text('Item di Keranjang'), findsNothing);

        // Tap produk pertama untuk menambah ke keranjang
        await tester.tap(find.text('Es Kopi Gula Aren'));
        await tester.pumpAndSettle();

        // Sekarang bar keranjang muncul dengan total 1 item dan Rp 15.000
        expect(find.text('1 Item di Keranjang'), findsOneWidget);
        expect(find.text('Bayar'), findsOneWidget);

        // Tap sekali lagi produk pertama
        await tester.tap(find.text('Es Kopi Gula Aren'));
        await tester.pumpAndSettle();

        // Keranjang menjadi 2 item dan Rp 30.000
        expect(find.text('2 Item di Keranjang'), findsOneWidget);
      },
    );
  });
}
