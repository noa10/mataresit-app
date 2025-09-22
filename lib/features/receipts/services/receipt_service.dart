import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/line_item_model.dart';
import 'embedding_service.dart';

class ReceiptService {
  static final _supabase = Supabase.instance.client;
  static final _logger = Logger();

  /// Map receipt data from model format to database format
  static Map<String, dynamic> _mapReceiptDataForDatabase(
    Map<String, dynamic> data,
  ) {
    final mappedData = Map<String, dynamic>.from(data);

    // Map category to predicted_category
    if (mappedData.containsKey('category')) {
      mappedData['predicted_category'] = mappedData.remove('category');
    }

    // Map other fields that might have different names
    if (mappedData.containsKey('merchantName')) {
      mappedData['merchant'] = mappedData.remove('merchantName');
    }

    // Handle underscore format field names from Flutter
    if (mappedData.containsKey('merchant_name')) {
      mappedData['merchant'] = mappedData.remove('merchant_name');
    }

    if (mappedData.containsKey('transactionDate')) {
      mappedData['date'] = mappedData.remove('transactionDate');
    }

    // Handle underscore format field names from Flutter
    if (mappedData.containsKey('transaction_date')) {
      mappedData['date'] = mappedData.remove('transaction_date');
    }

    if (mappedData.containsKey('totalAmount')) {
      mappedData['total'] = mappedData.remove('totalAmount');
    }

    // Handle underscore format field names from Flutter
    if (mappedData.containsKey('total_amount')) {
      mappedData['total'] = mappedData.remove('total_amount');
    }

    if (mappedData.containsKey('taxAmount')) {
      mappedData['tax'] = mappedData.remove('taxAmount');
    }

    // Handle underscore format field names from Flutter
    if (mappedData.containsKey('tax_amount')) {
      mappedData['tax'] = mappedData.remove('tax_amount');
    }

    if (mappedData.containsKey('paymentMethod')) {
      mappedData['payment_method'] = mappedData.remove('paymentMethod');
    }

    // payment_method is already in the correct format, no need to map

    // Handle custom_category_id - it's already in the correct format for the database
    // No mapping needed for custom_category_id

    // Handle enum conversion for status
    if (mappedData.containsKey('status') &&
        mappedData['status'] is ReceiptStatus) {
      final status = mappedData['status'] as ReceiptStatus;
      switch (status) {
        case ReceiptStatus.unreviewed:
          mappedData['status'] = 'unreviewed';
          break;
        case ReceiptStatus.reviewed:
          mappedData['status'] = 'reviewed';
          break;
      }
    }

    // Handle enum conversion for processing_status
    if (mappedData.containsKey('processing_status') &&
        mappedData['processing_status'] is ProcessingStatus) {
      final processingStatus =
          mappedData['processing_status'] as ProcessingStatus;
      switch (processingStatus) {
        case ProcessingStatus.pending:
          mappedData['processing_status'] = 'pending';
          break;
        case ProcessingStatus.processing:
          mappedData['processing_status'] = 'processing';
          break;
        case ProcessingStatus.completed:
          mappedData['processing_status'] = 'completed';
          break;
        case ProcessingStatus.failed:
          mappedData['processing_status'] = 'failed';
          break;
        case ProcessingStatus.manualReview:
          mappedData['processing_status'] = 'manual_review';
          break;
      }
    }

    // Handle string processing_status values (cross-platform compatibility)
    if (mappedData.containsKey('processing_status') &&
        mappedData['processing_status'] is String) {
      final processingStatusStr = mappedData['processing_status'] as String;
      // Map React app's 'complete' to Flutter's 'completed'
      if (processingStatusStr.toLowerCase() == 'complete') {
        mappedData['processing_status'] = 'completed';
        _logger.d(
          'Mapped processing_status from "complete" to "completed" for database compatibility',
        );
      }
      // Ensure only valid values are used
      final validStatuses = [
        'pending',
        'processing',
        'completed',
        'failed',
        'manual_review',
      ];
      if (!validStatuses.contains(mappedData['processing_status'])) {
        _logger.w(
          'Invalid processing_status value: ${mappedData['processing_status']}, defaulting to completed',
        );
        mappedData['processing_status'] = 'completed';
      }
    }

    return mappedData;
  }

  /// Update a receipt with its line items
  static Future<ReceiptModel> updateReceiptWithLineItems({
    required String receiptId,
    required Map<String, dynamic> receiptData,
    required List<LineItemModel> lineItems,
  }) async {
    try {
      _logger.i(
        '🔄 Updating receipt $receiptId with ${lineItems.length} line items',
      );

      // Map receipt data to database format
      final mappedReceiptData = _mapReceiptDataForDatabase(receiptData);
      _logger.d('📝 Mapped receipt data: ${mappedReceiptData.keys.join(', ')}');

      // First update the receipt data
      _logger.d('📊 Updating receipt data...');
      await _supabase
          .from('receipts')
          .update({
            ...mappedReceiptData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', receiptId);
      _logger.i('✅ Receipt data updated successfully');

      // Update line items if provided
      if (lineItems.isNotEmpty) {
        _logger.d('🗑️ Deleting existing line items...');
        // Delete existing line items first
        await _supabase.from('line_items').delete().eq('receipt_id', receiptId);
        _logger.d('✅ Existing line items deleted');

        // Filter out items with empty descriptions and format for insertion
        final formattedLineItems = lineItems
            .where((item) => item.description.trim().isNotEmpty)
            .map((item) {
              final data = <String, dynamic>{
                'description': item.description.trim(),
                'amount': item.amount,
                'receipt_id': receiptId,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              };

              // Don't include temp IDs
              if (!item.id.startsWith('temp-')) {
                data['id'] = item.id;
              }

              return data;
            })
            .toList();

        if (formattedLineItems.isNotEmpty) {
          _logger.d('➕ Inserting ${formattedLineItems.length} line items...');
          await _supabase.from('line_items').insert(formattedLineItems);
          _logger.i('✅ Line items inserted successfully');
        }
      } else {
        _logger.d('🗑️ Deleting all line items (empty array provided)...');
        // If empty array is explicitly passed, delete all line items
        await _supabase.from('line_items').delete().eq('receipt_id', receiptId);
        _logger.d('✅ All line items deleted');
      }

      // Fetch the updated receipt with line items
      _logger.d('🔍 Fetching updated receipt with line items...');
      final result = await getReceiptWithLineItems(receiptId);

      if (result == null) {
        throw Exception('Receipt $receiptId not found after update');
      }

      _logger.i('✅ Receipt update completed successfully');

      // Trigger embedding synchronization to update search index
      _logger.d(
        '🔄 Triggering embedding synchronization for updated receipt...',
      );
      EmbeddingService.syncEmbeddingsAfterReceiptUpdate(receiptId).catchError((
        error,
      ) {
        _logger.w(
          '⚠️ Embedding synchronization failed but receipt update succeeded: $error',
        );
      });

      return result;
    } catch (error) {
      _logger.e('❌ Error updating receipt: $error');

      // Handle specific database constraint violations
      final errorMessage = error.toString().toLowerCase();
      if (errorMessage.contains('processing_status') &&
          errorMessage.contains('not one of the supported values')) {
        throw Exception(
          'Invalid processing status value. Please try again or contact support if the issue persists.',
        );
      } else if (errorMessage.contains('constraint') ||
          errorMessage.contains('check')) {
        throw Exception(
          'Data validation failed. Please check your input values and try again.',
        );
      }

      rethrow;
    }
  }

  /// Get a receipt with its line items
  static Future<ReceiptModel?> getReceiptWithLineItems(String receiptId) async {
    try {
      _logger.d('🔍 Fetching receipt $receiptId with line items...');

      // Fetch the receipt with line items using maybeSingle to handle missing receipts
      final response = await _supabase
          .from('receipts')
          .select('''
            *,
            line_items (*)
          ''')
          .eq('id', receiptId)
          .maybeSingle();

      if (response == null) {
        _logger.w('⚠️ Receipt $receiptId not found in database');
        return null;
      }

      // Note: 'unreviewed' is a valid status in ReceiptStatus enum, no conversion needed

      final receipt = ReceiptModel.fromJson(response);

      // Parse line items if they exist
      if (response['line_items'] != null) {
        final lineItemsData = response['line_items'] as List;
        final lineItems = lineItemsData
            .map((item) => LineItemModel.fromJson(item))
            .toList();

        _logger.i(
          '✅ Receipt fetched successfully with ${lineItems.length} line items',
        );
        return receipt.copyWith(lineItems: lineItems);
      }

      _logger.i('✅ Receipt fetched successfully with 0 line items');
      return receipt;
    } catch (error) {
      _logger.e('❌ Error fetching receipt with line items: $error');

      // Handle specific database constraint violations
      final errorMessage = error.toString().toLowerCase();
      if (errorMessage.contains('processing_status') &&
          errorMessage.contains('not one of the supported values')) {
        throw Exception(
          'Receipt data contains invalid processing status. This may be due to cross-platform compatibility issues.',
        );
      } else if (errorMessage.contains('invalid argument')) {
        throw Exception(
          'Invalid data format detected. Please try refreshing the receipt.',
        );
      }

      rethrow;
    }
  }

  /// Get multiple receipts by their IDs with line items
  static Future<List<ReceiptModel>> getReceiptsByIds(
    List<String> receiptIds,
  ) async {
    if (receiptIds.isEmpty) {
      return [];
    }

    try {
      _logger.d('🔍 Fetching ${receiptIds.length} receipts with line items...');
      final response = await _supabase
          .from('receipts')
          .select('''
            *,
            line_items (*)
          ''')
          .inFilter('id', receiptIds);

      final receipts = <ReceiptModel>[];

      for (final receiptData in response) {
        try {
          // Note: 'unreviewed' is a valid status in ReceiptStatus enum, no conversion needed
          final receipt = ReceiptModel.fromJson(receiptData);

          // Parse line items if they exist
          if (receiptData['line_items'] != null) {
            final lineItemsData = receiptData['line_items'] as List;
            final lineItems = lineItemsData
                .map((item) => LineItemModel.fromJson(item))
                .toList();

            receipts.add(receipt.copyWith(lineItems: lineItems));
          } else {
            receipts.add(receipt);
          }
        } catch (error) {
          _logger.e('❌ Error parsing receipt ${receiptData['id']}: $error');
          // Skip this receipt and continue with others
          continue;
        }
      }

      _logger.i('✅ Fetched ${receipts.length} receipts successfully');
      return receipts;
    } catch (error) {
      _logger.e('❌ Error fetching receipts by IDs: $error');
      rethrow;
    }
  }

  /// Validate receipt data before saving
  static Map<String, String> validateReceiptData(Map<String, dynamic> data) {
    final errors = <String, String>{};

    if (data['merchant_name'] == null ||
        data['merchant_name'].toString().trim().isEmpty) {
      errors['merchant_name'] = 'Merchant name is required';
    }

    if (data['transaction_date'] == null) {
      errors['transaction_date'] = 'Transaction date is required';
    }

    if (data['total_amount'] == null || data['total_amount'] <= 0) {
      errors['total_amount'] = 'Total amount must be greater than 0';
    }

    return errors;
  }

  /// Validate line item data
  static Map<String, String> validateLineItem(LineItemModel lineItem) {
    final errors = <String, String>{};

    if (lineItem.description.trim().isEmpty) {
      errors['description'] = 'Description is required';
    }

    if (lineItem.amount <= 0) {
      errors['amount'] = 'Amount must be greater than 0';
    }

    return errors;
  }

  /// Create a new line item with default values
  static LineItemModel createNewLineItem(String receiptId) {
    return LineItemModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      receiptId: receiptId,
      description: 'New item',
      amount: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Calculate receipt totals from line items
  static Map<String, double> calculateReceiptTotals(
    List<LineItemModel> lineItems,
  ) {
    double total = 0.0;

    for (final item in lineItems) {
      total += item.amount;
    }

    return {'subtotal': total, 'tax': 0.0, 'discount': 0.0, 'total': total};
  }

  /// Format currency for display
  static String formatCurrency(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Parse currency string to double
  static double parseCurrency(String currencyString) {
    // Remove currency symbols and parse
    final cleanString = currencyString.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleanString) ?? 0.0;
  }

  /// Validate and format date
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Try different date formats
      final formats = [
        RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
        RegExp(r'(\d{2})/(\d{2})/(\d{4})'),
        RegExp(r'(\d{2})-(\d{2})-(\d{4})'),
      ];

      for (final format in formats) {
        final match = format.firstMatch(dateString);
        if (match != null) {
          try {
            if (dateString.contains('/')) {
              // MM/DD/YYYY format
              final day = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              final year = int.parse(match.group(3)!);
              return DateTime(year, month, day);
            } else {
              // YYYY-MM-DD or DD-MM-YYYY format
              final part1 = int.parse(match.group(1)!);
              final part2 = int.parse(match.group(2)!);
              final part3 = int.parse(match.group(3)!);

              if (part1 > 1000) {
                // YYYY-MM-DD
                return DateTime(part1, part2, part3);
              } else {
                // DD-MM-YYYY
                return DateTime(part3, part2, part1);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }

      return null;
    }
  }

  /// Get available currencies
  static List<String> getAvailableCurrencies() {
    return ['MYR', 'USD', 'EUR', 'GBP', 'SGD', 'JPY', 'AUD', 'CAD'];
  }

  /// Get available payment methods
  static List<String> getAvailablePaymentMethods() {
    return [
      'Cash',
      'Credit Card',
      'Debit Card',
      'Bank Transfer',
      'Digital Wallet',
      'Check',
      'Other',
    ];
  }
}
