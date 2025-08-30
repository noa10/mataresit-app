import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/line_item_model.dart';

class ReceiptService {
  static final _supabase = Supabase.instance.client;

  /// Update a receipt with its line items
  static Future<ReceiptModel> updateReceiptWithLineItems({
    required String receiptId,
    required Map<String, dynamic> receiptData,
    required List<LineItemModel> lineItems,
  }) async {
    try {
      // Start a transaction-like operation
      await _supabase.rpc('begin_transaction');

      // Update the receipt
      await _supabase
          .from('receipts')
          .update({
            ...receiptData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', receiptId)
          .select()
          .single();

      // Delete existing line items
      await _supabase
          .from('line_items')
          .delete()
          .eq('receipt_id', receiptId);

      // Insert new line items
      if (lineItems.isNotEmpty) {
        final lineItemsData = lineItems.map((item) {
          final data = item.toJson();
          data['receipt_id'] = receiptId;
          data['created_at'] = DateTime.now().toIso8601String();
          data['updated_at'] = DateTime.now().toIso8601String();
          
          // Remove temp IDs
          if (data['id']?.toString().startsWith('temp-') == true) {
            data.remove('id');
          }
          
          return data;
        }).toList();

        await _supabase
            .from('line_items')
            .insert(lineItemsData);
      }

      // Commit the transaction
      await _supabase.rpc('commit_transaction');

      // Fetch the updated receipt with line items
      return await getReceiptWithLineItems(receiptId);
    } catch (error) {
      // Rollback on error
      try {
        await _supabase.rpc('rollback_transaction');
      } catch (_) {
        // Ignore rollback errors
      }
      rethrow;
    }
  }

  /// Get a receipt with its line items
  static Future<ReceiptModel> getReceiptWithLineItems(String receiptId) async {
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
      
      return receipt.copyWith(lineItems: lineItems);
    }

    return receipt;
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
