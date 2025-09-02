import 'dart:io';

/// Data class for receipt information extracted by AI Vision services
class ReceiptData {
  final String? merchantName;
  final String? merchantAddress;
  final String? merchantPhone;
  final String? receiptNumber;
  final DateTime? transactionDate;
  final String? transactionTime;
  final double? totalAmount;
  final double? subtotalAmount;
  final double? taxAmount;
  final double? discountAmount;
  final double? tipAmount;
  final String? currency;
  final String? paymentMethod;
  final String? category;
  final List<ReceiptItem>? items;
  final double confidence;
  final String? notes;
  final String rawResponse;
  final String? error;

  const ReceiptData({
    this.merchantName,
    this.merchantAddress,
    this.merchantPhone,
    this.receiptNumber,
    this.transactionDate,
    this.transactionTime,
    this.totalAmount,
    this.subtotalAmount,
    this.taxAmount,
    this.discountAmount,
    this.tipAmount,
    this.currency,
    this.paymentMethod,
    this.category,
    this.items,
    required this.confidence,
    this.notes,
    required this.rawResponse,
    this.error,
  });

  bool get hasError => error != null;
  bool get isHighConfidence => confidence >= 0.7;

  /// Factory constructor to create ReceiptData from JSON response
  factory ReceiptData.fromJson(Map<String, dynamic> json, String rawResponse) {
    try {
      // Parse transaction date
      DateTime? transactionDate;
      if (json['transactionDate'] != null) {
        try {
          transactionDate = DateTime.parse(json['transactionDate']);
        } catch (e) {
          // If parsing fails, try to parse as different formats
          final dateStr = json['transactionDate'].toString();
          try {
            // Try parsing DD-MM-YYYY or MM-DD-YYYY formats
            final parts = dateStr.split(RegExp(r'[/-]'));
            if (parts.length == 3) {
              // Assume YYYY-MM-DD format first
              if (parts[0].length == 4) {
                transactionDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              } else {
                // Assume DD-MM-YYYY format
                transactionDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
              }
            }
          } catch (_) {
            // Ignore parsing errors, use null
          }
        }
      }

      // Parse amounts safely
      double? parseAmount(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        if (value is String) {
          try {
            return double.parse(value.replaceAll(RegExp(r'[^\d.-]'), ''));
          } catch (_) {
            return null;
          }
        }
        return null;
      }

      // Parse confidence safely
      double confidence = 0.5; // Default to medium confidence
      if (json['confidence'] != null) {
        if (json['confidence'] is num) {
          confidence = (json['confidence'] as num).toDouble();
        } else if (json['confidence'] is String) {
          try {
            confidence = double.parse(json['confidence']);
          } catch (_) {
            confidence = 0.5;
          }
        }
      }

      // Ensure confidence is between 0 and 1
      confidence = confidence.clamp(0.0, 1.0);

      // Parse line items
      List<ReceiptItem>? items;
      if (json['items'] != null && json['items'] is List) {
        try {
          items = (json['items'] as List)
              .map((item) => ReceiptItem.fromJson(item))
              .where((item) => item != null)
              .cast<ReceiptItem>()
              .toList();
        } catch (e) {
          items = null;
        }
      }

      return ReceiptData(
        merchantName: json['merchantName']?.toString(),
        merchantAddress: json['merchantAddress']?.toString(),
        merchantPhone: json['merchantPhone']?.toString(),
        receiptNumber: json['receiptNumber']?.toString(),
        transactionDate: transactionDate,
        transactionTime: json['transactionTime']?.toString(),
        totalAmount: parseAmount(json['totalAmount']),
        subtotalAmount: parseAmount(json['subtotalAmount']),
        taxAmount: parseAmount(json['taxAmount']),
        discountAmount: parseAmount(json['discountAmount']),
        tipAmount: parseAmount(json['tipAmount']),
        currency: json['currency']?.toString() ?? 'USD',
        paymentMethod: json['paymentMethod']?.toString(),
        category: json['category']?.toString(),
        items: items,
        confidence: confidence,
        notes: json['notes']?.toString(),
        rawResponse: rawResponse,
      );
    } catch (e) {
      return ReceiptData(
        merchantName: 'Parse Error',
        totalAmount: null,
        transactionDate: DateTime.now(),
        category: 'Uncategorized',
        currency: 'USD',
        confidence: 0.0,
        rawResponse: rawResponse,
        error: 'JSON parsing failed: ${e.toString()}',
      );
    }
  }
}

/// Data class for individual receipt items
class ReceiptItem {
  final String name;
  final int? quantity;
  final double? unitPrice;
  final double? totalPrice;

  const ReceiptItem({
    required this.name,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  /// Factory constructor to create ReceiptItem from JSON
  static ReceiptItem? fromJson(Map<String, dynamic> json) {
    try {
      final name = json['name']?.toString();
      if (name == null || name.isEmpty) return null;

      // Parse numeric values safely
      int? quantity;
      if (json['quantity'] != null) {
        if (json['quantity'] is num) {
          quantity = (json['quantity'] as num).toInt();
        } else if (json['quantity'] is String) {
          try {
            quantity = int.parse(json['quantity']);
          } catch (_) {
            quantity = null;
          }
        }
      }

      double? parsePrice(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        if (value is String) {
          try {
            return double.parse(value.replaceAll(RegExp(r'[^\d.-]'), ''));
          } catch (_) {
            return null;
          }
        }
        return null;
      }

      return ReceiptItem(
        name: name,
        quantity: quantity,
        unitPrice: parsePrice(json['unitPrice']),
        totalPrice: parsePrice(json['totalPrice']),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Abstract interface for AI vision services
abstract class AIVisionService {
  /// Process receipt image and extract structured data
  Future<ReceiptData> processReceiptImage(File imageFile);
  
  /// Test the service connection
  Future<String> testConnection();
  
  /// Check if the service is properly configured
  bool isConfigured();
  
  /// Get the service name
  String get serviceName;
  
  /// Get the service priority (lower number = higher priority)
  int get priority;
  
  /// Check if the service supports the given image format
  bool supportsImageFormat(String mimeType);
}

/// Exception thrown when a service is not available due to geographic restrictions
class GeographicRestrictionException implements Exception {
  final String message;
  final String service;
  
  const GeographicRestrictionException(this.message, this.service);
  
  @override
  String toString() => 'GeographicRestrictionException: $message (Service: $service)';
}

/// Exception thrown when a service has reached its quota limit
class QuotaExceededException implements Exception {
  final String message;
  final String service;
  
  const QuotaExceededException(this.message, this.service);
  
  @override
  String toString() => 'QuotaExceededException: $message (Service: $service)';
}

/// Exception thrown when a service configuration is invalid
class ServiceConfigurationException implements Exception {
  final String message;
  final String service;
  
  const ServiceConfigurationException(this.message, this.service);
  
  @override
  String toString() => 'ServiceConfigurationException: $message (Service: $service)';
}
