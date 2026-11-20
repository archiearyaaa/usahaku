import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/models/dashboard_models.dart';
import '../data/repositories/dashboard_repository.dart';
import 'widgets/sales_bar_chart_widget.dart';

/// Halaman Dashboard utama USAHAKU:
/// - Kartu ringkasan omzet, pengeluaran, laba sederhana, dan transaksi
/// - Grafik penjualan tren 7 hari
/// - Aktivitas transaksi terbaru
/// - Filter periode (Hari Ini, 7 Hari Terakhir, Bulan Ini)
class DashboardPage extends StatefulWidget {
  final DashboardRepository? dashboardRepository;

  const DashboardPage({super.key, this.dashboardRepository});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardRepository _dashboardRepo;

  int _selectedPeriod = 0; // 0: Hari Ini, 1: 7 Hari Terakhir, 2: Bulan Ini
  bool _isLoading = true;

  DashboardMetrics _metrics = const DashboardMetrics();
  List<DailySalesPoint> _chartData = [];
  List<DashboardActivityItem> _activities = [];

  @override
  void initState() {
    super.initState();
    _dashboardRepo = widget.dashboardRepository ?? DashboardRepository();
    _loadDashboardData();
  }

  DateTime? get _startDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedPeriod) {
      case 0: // Hari Ini
        return today;
      case 1: // 7 Hari Terakhir
        return today.subtract(const Duration(days: 6));
      case 2: // Bulan Ini
        return DateTime(now.year, now.month, 1);
      default:
        return today;
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final start = _startDate;
      final metrics = await _dashboardRepo.getMetrics(startDate: start);
      final chartPoints = await _dashboardRepo.getDailySalesChartData(days: 7);
      final recentActs = await _dashboardRepo.getRecentActivities(limit: 6);

      if (mounted) {
        setState(() {
          _metrics = metrics;
          _chartData = chartPoints;
          _activities = recentActs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USAHAKU'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang Aplikasi',
            onPressed: _showAboutApp,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Data',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store Header Greeting
              _buildStoreHeader(),

              const SizedBox(height: 16),

              // Filter Periode
              _buildPeriodChips(),

              const SizedBox(height: 14),

              // 4 Kartu Ringkasan (Omzet, Pengeluaran, Laba, Transaksi)
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _buildMetricsGrid(),

                const SizedBox(height: 18),

                // Grafik Penjualan 7 Hari Terakhir (P1)
                _buildChartSection(),

                const SizedBox(height: 18),

                // Aktivitas Terbaru (P1)
                _buildRecentActivitiesSection(),

                const SizedBox(height: 28),

                // Copyright by Archie Arya Manggala
                Center(
                  child: Column(
                    children: [
                      const Text(
                        AppConstants.copyright,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Aplikasi Manajemen Usaha Kuliner (Tugas KWU)',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textDisabled,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutApp() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: 'v1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/logo.png',
          width: 48,
          height: 48,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.storefront_outlined,
            color: AppColors.primary,
            size: 40,
          ),
        ),
      ),
      applicationLegalese: AppConstants.copyright,
      children: const [
        SizedBox(height: 12),
        Text(
          'Aplikasi Pencatatan Penjualan dan Keuangan Sederhana untuk Usaha Makanan & Minuman.',
        ),
        SizedBox(height: 8),
        Text(
          'Dibuat oleh Archie Arya Manggala untuk Tugas Praktik Kewirausahaan (KWU).',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'USAHAKU',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips() {
    return Row(
      children: [
        _buildChip('Hari Ini', 0),
        const SizedBox(width: 8),
        _buildChip('7 Hari Terakhir', 1),
        const SizedBox(width: 8),
        _buildChip('Bulan Ini', 2),
      ],
    );
  }

  Widget _buildChip(String label, int value) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedPeriod = value);
        _loadDashboardData();
      },
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Omzet Penjualan',
                value: CurrencyFormatter.format(_metrics.omzet),
                icon: Icons.point_of_sale_outlined,
                color: AppColors.primary,
                subtitle: '${_metrics.transactionCount} Transaksi',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Pengeluaran',
                value: CurrencyFormatter.format(_metrics.totalExpenses),
                icon: Icons.receipt_long_outlined,
                color: AppColors.danger,
                subtitle: 'Biaya Usaha',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Laba Sederhana',
                value: CurrencyFormatter.format(_metrics.estimatedProfit),
                icon: _metrics.isProfitable
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: _metrics.isProfitable
                    ? AppColors.success
                    : AppColors.danger,
                subtitle: _metrics.hasHpp
                    ? 'Omzet - HPP - Biaya'
                    : 'Omzet - Biaya (HPP 0)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Transaksi',
                value: '${_metrics.transactionCount}',
                icon: Icons.shopping_bag_outlined,
                color: AppColors.info,
                subtitle: 'Penjualan Selesai',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tren Penjualan 7 Hari Terakhir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.bar_chart, size: 20, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 16),
            SalesBarChartWidget(data: _chartData),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_activities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Belum ada aktivitas transaksi',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activities.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final act = _activities[index];
                  final isSale = act.type == 'sale';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSale
                                ? AppColors.successContainer
                                : AppColors.dangerContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSale ? Icons.point_of_sale : Icons.receipt_long,
                            color: isSale
                                ? AppColors.success
                                : AppColors.danger,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${DateFormatter.formatDateTime(act.timestamp)} • ${act.subtitle}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (act.amount != null)
                          Text(
                            '${isSale ? '+' : '-'} ${CurrencyFormatter.format(act.amount!)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSale
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
