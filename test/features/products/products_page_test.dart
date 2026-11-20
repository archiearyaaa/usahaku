import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:usahaku/core/theme/app_theme.dart';
import 'package:usahaku/features/products/data/models/category_model.dart';
import 'package:usahaku/features/products/data/models/product_model.dart';
import 'package:usahaku/features/products/data/repositories/category_repository.dart';
import 'package:usahaku/features/products/data/repositories/product_repository.dart';
import 'package:usahaku/features/products/presentation/products_page.dart';

class FakeCategoryRepository extends CategoryRepository {
  final List<CategoryModel> _items;

  FakeCategoryRepository([List<CategoryModel>? items])
    : _items = items != null ? List.from(items) : [];

  @override
  Future<List<CategoryModel>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> seedDefaultCategoriesIfEmpty() async {}

  @override
  Future<int> insert(CategoryModel category) async {
    final newId = _items.length + 1;
    _items.add(category.copyWith(id: newId));
    return newId;
  }
}

class FakeProductRepository extends ProductRepository {
  final List<ProductModel> _items;

  FakeProductRepository([List<ProductModel>? items])
    : _items = items != null ? List.from(items) : [];

  @override
  Future<List<ProductModel>> getAll({
    int? categoryId,
    String? searchQuery,
    bool? activeOnly,
  }) async {
    return _items.where((p) {
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (activeOnly == true && !p.isActive) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        if (!p.name.toLowerCase().contains(searchQuery.trim().toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<int> insert(ProductModel product) async {
    final newId = _items.length + 1;
    _items.add(product.copyWith(id: newId));
    return newId;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ProductsPage Widget Tests', () {
    testWidgets('Menampilkan empty state saat belum ada produk', (
      WidgetTester tester,
    ) async {
      final fakeCatRepo = FakeCategoryRepository();
      final fakeProdRepo = FakeProductRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProductsPage(
            categoryRepository: fakeCatRepo,
            productRepository: fakeProdRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Produk & Bahan'), findsOneWidget);
      expect(find.text('Belum ada produk yang didaftarkan'), findsOneWidget);
      expect(find.text('Tambah Produk'), findsOneWidget);
    });

    testWidgets('Menampilkan daftar produk dan memfilter pencarian', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final fakeCatRepo = FakeCategoryRepository([
        CategoryModel(id: 1, name: 'Minuman', createdAt: now),
      ]);

      final fakeProdRepo = FakeProductRepository([
        ProductModel(
          id: 1,
          categoryId: 1,
          categoryName: 'Minuman',
          name: 'Kopi Susu Gula Aren',
          costPrice: 8000,
          sellingPrice: 18000,
          stock: 25,
          createdAt: now,
          updatedAt: now,
        ),
        ProductModel(
          id: 2,
          categoryId: 1,
          categoryName: 'Minuman',
          name: 'Roti Bakar Coklat',
          costPrice: 7000,
          sellingPrice: 15000,
          stock: 10,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProductsPage(
            categoryRepository: fakeCatRepo,
            productRepository: fakeProdRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kopi Susu Gula Aren'), findsOneWidget);
      expect(find.text('Roti Bakar Coklat'), findsOneWidget);

      // Cari "Kopi"
      await tester.enterText(find.byType(TextField).first, 'Kopi');
      await tester.pumpAndSettle();

      expect(find.text('Kopi Susu Gula Aren'), findsOneWidget);
      expect(find.text('Roti Bakar Coklat'), findsNothing);
    });
  });
}
