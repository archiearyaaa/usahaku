import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/report_summary_model.dart';

/// Layanan pembuatan dokumen PDF laporan keuangan dan penjualan USAHAKU.
class PdfExportService {
  PdfExportService._();

  static Future<Uint8List> generatePdf(ReportSummaryModel report) async {
    final pdf = pw.Document();

    final periodStr =
        '${DateFormatter.formatDate(report.startDate)} - ${DateFormatter.formatDate(report.endDate)}';
    final printDateStr = DateFormatter.formatDateTime(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'USAHAKU',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#FF2800'),
                  ),
                ),
                pw.Text(
                  'Laporan Usaha Kuliner',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Periode: $periodStr',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Dicetak pada: $printDateStr',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#FF2800')),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'USAHAKU • by Archie Arya Manggala',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          // 1. Ringkasan Laba / Rugi Sederhana
          pw.Text(
            '1. Ringkasan Laba / Rugi Sederhana',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              _buildTableRow(
                'Omzet Penjualan (${report.totalSalesTransactions} transaksi)',
                CurrencyFormatter.format(report.totalSales),
              ),
              _buildTableRow(
                'Harga Pokok Penjualan (HPP)',
                '- ${CurrencyFormatter.format(report.totalHpp)}',
              ),
              _buildTableRow(
                'Laba Kotor (Omzet - HPP)',
                CurrencyFormatter.format(report.grossProfit),
                isBold: true,
              ),
              _buildTableRow(
                'Total Beban & Biaya Usaha',
                '- ${CurrencyFormatter.format(report.totalExpenses)}',
              ),
              _buildTableRow(
                'Laba Bersih Sederhana',
                CurrencyFormatter.format(report.netProfit),
                isBold: true,
                color: report.isProfitable
                    ? PdfColors.green800
                    : PdfColors.red800,
              ),
            ],
          ),

          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Text(
              'Catatan: Laba sederhana dihitung dari omzet penjualan dikurangi estimasi HPP barang terjual dan biaya operasional yang dicatat. Biaya pembelian bahan tidak dihitung ganda jika HPP per produk telah ditetapkan.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),

          pw.SizedBox(height: 20),

          // 2. Rekap Transaksi Penjualan
          pw.Text(
            '2. Rekap Transaksi Penjualan (${report.sales.length} transaksi)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          if (report.sales.isEmpty)
            pw.Text(
              'Tidak ada transaksi penjualan pada periode ini.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('No. Nota'),
                    _cellHeader('Tanggal & Waktu'),
                    _cellHeader('Metode'),
                    _cellHeader('Total Belanja', alignRight: true),
                  ],
                ),
                ...report.sales.map(
                  (s) => pw.TableRow(
                    children: [
                      _cell(s.invoiceNumber),
                      _cell(DateFormatter.formatDateTime(s.saleDate)),
                      _cell(s.paymentMethod),
                      _cell(
                        CurrencyFormatter.format(s.total),
                        alignRight: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

          pw.SizedBox(height: 20),

          // 3. Rekap Pengeluaran Usaha
          pw.Text(
            '3. Rekap Pengeluaran Usaha (${report.expenses.length} item)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          if (report.expenses.isEmpty)
            pw.Text(
              'Tidak ada pengeluaran dicatat pada periode ini.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('Tanggal'),
                    _cellHeader('Keterangan'),
                    _cellHeader('Kategori'),
                    _cellHeader('Nominal', alignRight: true),
                  ],
                ),
                ...report.expenses.map(
                  (e) => pw.TableRow(
                    children: [
                      _cell(DateFormatter.formatDate(e.expenseDate)),
                      _cell(e.title),
                      _cell(e.category),
                      _cell(
                        CurrencyFormatter.format(e.amount),
                        alignRight: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return await pdf.save();
  }

  static pw.TableRow _buildTableRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _cellHeader(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _cell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }
}
