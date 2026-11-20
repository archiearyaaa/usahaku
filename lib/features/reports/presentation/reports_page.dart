import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/models/report_summary_model.dart';
import '../data/repositories/report_repository.dart';
import '../data/services/excel_export_service.dart';
import '../data/services/pdf_export_service.dart';

/// Halaman Laporan & Rekap:
/// - Filter periode (Hari Ini, 7 Hari Terakhir, Bulan Ini, Bulan Lalu, Kustom)
/// - Tab Laba Rugi, Penjualan, dan Pengeluaran
/// - Aksi Ekspor PDF dan Ekspor Excel
class ReportsPage extends StatefulWidget {
  final ReportRepository? reportRepository;

  const ReportsPage({super.key, this.reportRepository});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final ReportRepository _reportRepo;
  late final TabController _tabController;

  int _selectedPeriod =
      2; // Default: 2 (Bulan Ini) - 0: Hari Ini, 1: 7 Hari, 2: Bulan Ini, 3: Kustom
  DateTime _customStartDate = DateTime.now();
  DateTime _customEndDate = DateTime.now();

  bool _isLoading = true;
  ReportSummaryModel? _report;

  @override
  void initState() {
    super.initState();
    _reportRepo = widget.reportRepository ?? ReportRepository();
    _tabController = TabController(length: 3, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _effectiveStartDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedPeriod) {
      case 0: // Hari Ini
        return today;
      case 1: // 7 Hari Terakhir
        return today.subtract(const Duration(days: 6));
      case 2: // Bulan Ini
        return DateTime(now.year, now.month, 1);
      case 3: // Kustom
        return DateTime(
          _customStartDate.year,
          _customStartDate.month,
          _customStartDate.day,
        );
      default:
        return today;
    }
  }

  DateTime get _effectiveEndDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 3: // Kustom
        return DateTime(
          _customEndDate.year,
          _customEndDate.month,
          _customEndDate.day,
          23,
          59,
          59,
        );
      default:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reportRepo.getReportData(
        startDate: _effectiveStartDate,
        endDate: _effectiveEndDate,
      );
      if (mounted) {
        setState(() {
          _report = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: _customStartDate,
        end: _customEndDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 3;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _loadReport();
    }
  }

  Future<void> _exportPdf() async {
    if (_report == null) return;
    try {
      final bytes = await PdfExportService.generatePdf(_report!);
      if (mounted) {
        _showExportSuccessDialog(
          title: 'PDF Berhasil Dibuat!',
          filename:
              'Laporan_USAHAKU_${DateFormatter.formatShortDate(_report!.startDate).replaceAll('/', '-')}.pdf',
          sizeBytes: bytes.length,
          icon: Icons.picture_as_pdf_outlined,
          color: AppColors.primary,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _exportExcel() {
    if (_report == null) return;
    try {
      final bytes = ExcelExportService.generateExcel(_report!);
      _showExportSuccessDialog(
        title: 'Excel Berhasil Dibuat!',
        filename:
            'Laporan_USAHAKU_${DateFormatter.formatShortDate(_report!.startDate).replaceAll('/', '-')}.xlsx',
        sizeBytes: bytes.length,
        icon: Icons.table_chart_outlined,
        color: AppColors.success,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat Excel: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showExportSuccessDialog({
    required String title,
    required String filename,
    required int sizeBytes,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, size: 48, color: color),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama file: $filename',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Ukuran dokumen: ${(sizeBytes / 1024).toStringAsFixed(1)} KB',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dokumen laporan siap digunakan untuk bahan evaluasi atau pengumpulan tugas KWU.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Rekap'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Laba Rugi'),
            Tab(text: 'Penjualan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period Chips
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('Bulan Ini', 2),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Hari Ini', 0),
                  const SizedBox(width: 8),
                  _buildPeriodChip('7 Hari', 1),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.date_range, size: 16),
                    label: Text(
                      _selectedPeriod == 3
                          ? '${DateFormatter.formatShortDate(_customStartDate)} - ${DateFormatter.formatShortDate(_customEndDate)}'
                          : 'Pilih Tanggal',
                    ),
                    backgroundColor: _selectedPeriod == 3
                        ? AppColors.primaryContainer
                        : null,
                    onPressed: _selectCustomRange,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Content Tabs
          Expanded(
            child: _isLoading || _report == null
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfitLossTab(),
                      _buildSalesTab(),
                      _buildExpensesTab(),
                    ],
                  ),
          ),

          // Bottom Export Bar
          _buildExportBar(),
        ],
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
        _loadReport();
      },
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildProfitLossTab() {
    final r = _report!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kartu Laba Bersih Utama
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Laba Bersih Sederhana',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(r.netProfit),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: r.isProfitable
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.isProfitable ? 'Surplus Usaha' : 'Defisit Periode',
                    style: TextStyle(
                      fontSize: 12,
                      color: r.isProfitable
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Rincian Komponen Laba Rugi
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Komponen',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildReportRow(
                    'Omzet Penjualan',
                    CurrencyFormatter.format(r.totalSales),
                    subtitle: '${r.totalSalesTransactions} Transaksi',
                  ),
                  _buildReportRow(
                    'Harga Pokok Penjualan (HPP)',
                    '- ${CurrencyFormatter.format(r.totalHpp)}',
                    color: AppColors.danger,
                  ),
                  const Divider(height: 16),
                  _buildReportRow(
                    'Laba Kotor (Omzet - HPP)',
                    CurrencyFormatter.format(r.grossProfit),
                    isBold: true,
                  ),
                  _buildReportRow(
                    'Total Biaya Usaha (Pengeluaran)',
                    '- ${CurrencyFormatter.format(r.totalExpenses)}',
                    color: AppColors.danger,
                  ),
                  const Divider(height: 16),
                  _buildReportRow(
                    'Laba Bersih Sederhana',
                    CurrencyFormatter.format(r.netProfit),
                    isBold: true,
                    color: r.isProfitable
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  const SizedBox(height: 12),
                  _buildReportRow(
                    'Pemasukan Non-Penjualan',
                    '+ ${CurrencyFormatter.format(r.totalOtherIncome)}',
                    color: AppColors.success,
                  ),
                  _buildReportRow(
                    'Arus Kas Bersih',
                    CurrencyFormatter.format(r.netCashFlow),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Penjelasan Keterbatasan HPP sesuai PRD.md Bagian 7 & AGENTS.md
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.hasHpp
                        ? 'Perhitungan laba memperhitungkan modal HPP barang terjual yang diinput pada menu produk serta biaya operasional yang dicatat.'
                        : 'Catatan HPP: Sebagian atau seluruh produk belum memiliki harga modal (HPP = 0), sehingga laba dihitung sementara dari omzet dikurangi pengeluaran.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    final sales = _report!.sales;
    if (sales.isEmpty) {
      return const Center(
        child: Text('Belum ada transaksi penjualan pada periode ini'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sales.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = sales[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.receipt_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              s.invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              '${DateFormatter.formatDate(s.saleDate)} • ${s.paymentMethod} • ${s.items.length} item',
            ),
            trailing: Text(
              CurrencyFormatter.format(s.total),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    final expenses = _report!.expenses;
    if (expenses.isEmpty) {
      return const Center(
        child: Text('Belum ada pengeluaran dicatat pada periode ini'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final e = expenses[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: const Icon(Icons.arrow_upward, color: AppColors.danger),
            title: Text(
              e.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              '${DateFormatter.formatDate(e.expenseDate)} • ${e.category}',
            ),
            trailing: Text(
              '- ${CurrencyFormatter.format(e.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.danger,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isBold
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _report != null ? _exportPdf : null,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Ekspor PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _report != null ? _exportExcel : null,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Ekspor Excel'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
