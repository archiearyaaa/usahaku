import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:usahaku/core/theme/app_theme.dart';
import 'package:usahaku/features/dashboard/data/models/dashboard_models.dart';
import 'package:usahaku/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:usahaku/features/dashboard/presentation/dashboard_page.dart';

class FakeDashboardRepository extends DashboardRepository {
  final DashboardMetrics metrics;
  final List<DailySalesPoint> chartPoints;
  final List<DashboardActivityItem> activities;

  FakeDashboardRepository({
    this.metrics = const DashboardMetrics(
      omzet: 150000,
      transactionCount: 8,
      totalExpenses: 40000,
      totalHpp: 50000,
    ),
    List<DailySalesPoint>? chartPoints,
    List<DashboardActivityItem>? activities,
  }) : chartPoints =
           chartPoints ??
           [
             DailySalesPoint(
               date: DateTime.now(),
               amount: 150000,
               transactionCount: 8,
             ),
           ],
       activities =
           activities ??
           [
             DashboardActivityItem(
               id: '1',
               title: 'INV-20261120-0001',
               subtitle: 'Penjualan • Tunai',
               amount: 25000,
               type: 'sale',
               timestamp: DateTime.now(),
             ),
           ];

  @override
  Future<DashboardMetrics> getMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return metrics;
  }

  @override
  Future<List<DailySalesPoint>> getDailySalesChartData({int days = 7}) async {
    return chartPoints;
  }

  @override
  Future<List<DashboardActivityItem>> getRecentActivities({
    int limit = 10,
  }) async {
    return activities;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('DashboardPage Widget Tests', () {
    testWidgets(
      'Menampilkan 4 kartu ringkasan, grafik, dan aktivitas terbaru',
      (WidgetTester tester) async {
        final fakeRepo = FakeDashboardRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: DashboardPage(dashboardRepository: fakeRepo),
          ),
        );
        await tester.pumpAndSettle();

        // Periksa Header
        expect(find.text('USAHAKU'), findsWidgets);

        // Periksa Filter Periode Chips
        expect(find.text('Hari Ini'), findsOneWidget);
        expect(find.text('7 Hari Terakhir'), findsOneWidget);
        expect(find.text('Bulan Ini'), findsOneWidget);

        // Periksa 4 Kartu Ringkasan
        expect(find.text('Omzet Penjualan'), findsOneWidget);
        expect(find.text('Rp 150.000'), findsOneWidget);

        expect(find.text('Pengeluaran'), findsOneWidget);
        expect(find.text('Rp 40.000'), findsOneWidget);

        expect(find.text('Laba Sederhana'), findsOneWidget);
        // Laba = 150.000 - 50.000 - 40.000 = 60.000
        expect(find.text('Rp 60.000'), findsOneWidget);

        expect(find.text('Total Transaksi'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);

        // Periksa Judul Grafik
        expect(find.text('Tren Penjualan 7 Hari Terakhir'), findsOneWidget);

        // Periksa Bagian Aktivitas Terbaru
        expect(find.text('Aktivitas Terbaru'), findsOneWidget);
        expect(find.text('INV-20261120-0001'), findsOneWidget);
      },
    );
  });
}
