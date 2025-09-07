import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import 'ai_vision_service.dart';
import '../../shared/utils/currency_utils.dart';

/// Service for processing receipt images using OpenRouter Vision API
class OpenRouterVisionService implements AIVisionService {
  static final Logger _logger = Logger();
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  
  // Available vision models in order of preference
  static const List<String> _visionModels = [
    'google/gemini-pro-vision',
    'anthropic/claude-3-haiku:beta',
    'openai/gpt-4-vision-preview',
    'meta-llama/llama-3.2-90b-vision-instruct',
    'qwen/qwen-2-vl-72b-instruct',
  ];

  @override
  String get serviceName => 'OpenRouter Vision';

  @override
  int get priority => 2; // Lower priority than Gemini

  @override
  bool isConfigured() {
    return AppConstants.openRouterApiKey.isNotEmpty;
  }

  @override
  bool supportsImageFormat(String mimeType) {
    return ['image/jpeg', 'image/png', 'image/webp'].contains(mimeType);
  }

  @override
  Future<ReceiptData> processReceiptImage(File imageFile) async {
    if (!isConfigured()) {
      throw ServiceConfigurationException(
        'OpenRouter API key is not configured. Please set OPENROUTER_API_KEY environment variable.',
        serviceName,
      );
    }

    try {
      _logger.i('Processing receipt image with OpenRouter: ${imageFile.path}');

      // Validate image file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSizeBytes = await imageFile.length();
      _logger.d('Image file size: $fileSizeBytes bytes');
      
      // Check file size (4MB limit for most OpenRouter models)
      if (fileSizeBytes > 4 * 1024 * 1024) {
        throw Exception('Image file too large. Maximum size is 4MB for OpenRouter.');
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
      final dataUrl = 'data:$mimeType;base64,$base64Image';

      // Try each model until one succeeds
      Exception? lastError;
      for (final model in _visionModels) {
        try {
          _logger.d('Attempting with model: $model');
          final result = await _callOpenRouterAPI(model, dataUrl);
          _logger.i('Successfully processed receipt with model: $model');
          return result;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          _logger.w('Model $model failed: $e');
          
          // If it's a configuration or quota error, don't try other models
          if (e.toString().contains('quota') || 
              e.toString().contains('insufficient_quota') ||
              e.toString().contains('rate_limit')) {
            throw QuotaExceededException(
              'OpenRouter quota exceeded or rate limited. Please try again later.',
              serviceName,
            );
          }
          
          // Continue to next model for other errors
          continue;
        }
      }

      // All models failed
      throw lastError ?? Exception('All OpenRouter models failed to process the image');

    } catch (e) {
      _logger.e('Error processing receipt image with OpenRouter: $e');
      
      // Return error response
      return ReceiptData(
        merchantName: 'Processing Error',
        totalAmount: null,
        transactionDate: DateTime.now(),
        category: 'Uncategorized',
        currency: 'USD',
        confidence: 0.0,
        rawResponse: '',
        error: 'Failed to process receipt with OpenRouter: ${e.toString()}',
      );
    }
  }

  Future<ReceiptData> _callOpenRouterAPI(String model, String dataUrl) async {
    final prompt = _buildReceiptExtractionPrompt();
    
    final requestBody = {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': dataUrl,
                'detail': 'high',
              },
            },
          ],
        },
      ],
      'max_tokens': 2048,
      'temperature': 0.3,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AppConstants.openRouterApiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://mataresit.com',
        'X-Title': 'Mataresit Receipt Processing',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      _logger.e('OpenRouter API error: ${response.statusCode} - $errorBody');
      throw Exception('OpenRouter API error: ${response.statusCode} - $errorBody');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List<dynamic>?;
    
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from OpenRouter API');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    
    if (content == null || content.isEmpty) {
      throw Exception('Empty response from OpenRouter API');
    }

    _logger.d('OpenRouter response preview: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');
    
    // Parse the structured response
    return _parseReceiptData(content);
  }

  String _buildReceiptExtractionPrompt() {
    return '''
Analyze this receipt image and extract the following information in JSON format:

{
  "merchantName": "Name of the business/merchant",
  "merchantAddress": "Full address if visible",
  "merchantPhone": "Phone number if visible",
  "receiptNumber": "Receipt/transaction number if visible",
  "transactionDate": "Date in YYYY-MM-DD format",
  "transactionTime": "Time if visible (HH:MM format)",
  "totalAmount": 0.00,
  "subtotalAmount": 0.00,
  "taxAmount": 0.00,
  "discountAmount": 0.00,
  "tipAmount": 0.00,
  "currency": "Currency code (e.g., USD, MYR, EUR)",
  "paymentMethod": "Payment method if visible (e.g., Cash, Card, etc.)",
  "category": "Predicted category (e.g., Food, Gas, Shopping, etc.)",
  "items": [
    {
      "name": "Item name",
      "quantity": 1,
      "unitPrice": 0.00,
      "totalPrice": 0.00
    }
  ],
  "confidence": 0.95,
  "notes": "Any additional notes or observations"
}

Important guidelines:
- Extract ALL visible text accurately
- Use null for missing information
- Ensure totalAmount is the final amount paid
- Include tax in taxAmount if separately listed
- Set confidence between 0.0 and 1.0 based on text clarity
- For currency, detect from symbols or context (default to USD if unclear)
- Parse dates carefully, use YYYY-MM-DD format
- Include line items if clearly visible
- Be precise with numerical values
- Return ONLY the JSON object, no additional text
''';
  }

  @override
  Future<String> testConnection() async {
    if (!isConfigured()) {
      throw ServiceConfigurationException(
        'OpenRouter API key is not configured',
        serviceName,
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AppConstants.openRouterApiKey}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://mataresit.com',
          'X-Title': 'Mataresit Connection Test',
        },
        body: jsonEncode({
          'model': 'google/gemini-pro-vision',
          'messages': [
            {
              'role': 'user',
              'content': 'Hello, can you confirm you are working? Please respond with "OK".',
            },
          ],
          'max_tokens': 10,
          'temperature': 0,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = responseData['choices'] as List<dynamic>?;
        final message = choices?[0]['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        return content ?? 'Connection successful';
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _logger.e('Error testing OpenRouter connection: $e');
      rethrow;
    }
  }

  ReceiptData _parseReceiptData(String response) {
    try {
      // Clean up the response - remove markdown code blocks if present
      String cleanedResponse = response.trim();

      // Remove markdown code blocks
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

      _logger.d('Parsing OpenRouter response: $cleanedResponse');

      // Parse the JSON response
      final Map<String, dynamic> jsonData = jsonDecode(cleanedResponse);

      // Parse transaction date
      DateTime? transactionDate;
      if (jsonData['transactionDate'] != null) {
        try {
          transactionDate = DateTime.parse(jsonData['transactionDate']);
        } catch (e) {
          // If parsing fails, try to parse as different formats
          final dateStr = jsonData['transactionDate'].toString();
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
            transactionDate = DateTime.now();
          }
        }
      }

      // Parse amounts safely
      double? parseAmount(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        if (value is String) {
          try {
            // Remove currency symbols and parse
            final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
            return double.parse(cleanValue);
          } catch (_) {
            return null;
          }
        }
        return null;
      }

      // Parse confidence
      double confidence = 0.5; // Default confidence
      if (jsonData['confidence'] != null) {
        if (jsonData['confidence'] is num) {
          confidence = (jsonData['confidence'] as num).toDouble();
        } else if (jsonData['confidence'] is String) {
          try {
            confidence = double.parse(jsonData['confidence']);
          } catch (_) {
            confidence = 0.5;
          }
        }
      }

      // Parse items
      List<ReceiptItem>? items;
      if (jsonData['items'] is List) {
        items = (jsonData['items'] as List)
            .map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
            .where((item) => item != null)
            .cast<ReceiptItem>()
            .toList();
      }

      return ReceiptData(
        merchantName: jsonData['merchantName']?.toString(),
        merchantAddress: jsonData['merchantAddress']?.toString(),
        merchantPhone: jsonData['merchantPhone']?.toString(),
        receiptNumber: jsonData['receiptNumber']?.toString(),
        transactionDate: transactionDate,
        transactionTime: jsonData['transactionTime']?.toString(),
        totalAmount: parseAmount(jsonData['totalAmount']),
        subtotalAmount: parseAmount(jsonData['subtotalAmount']),
        taxAmount: parseAmount(jsonData['taxAmount']),
        discountAmount: parseAmount(jsonData['discountAmount']),
        tipAmount: parseAmount(jsonData['tipAmount']),
        currency: CurrencyUtils.normalizeCurrencyCode(jsonData['currency']?.toString() ?? 'MYR'),
        paymentMethod: jsonData['paymentMethod']?.toString(),
        category: jsonData['category']?.toString(),
        items: items,
        confidence: confidence,
        notes: jsonData['notes']?.toString(),
        rawResponse: response,
      );
    } catch (e) {
      _logger.e('Error parsing OpenRouter receipt data: $e');
      _logger.e('Raw response: $response');

      // Return a fallback response
      return ReceiptData(
        merchantName: 'Unknown Merchant',
        totalAmount: null,
        transactionDate: DateTime.now(),
        category: 'Uncategorized',
        currency: 'MYR',
        confidence: 0.0,
        rawResponse: response,
        error: 'Failed to parse receipt data: ${e.toString()}',
      );
    }
  }
}
