import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:usahaku/core/theme/app_theme.dart';
import 'package:usahaku/features/finance/data/models/expense_model.dart';
import 'package:usahaku/features/finance/data/models/income_model.dart';
import 'package:usahaku/features/finance/data/repositories/expense_repository.dart';
import 'package:usahaku/features/finance/data/repositories/income_repository.dart';
import 'package:usahaku/features/finance/presentation/finance_page.dart';
import 'package:usahaku/features/sales/data/models/sale_model.dart';
import 'package:usahaku/features/sales/data/repositories/sale_repository.dart';

class FakeFinanceExpenseRepository extends ExpenseRepository {
  final List<ExpenseModel> _items;

  FakeFinanceExpenseRepository([List<ExpenseModel>? items])
    : _items = items != null ? List.from(items) : [];

  @override
  Future<List<ExpenseModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? searchQuery,
  }) async => List.unmodifiable(_items);

  @override
  Future<int> getTotalAmount({DateTime? startDate, DateTime? endDate}) async {
    return _items.fold<int>(0, (sum, e) => sum + e.amount);
  }
}

class FakeFinanceIncomeRepository extends IncomeRepository {
  final List<IncomeModel> _items;

  FakeFinanceIncomeRepository([List<IncomeModel>? items])
    : _items = items != null ? List.from(items) : [];

  @override
  Future<List<IncomeModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? searchQuery,
  }) async => List.unmodifiable(_items);

  @override
  Future<int> getTotalAmount({
    DateTime? startDate,
    DateTime? endDate,
    bool excludeInitialCapital = false,
  }) async {
    return _items
        .where((i) => !excludeInitialCapital || !i.isInitialCapital)
        .fold<int>(0, (sum, i) => sum + i.amount);
  }

  @override
  Future<int> getInitialCapitalTotal() async {
    return _items
        .where((i) => i.isInitialCapital)
        .fold<int>(0, (sum, i) => sum + i.amount);
  }
}

class FakeFinanceSaleRepository extends SaleRepository {
  final List<SaleModel> _sales;

  FakeFinanceSaleRepository([List<SaleModel>? sales])
    : _sales = sales != null ? List.from(sales) : [];

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

  group('FinancePage Widget Tests', () {
    testWidgets('Menampilkan ringkasan arus kas dan daftar pengeluaran', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();

      final fakeExpenses = FakeFinanceExpenseRepository([
        ExpenseModel(
          id: 1,
          title: 'Beli Cup Minuman',
          category: 'Kemasan',
          amount: 50000,
          expenseDate: now,
          createdAt: now,
        ),
      ]);

      final fakeIncomes = FakeFinanceIncomeRepository([
        IncomeModel(
          id: 1,
          title: 'Modal Awal Kas',
          category: 'Modal Awal',
          amount: 1000000,
          incomeDate: now,
          createdAt: now,
        ),
      ]);

      final fakeSales = FakeFinanceSaleRepository([
        SaleModel(
          id: 1,
          invoiceNumber: 'INV-20261120-0001',
          saleDate: now,
          subtotal: 100000,
          total: 100000,
          paymentMethod: 'Tunai',
          amountPaid: 100000,
          createdAt: now,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: FinancePage(
            expenseRepository: fakeExpenses,
            incomeRepository: fakeIncomes,
            saleRepository: fakeSales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Periksa Header Ringkasan
      expect(find.text('Keuangan Usaha'), findsOneWidget);
      expect(find.text('Arus Kas Bersih'), findsOneWidget);
      expect(find.text('Total Masuk'), findsOneWidget);
      expect(find.text('Total Keluar'), findsOneWidget);

      // Periksa daftar pengeluaran di tab default
      expect(find.text('Beli Cup Minuman'), findsOneWidget);
      expect(find.text('- Rp 50.000'), findsOneWidget);

      // Pindah ke tab Pemasukan Lain
      await tester.tap(find.text('Pemasukan Lain'));
      await tester.pumpAndSettle();

      expect(find.text('Modal Awal Kas'), findsOneWidget);
      expect(find.text('+ Rp 1.000.000'), findsOneWidget);
    });
  });
}
