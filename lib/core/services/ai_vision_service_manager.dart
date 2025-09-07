import 'dart:io';
import 'package:logger/logger.dart';
import 'ai_vision_service.dart';
import 'gemini_vision_service.dart';
import 'openrouter_vision_service.dart';

/// Service manager that handles AI vision processing with automatic fallback
class AIVisionServiceManager {
  static final Logger _logger = Logger();
  static final List<AIVisionService> _services = [];
  static bool _initialized = false;

  /// Initialize the service manager with available services
  static void initialize() {
    if (_initialized) return;

    _services.clear();
    
    // Add services in order of preference (priority)
    final geminiService = GeminiVisionService();
    final openRouterService = OpenRouterVisionService();
    
    // Only add configured services
    if (geminiService.isConfigured()) {
      _services.add(geminiService);
      _logger.i('✅ Gemini Vision Service added to manager');
    } else {
      _logger.w('⚠️ Gemini Vision Service not configured - skipping');
    }
    
    if (openRouterService.isConfigured()) {
      _services.add(openRouterService);
      _logger.i('✅ OpenRouter Vision Service added to manager');
    } else {
      _logger.w('⚠️ OpenRouter Vision Service not configured - skipping');
    }
    
    // Sort services by priority (lower number = higher priority)
    _services.sort((a, b) => a.priority.compareTo(b.priority));
    
    _initialized = true;
    _logger.i('🎉 AI Vision Service Manager initialized with ${_services.length} services');
    
    if (_services.isEmpty) {
      _logger.e('❌ No AI vision services are configured! Receipt processing will not work.');
    }
  }

  /// Process receipt image with automatic fallback
  static Future<ReceiptData> processReceiptImage(File imageFile) async {
    if (!_initialized) {
      initialize();
    }

    if (_services.isEmpty) {
      throw ServiceConfigurationException(
        'No AI vision services are configured. Please configure at least one service (Gemini or OpenRouter).',
        'AIVisionServiceManager',
      );
    }

    _logger.i('Processing receipt image with ${_services.length} available services');

    Exception? lastError;
    final List<String> attemptedServices = [];

    for (final service in _services) {
      try {
        _logger.i('Attempting to process with ${service.serviceName}...');
        attemptedServices.add(service.serviceName);
        
        final result = await service.processReceiptImage(imageFile);
        
        // Check if the result has an error
        if (result.hasError) {
          _logger.w('${service.serviceName} returned error result: ${result.error}');
          
          // If it's a geographic restriction, don't retry with the same service
          if (result.error?.contains('geographic') == true ||
              result.error?.contains('UnsupportedUserLocation') == true ||
              result.error?.contains('not available in your') == true) {
            _logger.w('Geographic restriction detected for ${service.serviceName}, trying next service...');
            lastError = GeographicRestrictionException(
              result.error ?? 'Geographic restriction',
              service.serviceName,
            );
            continue;
          }
          
          // For other errors, still try next service
          lastError = Exception('${service.serviceName}: ${result.error}');
          continue;
        }
        
        // Success!
        _logger.i('✅ Successfully processed receipt with ${service.serviceName}');
        _logger.i('Confidence: ${result.confidence}, Merchant: ${result.merchantName}, Total: ${result.totalAmount}');
        
        return result;
        
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        _logger.w('${service.serviceName} failed: $e');
        
        // Check for specific error types that should trigger immediate fallback
        if (e is GeographicRestrictionException) {
          _logger.w('Geographic restriction for ${service.serviceName}, trying next service...');
          continue;
        }
        
        if (e is QuotaExceededException) {
          _logger.w('Quota exceeded for ${service.serviceName}, trying next service...');
          continue;
        }
        
        if (e.toString().contains('UnsupportedUserLocation') ||
            e.toString().contains('geographic restriction') ||
            e.toString().contains('not available in your current location')) {
          _logger.w('Geographic restriction detected for ${service.serviceName}, trying next service...');
          lastError = GeographicRestrictionException(
            e.toString(),
            service.serviceName,
          );
          continue;
        }
        
        if (e.toString().contains('quota') ||
            e.toString().contains('rate_limit') ||
            e.toString().contains('insufficient_quota')) {
          _logger.w('Quota/rate limit for ${service.serviceName}, trying next service...');
          lastError = QuotaExceededException(
            e.toString(),
            service.serviceName,
          );
          continue;
        }
        
        // For other errors, continue to next service
        continue;
      }
    }

    // All services failed
    _logger.e('❌ All AI vision services failed. Attempted: ${attemptedServices.join(', ')}');
    
    // Determine the most appropriate error message
    String errorMessage = 'All AI vision services failed to process the receipt.';
    if (lastError is GeographicRestrictionException) {
      errorMessage = 'AI vision services are not available in your region. Please try using a VPN or manual entry.';
    } else if (lastError is QuotaExceededException) {
      errorMessage = 'AI vision service quotas exceeded. Please try again later.';
    } else if (lastError != null) {
      errorMessage = 'AI vision processing failed: ${lastError.toString()}';
    }

    // Return error result
    return ReceiptData(
      merchantName: 'Processing Error',
      totalAmount: null,
      transactionDate: DateTime.now(),
      category: 'Uncategorized',
      currency: 'MYR',
      confidence: 0.0,
      rawResponse: 'Failed with all services: ${attemptedServices.join(', ')}',
      error: errorMessage,
    );
  }

  /// Test connection for all configured services
  static Future<Map<String, String>> testAllConnections() async {
    if (!_initialized) {
      initialize();
    }

    final results = <String, String>{};
    
    for (final service in _services) {
      try {
        _logger.i('Testing connection for ${service.serviceName}...');
        final result = await service.testConnection();
        results[service.serviceName] = 'OK: $result';
        _logger.i('✅ ${service.serviceName} connection test passed');
      } catch (e) {
        results[service.serviceName] = 'ERROR: $e';
        _logger.e('❌ ${service.serviceName} connection test failed: $e');
      }
    }
    
    return results;
  }

  /// Get status of all services
  static Map<String, dynamic> getServicesStatus() {
    if (!_initialized) {
      initialize();
    }

    return {
      'initialized': _initialized,
      'total_services': _services.length,
      'services': _services.map((service) => {
        'name': service.serviceName,
        'priority': service.priority,
        'configured': service.isConfigured(),
        'supported_formats': ['image/jpeg', 'image/png', 'image/webp']
            .where((format) => service.supportsImageFormat(format))
            .toList(),
      }).toList(),
    };
  }

  /// Check if any service is configured
  static bool hasConfiguredServices() {
    if (!_initialized) {
      initialize();
    }
    return _services.isNotEmpty;
  }

  /// Get the list of configured service names
  static List<String> getConfiguredServiceNames() {
    if (!_initialized) {
      initialize();
    }
    return _services.map((service) => service.serviceName).toList();
  }
}
