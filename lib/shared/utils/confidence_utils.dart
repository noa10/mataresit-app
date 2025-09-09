import '../models/receipt_model.dart';

/// Utility class for calculating and handling confidence scores
class ConfidenceUtils {
  /// Calculate aggregate confidence score from individual field confidence scores
  /// Matches the React web version's calculateAggregateConfidence logic
  static double calculateAggregateConfidence(ReceiptModel receipt) {
    // First, check if we have a direct confidence score from ai_suggestions
    if (receipt.aiSuggestions != null &&
        receipt.aiSuggestions!.containsKey('confidence')) {
      final confidence = _parseConfidenceValue(
        receipt.aiSuggestions!['confidence'],
      );
      if (confidence != null) {
        // Convert from decimal (0.95) to percentage (95) if needed
        final result = confidence > 1 ? confidence : confidence * 100;
        return result.clamp(0.0, 100.0);
      }
    }

    // Fallback to confidence_scores field for older receipts
    if (receipt.confidenceScores == null) return 0.0;

    // Handle legacy format from older Flutter app versions (backward compatibility)
    if (receipt.confidenceScores!.containsKey('overall')) {
      final confidence = _parseConfidenceValue(
        receipt.confidenceScores!['overall'],
      );
      if (confidence != null) {
        // Convert from decimal (0.95) to percentage (95) if needed
        final result = confidence > 1 ? confidence : confidence * 100;
        return result.clamp(0.0, 100.0);
      }
    }

    // Define weights for each field (total = 1.0)
    // These weights match the React web version
    const weights = {
      'merchant': 0.3, // 30% weight for merchant name
      'date': 0.2, // 20% weight for date
      'total': 0.3, // 30% weight for total amount
      'payment_method': 0.1, // 10% weight for payment method
      'tax': 0.1, // 10% weight for tax
    };

    // Calculate weighted average
    double totalWeight = 0.0;
    double weightedSum = 0.0;

    for (final entry in weights.entries) {
      final field = entry.key;
      final weight = entry.value;

      if (receipt.confidenceScores!.containsKey(field)) {
        final confidence = _parseConfidenceValue(
          receipt.confidenceScores![field],
        );
        if (confidence != null) {
          weightedSum += (confidence * weight);
          totalWeight += weight;
        }
      }
    }

    // If no valid confidence scores found, return 0
    if (totalWeight == 0) return 0.0;

    // Calculate final weighted average (already in percentage 0-100)
    final result = weightedSum / totalWeight;
    return result.clamp(0.0, 100.0);
  }

  /// Parse confidence value from various formats (decimal, percentage, string)
  static double? _parseConfidenceValue(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      final doubleValue = value.toDouble();
      // If value is > 1, assume it's already a percentage (0-100)
      // If value is <= 1, assume it's a decimal (0-1) and convert to percentage
      return doubleValue > 1 ? doubleValue : doubleValue * 100;
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed > 1 ? parsed : parsed * 100;
      }
    }

    return null;
  }

  /// Normalize confidence score to ensure it's in the 0-100 range
  static double normalizeConfidence(double? score) {
    if (score == null) return 50.0; // Default to 50% instead of 0
    final numScore = score;
    if (numScore.isNaN) return 50.0; // Default to 50% if invalid

    // Assume scores > 1 are already percentages, otherwise convert decimal
    final normalized = numScore > 1 ? numScore : numScore * 100;
    return normalized.clamp(0.0, 100.0);
  }

  /// Get confidence color based on score
  /// Returns color values that match the React web version
  static ConfidenceColor getConfidenceColor(double confidence) {
    if (confidence >= 80) {
      return ConfidenceColor.high;
    } else if (confidence >= 60) {
      return ConfidenceColor.medium;
    } else {
      return ConfidenceColor.low;
    }
  }

  /// Get confidence label based on score
  static String getConfidenceLabel(double confidence) {
    if (confidence >= 80) return 'High';
    if (confidence >= 60) return 'Medium';
    if (confidence >= 40) return 'Low';
    return 'Very Low';
  }

  /// Check if confidence score indicates high reliability
  static bool isHighConfidence(double confidence) {
    return confidence >= 80;
  }

  /// Check if confidence score indicates medium reliability
  static bool isMediumConfidence(double confidence) {
    return confidence >= 60 && confidence < 80;
  }

  /// Check if confidence score indicates low reliability
  static bool isLowConfidence(double confidence) {
    return confidence < 60;
  }

  /// Get confidence score from AI vision service data
  /// This handles the confidence score from the AI processing
  static double getAIConfidenceScore(Map<String, dynamic>? metadata) {
    if (metadata == null) return 0.0;

    // Check for confidence in metadata
    if (metadata.containsKey('confidence')) {
      final confidence = _parseConfidenceValue(metadata['confidence']);
      return confidence ?? 0.0;
    }

    // Check for ai_confidence
    if (metadata.containsKey('ai_confidence')) {
      final confidence = _parseConfidenceValue(metadata['ai_confidence']);
      return confidence ?? 0.0;
    }

    return 0.0;
  }
}

/// Enum for confidence color categories
enum ConfidenceColor {
  high, // Green - 80% and above
  medium, // Yellow - 60-79%
  low, // Red - below 60%
}

/// Extension to get color values for confidence colors
extension ConfidenceColorExtension on ConfidenceColor {
  /// Get the primary color value (for text/icons)
  int get primaryColor {
    switch (this) {
      case ConfidenceColor.high:
        return 0xFF22C55E; // Green-500
      case ConfidenceColor.medium:
        return 0xFFEAB308; // Yellow-500
      case ConfidenceColor.low:
        return 0xFFEF4444; // Red-500
    }
  }

  /// Get the background color value (for indicators)
  int get backgroundColor {
    switch (this) {
      case ConfidenceColor.high:
        return 0xFF22C55E; // Green-500
      case ConfidenceColor.medium:
        return 0xFFEAB308; // Yellow-500
      case ConfidenceColor.low:
        return 0xFFEF4444; // Red-500
    }
  }

  /// Get the light background color value (for subtle backgrounds)
  int get lightBackgroundColor {
    switch (this) {
      case ConfidenceColor.high:
        return 0x1A22C55E; // Green-500 with 10% opacity
      case ConfidenceColor.medium:
        return 0x1AEAB308; // Yellow-500 with 10% opacity
      case ConfidenceColor.low:
        return 0x1AEF4444; // Red-500 with 10% opacity
    }
  }
}
