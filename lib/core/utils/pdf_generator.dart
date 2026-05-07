import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tokoku/core/utils/formatters.dart';

class PdfGenerator {
  static Future<void> generateSalesReport({
    required String periodLabel,
    required Map<String, dynamic> reportData,
  }) async {
    final pdf = pw.Document();

    final totalRevenue = reportData['totalRevenue'] ?? 0.0;
    final totalTransactions = reportData['totalTransactions'] ?? 0;
    final topProducts = (reportData['topProducts'] as List? ?? []);

    // Header Font
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(periodLabel, fontBold),
          pw.SizedBox(height: 20),
          _buildSummary(totalRevenue, totalTransactions, font, fontBold),
          pw.SizedBox(height: 30),
          _buildTopProductsTitle(fontBold),
          pw.SizedBox(height: 10),
          _buildProductsTable(topProducts, font, fontBold),
          pw.Spacer(),
          _buildFooter(font),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Penjualan_${periodLabel.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildHeader(String periodLabel, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Redo Jaya Plastik',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 24,
                color: PdfColors.blue900,
              ),
            ),
            pw.Text(
              'Laporan Analisis Penjualan',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Periode:',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              periodLabel,
              style: pw.TextStyle(font: fontBold, fontSize: 12),
            ),
            pw.Text(
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummary(
    num revenue,
    int transactions,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Pendapatan',
            Formatters.currency(revenue),
            font,
            fontBold,
          ),
          pw.VerticalDivider(color: PdfColors.blue200, width: 1),
          _buildSummaryItem(
            'Total Transaksi',
            transactions.toString(),
            font,
            fontBold,
          ),
          pw.VerticalDivider(color: PdfColors.blue200, width: 1),
          _buildSummaryItem(
            'Rata-rata Transaksi',
            Formatters.currency(transactions > 0 ? revenue / transactions : 0),
            font,
            fontBold,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: PdfColors.blueGrey700,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 14,
            color: PdfColors.blue900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTopProductsTitle(pw.Font fontBold) {
    return pw.Text(
      'Produk Terlaris',
      style: pw.TextStyle(
        font: fontBold,
        fontSize: 16,
        color: PdfColors.grey900,
      ),
    );
  }

  static pw.Widget _buildProductsTable(
    List<dynamic> products,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final headers = ['No', 'Nama Produk', 'Jumlah', 'Total Pendapatan'];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: List.generate(products.length, (index) {
        final product = products[index];
        return [
          '${index + 1}',
          product['name'] ?? '-',
          '${product['count']} pcs',
          Formatters.currency(product['revenue'] ?? 0),
        ];
      }),
      headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellStyle: pw.TextStyle(font: font),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Text(
        'Laporan ini digenerate secara otomatis oleh sistem TOKOKU POS.',
        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }
}
