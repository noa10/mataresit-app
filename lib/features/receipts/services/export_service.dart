import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../core/services/app_logger.dart';

/// Service for exporting receipts to various formats
class ExportService {
  static const String _appName = 'Mataresit';

  /// Export receipts to PDF format
  static Future<void> exportToPDF(List<ReceiptModel> receipts) async {
    if (receipts.isEmpty) {
      throw Exception('No receipts to export');
    }

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormatter = DateFormat('MMMM d, yyyy HH:mm:ss');
      final currencyFormatter = NumberFormat.currency(symbol: '\$');

      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Receipt Export Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Export Date: ${dateFormatter.format(now)}'),
                      pw.Text('Total Receipts: ${receipts.length}'),
                    ],
                  ),
                ),

                // Summary
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Summary',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildSummarySection(receipts, currencyFormatter),
                    ],
                  ),
                ),

                // Receipts table
                pw.Expanded(
                  child: _buildReceiptsTable(receipts, currencyFormatter),
                ),
              ],
            );
          },
        ),
      );

      // Save and share the PDF
      await _savePDF(pdf, 'receipts_export_${_getTimestamp()}.pdf');
    } catch (e) {
      AppLogger.error('PDF export failed: $e');
      throw Exception('Failed to export PDF: $e');
    }
  }

  /// Export receipts to Excel format
  static Future<void> exportToExcel(List<ReceiptModel> receipts) async {
    if (receipts.isEmpty) {
      throw Exception('No receipts to export');
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Receipts'];

      // Add headers
      final headers = [
        'ID',
        'Date',
        'Merchant',
        'Total',
        'Currency',
        'Tax',
        'Payment Method',
        'Status',
        'Category',
        'Processing Status',
        'Created At',
        'Updated At',
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headers[i],
        );
      }

      // Add receipt data
      for (int i = 0; i < receipts.length; i++) {
        final receipt = receipts[i];
        final row = i + 1;

        final rowData = [
          receipt.id,
          _formatDate(receipt.transactionDate ?? receipt.createdAt),
          receipt.merchantName ?? 'Unknown Merchant',
          receipt.totalAmount?.toString() ?? '0.00',
          receipt.currency ?? 'USD',
          receipt.taxAmount?.toString() ?? '',
          receipt.paymentMethod ?? '',
          receipt.status.name,
          receipt.category ?? '',
          receipt.processingStatus.name,
          _formatDateTime(receipt.createdAt),
          _formatDateTime(receipt.updatedAt),
        ];

        for (int j = 0; j < rowData.length; j++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row))
              .value = TextCellValue(
            rowData[j],
          );
        }
      }

      // Create summary sheet
      final summarySheet = excel['Summary'];
      _addSummaryToExcel(summarySheet, receipts);

      // Save and share the Excel file
      final bytes = excel.encode();
      if (bytes != null) {
        await _saveFile(
          Uint8List.fromList(bytes),
          'receipts_export_${_getTimestamp()}.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      }
    } catch (e) {
      AppLogger.error('Excel export failed: $e');
      throw Exception('Failed to export Excel: $e');
    }
  }

  /// Export receipts to CSV format
  static Future<void> exportToCSV(List<ReceiptModel> receipts) async {
    if (receipts.isEmpty) {
      throw Exception('No receipts to export');
    }

    try {
      final headers = [
        'ID',
        'Date',
        'Merchant',
        'Total',
        'Currency',
        'Tax',
        'Payment Method',
        'Status',
        'Category',
        'Processing Status',
        'Created At',
        'Updated At',
      ];

      final rows = <List<String>>[headers];

      for (final receipt in receipts) {
        rows.add([
          receipt.id,
          _formatDate(receipt.transactionDate ?? receipt.createdAt),
          receipt.merchantName ?? 'Unknown Merchant',
          receipt.totalAmount?.toString() ?? '0.00',
          receipt.currency ?? 'USD',
          receipt.taxAmount?.toString() ?? '',
          receipt.paymentMethod ?? '',
          receipt.status.name,
          receipt.category ?? '',
          receipt.processingStatus.name,
          _formatDateTime(receipt.createdAt),
          _formatDateTime(receipt.updatedAt),
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(csvData.codeUnits);

      await _saveFile(
        bytes,
        'receipts_export_${_getTimestamp()}.csv',
        'text/csv',
      );
    } catch (e) {
      AppLogger.error('CSV export failed: $e');
      throw Exception('Failed to export CSV: $e');
    }
  }

  // Helper methods

  static pw.Widget _buildSummarySection(
    List<ReceiptModel> receipts,
    NumberFormat currencyFormatter,
  ) {
    final totalAmount = receipts
        .where((r) => r.totalAmount != null)
        .fold<double>(0.0, (sum, r) => sum + r.totalAmount!);

    final statusCounts = <String, int>{};
    final categoryCounts = <String, int>{};

    for (final receipt in receipts) {
      statusCounts[receipt.status.name] =
          (statusCounts[receipt.status.name] ?? 0) + 1;

      final category = receipt.category ?? 'Uncategorized';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Total Amount: ${currencyFormatter.format(totalAmount)}'),
        pw.SizedBox(height: 10),
        pw.Text('Status Breakdown:'),
        ...statusCounts.entries.map((e) => pw.Text('  ${e.key}: ${e.value}')),
        pw.SizedBox(height: 10),
        pw.Text('Category Breakdown:'),
        ...categoryCounts.entries
            .take(10)
            .map((e) => pw.Text('  ${e.key}: ${e.value}')),
      ],
    );
  }

  static pw.Widget _buildReceiptsTable(
    List<ReceiptModel> receipts,
    NumberFormat currencyFormatter,
  ) {
    return pw.TableHelper.fromTextArray(
      context: null,
      data: [
        ['Date', 'Merchant', 'Amount', 'Payment', 'Status', 'Category'],
        ...receipts.map(
          (receipt) => [
            _formatDate(receipt.transactionDate ?? receipt.createdAt),
            receipt.merchantName ?? 'Unknown',
            currencyFormatter.format(receipt.totalAmount ?? 0),
            receipt.paymentMethod ?? '',
            receipt.status.name,
            receipt.category ?? '',
          ],
        ),
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
        5: pw.Alignment.centerLeft,
      },
    );
  }

  static void _addSummaryToExcel(Sheet sheet, List<ReceiptModel> receipts) {
    // Add summary data to Excel sheet
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('Export Summary');

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('Total Receipts');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value =
        IntCellValue(receipts.length);

    final totalAmount = receipts
        .where((r) => r.totalAmount != null)
        .fold<double>(0.0, (sum, r) => sum + r.totalAmount!);

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value =
        TextCellValue('Total Amount');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value =
        DoubleCellValue(totalAmount);
  }

  static Future<void> _savePDF(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    await _saveFile(bytes, filename, 'application/pdf');
  }

  static Future<void> _saveFile(
    Uint8List bytes,
    String filename,
    String mimeType,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);

      // Share the file
      await Share.shareXFiles([
        XFile(file.path, mimeType: mimeType),
      ], text: 'Receipt export from $_appName');

      AppLogger.info('✅ File exported and shared: $filename');
    } catch (e) {
      AppLogger.error('Failed to save/share file: $e');
      throw Exception('Failed to save file: $e');
    }
  }

  static String _getTimestamp() {
    return DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
  }

  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String _formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }
}
