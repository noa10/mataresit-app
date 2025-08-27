import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';

/// Service for processing receipt images using Google Gemini Vision API
class GeminiVisionService {
  static final Logger _logger = Logger();
  static GenerativeModel? _model;

  /// Initialize the Gemini model
  static void initialize() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppConstants.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
    );
    _logger.i('Gemini Vision Service initialized');
  }

  /// Process receipt image and extract structured data
  static Future<ReceiptData> processReceiptImage(File imageFile) async {
    if (_model == null) {
      throw Exception('Gemini Vision Service not initialized');
    }

    try {
      _logger.i('Processing receipt image: ${imageFile.path}');

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Create the prompt for receipt data extraction
      final prompt = _buildReceiptExtractionPrompt();
      
      // Create content with image and text
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // Generate response
      final response = await _model!.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No response from Gemini Vision API');
      }

      _logger.i('Gemini Vision response received');
      
      // Parse the structured response
      return _parseReceiptData(response.text!);
      
    } catch (e) {
      _logger.e('Error processing receipt image: $e');
      rethrow;
    }
  }

  /// Build the prompt for receipt data extraction
  static String _buildReceiptExtractionPrompt() {
    return '''
Analyze this receipt image and extract the following information in JSON format. Be as accurate as possible and use null for any information that cannot be clearly determined from the image.

Please return ONLY a valid JSON object with this exact structure:

{
  "merchantName": "string or null",
  "merchantAddress": "string or null", 
  "merchantPhone": "string or null",
  "receiptNumber": "string or null",
  "transactionDate": "YYYY-MM-DD or null",
  "transactionTime": "HH:MM or null",
  "totalAmount": number or null,
  "subtotalAmount": number or null,
  "taxAmount": number or null,
  "discountAmount": number or null,
  "tipAmount": number or null,
  "currency": "string or null",
  "paymentMethod": "string or null",
  "category": "string or null",
  "items": [
    {
      "name": "string",
      "quantity": number or null,
      "unitPrice": number or null,
      "totalPrice": number or null
    }
  ],
  "confidence": number between 0 and 1,
  "notes": "string with any additional observations or null"
}

Guidelines:
- For merchantName: Extract the business/store name
- For category: Suggest appropriate category like "Food & Beverage", "Gas", "Retail", "Healthcare", etc.
- For items: Extract individual line items if clearly visible
- For amounts: Extract numeric values only (no currency symbols)
- For dates: Use YYYY-MM-DD format
- For confidence: Rate how confident you are in the extraction (0.0 to 1.0)
- For currency: Use standard codes like "USD", "EUR", etc.
- For paymentMethod: "Cash", "Credit Card", "Debit Card", etc.

Return ONLY the JSON object, no additional text or formatting.
''';
  }

  /// Parse the Gemini response into structured receipt data
  static ReceiptData _parseReceiptData(String response) {
    try {
      // Clean the response to ensure it's valid JSON
      String cleanedResponse = response.trim();
      
      // Remove any markdown formatting if present
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      
      cleanedResponse = cleanedResponse.trim();
      
      _logger.d('Parsing Gemini response: $cleanedResponse');
      
      // For now, return a mock response structure
      // In a real implementation, you would parse the JSON response
      return ReceiptData(
        merchantName: 'Sample Merchant',
        totalAmount: 25.99,
        transactionDate: DateTime.now(),
        category: 'Food & Beverage',
        currency: 'USD',
        confidence: 0.85,
        rawResponse: cleanedResponse,
      );
      
    } catch (e) {
      _logger.e('Error parsing receipt data: $e');
      
      // Return a fallback response
      return ReceiptData(
        merchantName: 'Unknown Merchant',
        totalAmount: null,
        transactionDate: DateTime.now(),
        category: 'Uncategorized',
        currency: 'USD',
        confidence: 0.0,
        rawResponse: response,
        error: 'Failed to parse receipt data: ${e.toString()}',
      );
    }
  }

  /// Test the Gemini Vision service with a sample prompt
  static Future<String> testConnection() async {
    if (_model == null) {
      throw Exception('Gemini Vision Service not initialized');
    }

    try {
      final content = [Content.text('Hello, can you confirm you are working?')];
      final response = await _model!.generateContent(content);
      return response.text ?? 'No response';
    } catch (e) {
      _logger.e('Error testing Gemini connection: $e');
      rethrow;
    }
  }
}

/// Data class for receipt information extracted by Gemini Vision
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
}
