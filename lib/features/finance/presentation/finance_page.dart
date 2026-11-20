import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../sales/data/repositories/sale_repository.dart';
import '../data/models/expense_model.dart';
import '../data/models/finance_summary_model.dart';
import '../data/models/income_model.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/income_repository.dart';
import 'expense_form_page.dart';
import 'income_form_page.dart';

/// Halaman utama Keuangan Usaha:
/// - Ringkasan Arus Kas (Omzet, Pemasukan Lain, Pengeluaran, Saldo Bersih, Modal Awal)
/// - Filter periode (Hari Ini, 7 Hari, Bulan Ini, Semua)
/// - Sub-tab Pengeluaran dan Pemasukan Lain
/// - Tombol tambah cepat
class FinancePage extends StatefulWidget {
  final ExpenseRepository? expenseRepository;
  final IncomeRepository? incomeRepository;
  final SaleRepository? saleRepository;

  const FinancePage({
    super.key,
    this.expenseRepository,
    this.incomeRepository,
    this.saleRepository,
  });

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late final ExpenseRepository _expenseRepo;
  late final IncomeRepository _incomeRepo;
  late final SaleRepository _saleRepo;

  late final TabController _tabController;
  final _searchController = TextEditingController();

  int _selectedPeriod =
      2; // Default: 2 (Bulan Ini) - 0: Semua, 1: Hari Ini, 2: Bulan Ini
  String _searchQuery = '';
  bool _isLoading = true;

  FinanceSummaryModel _summary = const FinanceSummaryModel();
  List<ExpenseModel> _expenses = [];
  List<IncomeModel> _incomes = [];

  @override
  void initState() {
    super.initState();
    _expenseRepo = widget.expenseRepository ?? ExpenseRepository();
    _incomeRepo = widget.incomeRepository ?? IncomeRepository();
    _saleRepo = widget.saleRepository ?? SaleRepository();

    _tabController = TabController(length: 2, vsync: this);
    _loadFinanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  DateTime? get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 1: // Hari Ini
        return DateTime(now.year, now.month, now.day);
      case 2: // Bulan Ini
        return DateTime(now.year, now.month, 1);
      default: // Semua
        return null;
    }
  }

  DateTime? get _endDate => null;

  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);

    try {
      final start = _startDate;
      final end = _endDate;

      // 1. Ambil ringkasan omzet dari sales
      final sales = await _saleRepo.getAll(startDate: start, endDate: end);
      final totalSales = sales.fold<int>(0, (sum, s) => sum + s.total);

      // 2. Ambil pemasukan non-penjualan
      final incomes = await _incomeRepo.getAll(
        startDate: start,
        endDate: end,
        searchQuery: _searchQuery,
      );
      final totalOtherIncome = await _incomeRepo.getTotalAmount(
        startDate: start,
        endDate: end,
      );
      final initialCapital = await _incomeRepo.getInitialCapitalTotal();

      // 3. Ambil pengeluaran
      final expenses = await _expenseRepo.getAll(
        startDate: start,
        endDate: end,
        searchQuery: _searchQuery,
      );
      final totalExpenses = await _expenseRepo.getTotalAmount(
        startDate: start,
        endDate: end,
      );

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _incomes = incomes;
          _summary = FinanceSummaryModel(
            totalSales: totalSales,
            totalOtherIncome: totalOtherIncome,
            totalExpenses: totalExpenses,
            initialCapital: initialCapital,
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openExpenseForm([ExpenseModel? expense]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormPage(expense: expense, expenseRepository: _expenseRepo),
      ),
    );

    if (result == true) {
      _loadFinanceData();
    }
  }

  Future<void> _openIncomeForm([IncomeModel? income]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            IncomeFormPage(income: income, incomeRepository: _incomeRepo),
      ),
    );

    if (result == true) {
      _loadFinanceData();
    }
  }

  void _showAddActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: AppColors.danger,
                  ),
                ),
                title: const Text(
                  'Catat Pengeluaran',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Bahan baku, operasional, sewa, gaji, dll.',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openExpenseForm();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    color: AppColors.success,
                  ),
                ),
                title: const Text(
                  'Catat Pemasukan Lain',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Modal awal, pendapatan di luar penjualan, bonus.',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openIncomeForm();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan Usaha'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan Lain'),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Period Filter Chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        _buildPeriodChip('Bulan Ini', 2),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Hari Ini', 1),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Semua', 0),
                      ],
                    ),
                  ),

                  // Summary Card
                  _buildSummaryCard(),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari catatan atau keterangan...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _loadFinanceData();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                        _loadFinanceData();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [_buildExpensesTab(), _buildIncomesTab()],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Catat Keuangan'),
        onPressed: _showAddActionSheet,
      ),
    );
  }

  Widget _buildPeriodChip(String label, int value) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedPeriod = value);
        _loadFinanceData();
      },
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Arus Kas Bersih',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              if (_summary.initialCapital > 0)
                Text(
                  'Modal: ${CurrencyFormatter.format(_summary.initialCapital)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(_summary.netCashFlow),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _summary.isSurplus
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Masuk',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(_summary.totalInflow),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      '(Omzet ${CurrencyFormatter.format(_summary.totalSales)})',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Keluar',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(_summary.totalExpenses),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.danger,
                      ),
                    ),
                    const Text(
                      'Biaya Usaha',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return _buildEmptyState('Belum ada pengeluaran dicatat');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: _expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _expenses[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            onTap: () => _openExpenseForm(item),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${DateFormatter.formatDate(item.expenseDate)} • ${item.category}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Text(
              '- ${CurrencyFormatter.format(item.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.danger,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomesTab() {
    if (_incomes.isEmpty) {
      return _buildEmptyState('Belum ada pemasukan lain dicatat');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: _incomes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _incomes[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            onTap: () => _openIncomeForm(item),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_downward,
                color: AppColors.success,
                size: 20,
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${DateFormatter.formatDate(item.incomeDate)} • ${item.category}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Text(
              '+ ${CurrencyFormatter.format(item.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.success,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
