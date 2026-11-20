import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:usahaku/core/theme/app_theme.dart';
import 'package:usahaku/features/reports/data/models/report_summary_model.dart';
import 'package:usahaku/features/reports/data/repositories/report_repository.dart';
import 'package:usahaku/features/reports/presentation/reports_page.dart';

class FakeReportRepository extends ReportRepository {
  final ReportSummaryModel reportData;

  FakeReportRepository([ReportSummaryModel? data])
    : reportData =
          data ??
          ReportSummaryModel(
            startDate: DateTime(2026, 11, 1),
            endDate: DateTime(2026, 11, 30),
            totalSales: 200000,
            totalSalesTransactions: 5,
            totalHpp: 80000,
            totalExpenses: 40000,
            totalOtherIncome: 10000,
          );

  @override
  Future<ReportSummaryModel> getReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return reportData;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ReportsPage Widget Tests', () {
    testWidgets(
      'Menampilkan ringkasan laba bersih, tab navigasi, dan tombol ekspor',
      (WidgetTester tester) async {
        final fakeRepo = FakeReportRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: ReportsPage(reportRepository: fakeRepo),
          ),
        );
        await tester.pumpAndSettle();

        // Periksa Header & Judul
        expect(find.text('Laporan & Rekap'), findsOneWidget);

        // Periksa Tab Laba Rugi
        expect(find.text('Laba Rugi'), findsOneWidget);
        expect(find.text('Penjualan'), findsOneWidget);
        expect(find.text('Pengeluaran'), findsOneWidget);

        // Periksa Komponen Nilai
        // Laba Bersih = (200.000 - 80.000) - 40.000 = 80.000
        expect(find.text('Laba Bersih Sederhana'), findsWidgets);
        expect(find.text('Rp 80.000'), findsWidgets);

        // Periksa Tombol Aksi Ekspor
        expect(find.text('Ekspor PDF'), findsOneWidget);
        expect(find.text('Ekspor Excel'), findsOneWidget);

        // Pindah ke Tab Penjualan
        await tester.tap(find.text('Penjualan'));
        await tester.pumpAndSettle();

        // Pindah ke Tab Pengeluaran
        await tester.tap(find.text('Pengeluaran'));
        await tester.pumpAndSettle();
      },
    );
  });
}
