import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:usahaku/features/finance/data/models/expense_model.dart';
import 'package:usahaku/features/reports/data/models/report_summary_model.dart';
import 'package:usahaku/features/reports/data/services/excel_export_service.dart';
import 'package:usahaku/features/reports/data/services/pdf_export_service.dart';
import 'package:usahaku/features/sales/data/models/sale_item_model.dart';
import 'package:usahaku/features/sales/data/models/sale_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Export Services Integration Tests (PDF & Excel)', () {
    final now = DateTime.now();
    final testReport = ReportSummaryModel(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
      totalSales: 150000,
      totalSalesTransactions: 2,
      totalHpp: 50000,
      totalExpenses: 30000,
      totalOtherIncome: 20000,
      sales: [
        SaleModel(
          id: 1,
          invoiceNumber: 'INV-20261120-0001',
          saleDate: now,
          subtotal: 150000,
          total: 150000,
          paymentMethod: 'Tunai',
          amountPaid: 150000,
          createdAt: now,
          items: const [
            SaleItemModel(
              productName: 'Ayam Bakar',
              quantity: 5,
              unitPrice: 30000,
              unitCost: 10000,
              lineTotal: 150000,
            ),
          ],
        ),
      ],
      expenses: [
        ExpenseModel(
          id: 1,
          title: 'Arang dan Bumbu',
          category: 'Bahan Baku',
          amount: 30000,
          expenseDate: now,
          createdAt: now,
        ),
      ],
    );

    test(
      'PdfExportService menghasilkan berkas PDF valid dengan header %PDF',
      () async {
        final pdfBytes = await PdfExportService.generatePdf(testReport);

        expect(pdfBytes, isNotEmpty);
        expect(pdfBytes.length, greaterThan(1000));

        // Verifikasi Magic Bytes PDF: %PDF
        final header = ascii.decode(pdfBytes.sublist(0, 4));
        expect(header, equals('%PDF'));
      },
    );

    test(
      'ExcelExportService menghasilkan berkas spreadsheet XLSX valid dengan header PK',
      () {
        final excelBytes = ExcelExportService.generateExcel(testReport);

        expect(excelBytes, isNotEmpty);
        expect(excelBytes.length, greaterThan(500));

        // Berkas .xlsx adalah berkas ZIP (Open Packaging Convention) dengan magic header: PK (0x50, 0x4B)
        expect(excelBytes[0], equals(0x50)); // 'P'
        expect(excelBytes[1], equals(0x4B)); // 'K'
      },
    );
  });
}
