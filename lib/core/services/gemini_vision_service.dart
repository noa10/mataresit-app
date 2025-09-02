import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import 'ai_vision_service.dart';

/// Service for processing receipt images using Google Gemini Vision API
class GeminiVisionService implements AIVisionService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-1.5-flash';

  final Logger _logger = Logger();

  @override
  String get serviceName => 'Gemini Vision';

  @override
  int get priority => 1; // Highest priority

  @override
  bool supportsImageFormat(String mimeType) {
    return ['image/jpeg', 'image/png', 'image/webp'].contains(mimeType);
  }

  @override
  bool isConfigured() {
    return AppConstants.geminiApiKey.isNotEmpty;
  }

  @override
  Future<ReceiptData> processReceiptImage(File imageFile) async {
    if (!isConfigured()) {
      throw ServiceConfigurationException(
        'Gemini API key is not configured. Please set GEMINI_API_KEY environment variable.',
        serviceName,
      );
    }

    try {
      _logger.i('Processing receipt image with Gemini: ${imageFile.path}');

      // Validate image file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSizeBytes = await imageFile.length();
      _logger.i('Image file size: $fileSizeBytes bytes');

      // Check file size (5MB limit)
      if (fileSizeBytes > 5 * 1024 * 1024) {
        throw Exception('Image file too large. Maximum size is 5MB.');
      }

      // Check minimum file size
      if (fileSizeBytes < 1024) {
        throw Exception('Image file too small. Please select a valid image.');
      }

      // Read image bytes and convert to base64
      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      // Determine MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'jpg':
        case 'jpeg':
        default:
          mimeType = 'image/jpeg';
          break;
      }

      if (!supportsImageFormat(mimeType)) {
        throw Exception('Unsupported image format: $mimeType');
      }

      final base64Image = base64Encode(imageBytes);

      // Try processing with retry logic
      Exception? lastError;
      const maxRetries = 3;

      for (int retryCount = 0; retryCount < maxRetries; retryCount++) {
        try {
          _logger.i('Attempt ${retryCount + 1} of $maxRetries');
          final result = await _callGeminiAPI(base64Image, mimeType);
          _logger.i('Successfully processed receipt with Gemini');
          return result;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          _logger.w('Attempt ${retryCount + 1} failed: $e');

          // Check for specific error types
          if (e.toString().contains('UnsupportedUserLocation')) {
            throw GeographicRestrictionException(
              'Gemini AI is not available in your current location.',
              serviceName,
            );
          }

          if (e.toString().contains('quota') || e.toString().contains('rate_limit')) {
            throw QuotaExceededException(
              'Gemini API quota exceeded or rate limited.',
              serviceName,
            );
          }

          if (retryCount >= maxRetries - 1) {
            throw lastError;
          }

          // Wait before retrying (exponential backoff)
          final delaySeconds = (retryCount + 1) * 2;
          _logger.i('Waiting ${delaySeconds}s before retry...');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }

      throw lastError ?? Exception('All retry attempts failed');

    } catch (e) {
      _logger.e('Error processing receipt image with Gemini: $e');

      // Return error response
      return ReceiptData(
        merchantName: 'Processing Error',
        totalAmount: null,
        transactionDate: DateTime.now(),
        category: 'Uncategorized',
        currency: 'USD',
        confidence: 0.0,
        rawResponse: '',
        error: 'Failed to process receipt with Gemini: ${e.toString()}',
      );
    }
  }

  Future<ReceiptData> _callGeminiAPI(String base64Image, String mimeType) async {
    final prompt = _buildReceiptExtractionPrompt();

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': prompt,
            },
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.3,
        'topK': 32,
        'topP': 1,
        'maxOutputTokens': 8192,
      },
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/$_model:generateContent?key=${AppConstants.geminiApiKey}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      _logger.e('Gemini API error: ${response.statusCode} - $errorBody');

      if (errorBody.contains('UnsupportedUserLocation')) {
        throw GeographicRestrictionException(
          'Gemini API not available in your region',
          serviceName,
        );
      }

      throw Exception('Gemini API error: ${response.statusCode} - $errorBody');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = responseData['candidates'] as List<dynamic>?;

    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini API');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?[0]['text'] as String?;

    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini API');
    }

    _logger.i('Gemini response preview: ${text.substring(0, text.length > 200 ? 200 : text.length)}...');

    // Parse the structured response
    return _parseReceiptData(text);
  }

  /// Build the prompt for receipt data extraction
  String _buildReceiptExtractionPrompt() {
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
- For merchantName: Extract the business/store name from the receipt header
- For merchantAddress: Extract the complete business address if visible
- For merchantPhone: Extract phone number if visible
- For receiptNumber: Look for receipt/invoice/transaction number
- For transactionDate: Use YYYY-MM-DD format (e.g., "2024-03-15")
- For transactionTime: Use HH:MM format (e.g., "14:30")
- For category: Suggest appropriate category like "Food & Beverage", "Gas", "Retail", "Healthcare", "Transportation", "Entertainment", "Office Supplies", etc.
- For items: Extract individual line items with descriptions, quantities, and prices if clearly visible
- For amounts: Extract numeric values only (no currency symbols), use null if not clearly visible
- For currency: Use standard codes like "USD", "EUR", "MYR", "SGD", etc. Default to "USD" if unclear
- For paymentMethod: "Cash", "Credit Card", "Debit Card", "Mobile Payment", etc.
- For confidence: Rate how confident you are in the overall extraction (0.0 to 1.0)
- For notes: Include any additional observations about receipt quality, special offers, or unclear text

IMPORTANT: Return ONLY the JSON object, no additional text, markdown formatting, or explanations.
''';
  }

  /// Parse the Gemini response into structured receipt data
  ReceiptData _parseReceiptData(String response) {
    try {
      // Clean the response to ensure it's valid JSON
      String cleanedResponse = response.trim();
      
      // Remove any markdown formatting if present
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      
      cleanedResponse = cleanedResponse.trim();
      
      _logger.i('Parsing Gemini response: $cleanedResponse');

      // Parse the JSON response
      final Map<String, dynamic> jsonData = jsonDecode(cleanedResponse);

      // Validate required fields and parse the response
      return ReceiptData.fromJson(jsonData, cleanedResponse);

    } catch (e) {
      _logger.e('Error parsing receipt data: $e');
      _logger.e('Raw response: $response');
      
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

  @override
  Future<String> testConnection() async {
    if (!isConfigured()) {
      throw ServiceConfigurationException(
        'Gemini API key is not configured',
        serviceName,
      );
    }

    try {
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': 'Hello, can you confirm you are working? Please respond with "OK".',
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0,
          'maxOutputTokens': 10,
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=${AppConstants.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = responseData['candidates'] as List<dynamic>?;
        final content = candidates?[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        final text = parts?[0]['text'] as String?;
        return text ?? 'Connection successful';
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _logger.e('Error testing Gemini connection: $e');
      rethrow;
    }
  }

  /// Get the current configuration status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': true,
      'hasApiKey': AppConstants.geminiApiKey.isNotEmpty,
      'apiKeyPreview': AppConstants.geminiApiKey.isNotEmpty
        ? '${AppConstants.geminiApiKey.substring(0, 8)}...'
        : 'Not set',
      'model': 'gemini-1.5-flash',
    };
  }
}
