import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/line_item_model.dart';

class ReceiptService {
  static final _supabase = Supabase.instance.client;

  /// Map receipt data from model format to database format
  static Map<String, dynamic> _mapReceiptDataForDatabase(Map<String, dynamic> data) {
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
    if (mappedData.containsKey('status') && mappedData['status'] is ReceiptStatus) {
      final status = mappedData['status'] as ReceiptStatus;
      switch (status) {
        case ReceiptStatus.draft:
          mappedData['status'] = 'draft';
          break;
        case ReceiptStatus.active:
          mappedData['status'] = 'active';
          break;
        case ReceiptStatus.archived:
          mappedData['status'] = 'archived';
          break;
        case ReceiptStatus.deleted:
          mappedData['status'] = 'deleted';
          break;
      }
    }

    // Handle enum conversion for processing_status
    if (mappedData.containsKey('processing_status') && mappedData['processing_status'] is ProcessingStatus) {
      final processingStatus = mappedData['processing_status'] as ProcessingStatus;
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

    return mappedData;
  }

  /// Update a receipt with its line items
  static Future<ReceiptModel> updateReceiptWithLineItems({
    required String receiptId,
    required Map<String, dynamic> receiptData,
    required List<LineItemModel> lineItems,
  }) async {
    try {
      print('🔄 Updating receipt $receiptId with ${lineItems.length} line items');

      // Map receipt data to database format
      final mappedReceiptData = _mapReceiptDataForDatabase(receiptData);
      print('📝 Mapped receipt data: ${mappedReceiptData.keys.join(', ')}');

      // First update the receipt data
      print('📊 Updating receipt data...');
      await _supabase
          .from('receipts')
          .update({
            ...mappedReceiptData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', receiptId);
      print('✅ Receipt data updated successfully');

      // Update line items if provided
      if (lineItems.isNotEmpty) {
        print('🗑️ Deleting existing line items...');
        // Delete existing line items first
        await _supabase
            .from('line_items')
            .delete()
            .eq('receipt_id', receiptId);
        print('✅ Existing line items deleted');

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
        }).toList();

        if (formattedLineItems.isNotEmpty) {
          print('➕ Inserting ${formattedLineItems.length} line items...');
          await _supabase
              .from('line_items')
              .insert(formattedLineItems);
          print('✅ Line items inserted successfully');
        }
      } else {
        print('🗑️ Deleting all line items (empty array provided)...');
        // If empty array is explicitly passed, delete all line items
        await _supabase
            .from('line_items')
            .delete()
            .eq('receipt_id', receiptId);
        print('✅ All line items deleted');
      }

      // Fetch the updated receipt with line items
      print('🔍 Fetching updated receipt with line items...');
      final result = await getReceiptWithLineItems(receiptId);
      print('✅ Receipt update completed successfully');
      return result;
    } catch (error) {
      print('❌ Error updating receipt: $error');
      rethrow;
    }
  }

  /// Get a receipt with its line items
  static Future<ReceiptModel> getReceiptWithLineItems(String receiptId) async {
    try {
      print('🔍 Fetching receipt $receiptId with line items...');
      final response = await _supabase
          .from('receipts')
          .select('''
            *,
            line_items (*)
          ''')
          .eq('id', receiptId)
          .single();

      final receipt = ReceiptModel.fromJson(response);

      // Parse line items if they exist
      if (response['line_items'] != null) {
        final lineItemsData = response['line_items'] as List;
        final lineItems = lineItemsData
            .map((item) => LineItemModel.fromJson(item))
            .toList();

        print('✅ Receipt fetched successfully with ${lineItems.length} line items');
        return receipt.copyWith(lineItems: lineItems);
      }

      print('✅ Receipt fetched successfully with 0 line items');
      return receipt;
    } catch (error) {
      print('❌ Error fetching receipt with line items: $error');
      rethrow;
    }
  }

  /// Validate receipt data before saving
  static Map<String, String> validateReceiptData(Map<String, dynamic> data) {
    final errors = <String, String>{};

    if (data['merchant_name'] == null || data['merchant_name'].toString().trim().isEmpty) {
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
  static Map<String, double> calculateReceiptTotals(List<LineItemModel> lineItems) {
    double total = 0.0;

    for (final item in lineItems) {
      total += item.amount;
    }

    return {
      'subtotal': total,
      'tax': 0.0,
      'discount': 0.0,
      'total': total,
    };
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
      'Other'
    ];
  }
}
