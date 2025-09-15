import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../shared/models/receipt_model.dart';
import '../../shared/models/claim_model.dart';
import 'app_logger.dart';

/// iOS-specific sharing service with native sharing capabilities
class IOSSharingService {
  static const String _tag = 'IOSSharingService';
  static final _logger = AppLogger.getLogger(_tag);

  /// Share a single receipt with iOS native sharing
  static Future<void> shareReceipt(
    BuildContext context,
    ReceiptModel receipt, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      _logger.i('Sharing receipt: ${receipt.id}');

      final shareText = _buildReceiptShareText(receipt);
      final files = <XFile>[];

      // Add receipt image if available
      if (receipt.imageUrl != null) {
        try {
          final imageFile = await _downloadReceiptImage(receipt);
          if (imageFile != null) {
            files.add(imageFile);
          }
        } catch (e) {
          _logger.w('Failed to download receipt image: $e');
        }
      }

      // Share with iOS native sharing
      if (Platform.isIOS && sharePositionOrigin != null) {
        await Share.shareXFiles(
          files,
          text: shareText,
          subject: 'Receipt from ${receipt.merchantName ?? 'Unknown Merchant'}',
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        await Share.shareXFiles(
          files,
          text: shareText,
          subject: 'Receipt from ${receipt.merchantName ?? 'Unknown Merchant'}',
        );
      }

      _logger.i('Receipt shared successfully');
    } catch (e) {
      _logger.e('Failed to share receipt: $e');
      rethrow;
    }
  }

  /// Share multiple receipts as a PDF report
  static Future<void> shareReceiptsAsPDF(
    BuildContext context,
    List<ReceiptModel> receipts, {
    String? title,
    Rect? sharePositionOrigin,
  }) async {
    try {
      _logger.i('Sharing ${receipts.length} receipts as PDF');

      final pdfFile = await _generateReceiptsPDF(receipts, title: title);
      final shareText = _buildMultipleReceiptsShareText(receipts, title: title);

      if (Platform.isIOS && sharePositionOrigin != null) {
        await Share.shareXFiles(
          [pdfFile],
          text: shareText,
          subject: title ?? 'Expense Report',
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        await Share.shareXFiles(
          [pdfFile],
          text: shareText,
          subject: title ?? 'Expense Report',
        );
      }

      _logger.i('Receipts PDF shared successfully');
    } catch (e) {
      _logger.e('Failed to share receipts PDF: $e');
      rethrow;
    }
  }

  /// Share a claim with all associated receipts
  static Future<void> shareClaim(
    BuildContext context,
    ClaimModel claim,
    List<ReceiptModel> receipts, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      _logger.i('Sharing claim: ${claim.id}');

      final pdfFile = await _generateClaimPDF(claim, receipts);
      final shareText = _buildClaimShareText(claim);

      if (Platform.isIOS && sharePositionOrigin != null) {
        await Share.shareXFiles(
          [pdfFile],
          text: shareText,
          subject: 'Expense Claim - ${claim.title}',
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        await Share.shareXFiles(
          [pdfFile],
          text: shareText,
          subject: 'Expense Claim - ${claim.title}',
        );
      }

      _logger.i('Claim shared successfully');
    } catch (e) {
      _logger.e('Failed to share claim: $e');
      rethrow;
    }
  }

  /// Share app download link
  static Future<void> shareApp(
    BuildContext context, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      const appStoreUrl = 'https://apps.apple.com/app/mataresit/id123456789'; // Replace with actual App Store URL
      const shareText = 'Check out Mataresit - the smart receipt manager that makes expense tracking effortless!\n\n$appStoreUrl';

      if (Platform.isIOS && sharePositionOrigin != null) {
        await Share.share(
          shareText,
          subject: 'Mataresit - Smart Receipt Manager',
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        await Share.share(
          shareText,
          subject: 'Mataresit - Smart Receipt Manager',
        );
      }

      _logger.i('App shared successfully');
    } catch (e) {
      _logger.e('Failed to share app: $e');
      rethrow;
    }
  }

  /// Share receipt data as CSV
  static Future<void> shareReceiptsAsCSV(
    BuildContext context,
    List<ReceiptModel> receipts, {
    String? title,
    Rect? sharePositionOrigin,
  }) async {
    try {
      _logger.i('Sharing ${receipts.length} receipts as CSV');

      final csvFile = await _generateReceiptsCSV(receipts, title: title);
      final shareText = 'Expense data export from Mataresit';

      if (Platform.isIOS && sharePositionOrigin != null) {
        await Share.shareXFiles(
          [csvFile],
          text: shareText,
          subject: title ?? 'Expense Data Export',
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        await Share.shareXFiles(
          [csvFile],
          text: shareText,
          subject: title ?? 'Expense Data Export',
        );
      }

      _logger.i('Receipts CSV shared successfully');
    } catch (e) {
      _logger.e('Failed to share receipts CSV: $e');
      rethrow;
    }
  }

  /// Build share text for a single receipt
  static String _buildReceiptShareText(ReceiptModel receipt) {
    final buffer = StringBuffer();
    buffer.writeln('Receipt from ${receipt.merchantName ?? 'Unknown Merchant'}');
    buffer.writeln('Date: ${receipt.transactionDate?.toString().split(' ')[0] ?? 'Unknown Date'}');
    buffer.writeln('Amount: ${receipt.currency ?? 'USD'} ${receipt.totalAmount?.toStringAsFixed(2) ?? '0.00'}');

    if (receipt.category?.isNotEmpty == true) {
      buffer.writeln('Category: ${receipt.category}');
    }

    buffer.writeln('\nShared from Mataresit - Smart Receipt Manager');
    return buffer.toString();
  }

  /// Build share text for multiple receipts
  static String _buildMultipleReceiptsShareText(List<ReceiptModel> receipts, {String? title}) {
    final buffer = StringBuffer();
    buffer.writeln(title ?? 'Expense Report');
    buffer.writeln('${receipts.length} receipts');

    final total = receipts.fold<double>(0, (sum, receipt) => sum + (receipt.totalAmount ?? 0.0));
    buffer.writeln('Total: \$${total.toStringAsFixed(2)}');

    buffer.writeln('\nGenerated by Mataresit - Smart Receipt Manager');
    return buffer.toString();
  }

  /// Build share text for a claim
  static String _buildClaimShareText(ClaimModel claim) {
    final buffer = StringBuffer();
    buffer.writeln('Expense Claim: ${claim.title}');
    buffer.writeln('Status: ${claim.status.toString().split('.').last}');
    buffer.writeln('Amount: \$${claim.amount.toStringAsFixed(2)}');

    if (claim.description?.isNotEmpty == true) {
      buffer.writeln('Description: ${claim.description}');
    }

    buffer.writeln('\nGenerated by Mataresit - Smart Receipt Manager');
    return buffer.toString();
  }

  /// Download receipt image for sharing
  static Future<XFile?> _downloadReceiptImage(ReceiptModel receipt) async {
    try {
      if (receipt.imageUrl == null) return null;

      // In a real implementation, you would download the image from the URL
      // For now, we'll return null as a placeholder
      return null;
    } catch (e) {
      _logger.e('Failed to download receipt image: $e');
      return null;
    }
  }

  /// Generate PDF from receipts
  static Future<XFile> _generateReceiptsPDF(List<ReceiptModel> receipts, {String? title}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(title ?? 'Expense Report'),
            ),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Merchant', 'Amount', 'Category'],
              data: receipts.map((receipt) => [
                receipt.transactionDate?.toString().split(' ')[0] ?? 'Unknown Date',
                receipt.merchantName ?? 'Unknown Merchant',
                '${receipt.currency ?? 'USD'} ${(receipt.totalAmount ?? 0.0).toStringAsFixed(2)}',
                receipt.category ?? 'Uncategorized',
              ]).toList(),
            ),
            pw.Spacer(),
            pw.Text(
              'Total: \$${receipts.fold<double>(0, (sum, r) => sum + (r.totalAmount ?? 0.0)).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipts_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return XFile(file.path);
  }

  /// Generate PDF from claim
  static Future<XFile> _generateClaimPDF(ClaimModel claim, List<ReceiptModel> receipts) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Expense Claim: ${claim.title}'),
            ),
            pw.Text('Status: ${claim.status.toString().split('.').last}'),
            pw.Text('Description: ${claim.description ?? 'No description'}'),
            pw.SizedBox(height: 20),
            pw.Text('Receipts:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Merchant', 'Amount', 'Category'],
              data: receipts.map((receipt) => [
                receipt.transactionDate?.toString().split(' ')[0] ?? 'Unknown Date',
                receipt.merchantName ?? 'Unknown Merchant',
                '${receipt.currency ?? 'USD'} ${(receipt.totalAmount ?? 0.0).toStringAsFixed(2)}',
                receipt.category ?? 'Uncategorized',
              ]).toList(),
            ),
            pw.Spacer(),
            pw.Text(
              'Total: \$${claim.amount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/claim_${claim.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return XFile(file.path);
  }

  /// Generate CSV from receipts
  static Future<XFile> _generateReceiptsCSV(List<ReceiptModel> receipts, {String? title}) async {
    final buffer = StringBuffer();

    // CSV header
    buffer.writeln('Date,Merchant,Amount,Currency,Category,Payment Method');

    // CSV data
    for (final receipt in receipts) {
      buffer.writeln([
        receipt.transactionDate?.toString().split(' ')[0] ?? 'Unknown Date',
        '"${receipt.merchantName ?? 'Unknown Merchant'}"',
        (receipt.totalAmount ?? 0.0).toStringAsFixed(2),
        receipt.currency ?? 'USD',
        '"${receipt.category ?? 'Uncategorized'}"',
        '"${receipt.paymentMethod ?? 'Unknown'}"',
      ].join(','));
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipts_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());
    
    return XFile(file.path);
  }

  // Additional methods for test compatibility

  /// Share text content
  static Future<void> shareText(String text, {String? subject}) async {
    try {
      await Share.share(
        text,
        subject: subject,
      );
      _logger.i('Text shared successfully');
    } catch (e) {
      _logger.e('Failed to share text: $e');
      rethrow;
    }
  }

  /// Share a file
  static Future<void> shareFile(String filePath, {String? text, String? subject}) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        text: text,
        subject: subject,
      );
      _logger.i('File shared successfully: $filePath');
    } catch (e) {
      _logger.e('Failed to share file: $e');
      rethrow;
    }
  }
}
