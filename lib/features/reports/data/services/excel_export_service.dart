import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/report_summary_model.dart';

/// Layanan pembuatan file Excel spreadsheet laporan usaha USAHAKU (.xlsx).
class ExcelExportService {
  ExcelExportService._();

  static List<int> generateExcel(ReportSummaryModel report) {
    final excel = Excel.createExcel();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // 1. Sheet Ringkasan Laba Rugi
    final sheetSummary = excel['Laba Rugi'];
    excel.setDefaultSheet('Laba Rugi');

    sheetSummary.appendRow([
      TextCellValue('USAHAKU - Laporan Laba Rugi Sederhana'),
    ]);
    sheetSummary.appendRow([
      TextCellValue(
        'Periode: ${dateFormat.format(report.startDate)} s/d ${dateFormat.format(report.endDate)}',
      ),
    ]);
    sheetSummary.appendRow([TextCellValue('')]);

    sheetSummary.appendRow([
      TextCellValue('Komponen'),
      TextCellValue('Nominal (Rp)'),
    ]);
    sheetSummary.appendRow([
      TextCellValue('Omzet Penjualan'),
      IntCellValue(report.totalSales),
    ]);
    sheetSummary.appendRow([
      TextCellValue('Harga Pokok Penjualan (HPP)'),
      IntCellValue(report.totalHpp),
    ]);
    sheetSummary.appendRow([
      TextCellValue('Laba Kotor (Omzet - HPP)'),
      IntCellValue(report.grossProfit),
    ]);
    sheetSummary.appendRow([
      TextCellValue('Beban Biaya Usaha'),
      IntCellValue(report.totalExpenses),
    ]);
    sheetSummary.appendRow([
      TextCellValue('Laba Bersih Sederhana'),
      IntCellValue(report.netProfit),
    ]);
    sheetSummary.appendRow([
      TextCellValue('Pemasukan Tambahan Non-Penjualan'),
      IntCellValue(report.totalOtherIncome),
    ]);
    sheetSummary.appendRow([
      TextCellValue('Arus Kas Bersih'),
      IntCellValue(report.netCashFlow),
    ]);

    // 2. Sheet Rincian Penjualan
    final sheetSales = excel['Penjualan'];
    sheetSales.appendRow([
      TextCellValue('USAHAKU - Rincian Transaksi Penjualan'),
    ]);
    sheetSales.appendRow([TextCellValue('')]);
    sheetSales.appendRow([
      TextCellValue('No. Nota'),
      TextCellValue('Tanggal'),
      TextCellValue('Metode Bayar'),
      TextCellValue('Subtotal'),
      TextCellValue('Diskon'),
      TextCellValue('Total'),
      TextCellValue('Item'),
    ]);

    for (final s in report.sales) {
      final itemsSummary = s.items
          .map((i) => '${i.productName} (${i.quantity}x)')
          .join(', ');
      sheetSales.appendRow([
        TextCellValue(s.invoiceNumber),
        TextCellValue(dateFormat.format(s.saleDate)),
        TextCellValue(s.paymentMethod),
        IntCellValue(s.subtotal),
        IntCellValue(s.discount),
        IntCellValue(s.total),
        TextCellValue(itemsSummary),
      ]);
    }

    // 3. Sheet Rincian Pengeluaran
    final sheetExpenses = excel['Pengeluaran'];
    sheetExpenses.appendRow([
      TextCellValue('USAHAKU - Rincian Pengeluaran Usaha'),
    ]);
    sheetExpenses.appendRow([TextCellValue('')]);
    sheetExpenses.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Keterangan'),
      TextCellValue('Kategori'),
      TextCellValue('Nominal'),
      TextCellValue('Catatan'),
    ]);

    for (final e in report.expenses) {
      sheetExpenses.appendRow([
        TextCellValue(dateFormat.format(e.expenseDate)),
        TextCellValue(e.title),
        TextCellValue(e.category),
        IntCellValue(e.amount),
        TextCellValue(e.note ?? ''),
      ]);
    }

    // Hapus sheet default bawaan excel jika ada
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    return bytes ?? [];
  }
}
