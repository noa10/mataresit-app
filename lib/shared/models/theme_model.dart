import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Theme mode options
enum ThemeMode {
  light('light', 'Light'),
  dark('dark', 'Dark'),
  auto('auto', 'Auto');

  const ThemeMode(this.value, this.displayName);

  final String value;
  final String displayName;

  static ThemeMode fromString(String value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ThemeMode.auto,
    );
  }
}

/// Theme variant options
enum ThemeVariant {
  defaultTheme('default', 'Default', 'Clean and professional default theme'),
  ocean('ocean', 'Ocean', 'Cool blues and teals inspired by the ocean'),
  forest('forest', 'Forest', 'Natural greens and earth tones'),
  sunset('sunset', 'Sunset', 'Warm oranges and golden hues');

  const ThemeVariant(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  static ThemeVariant fromString(String value) {
    return ThemeVariant.values.firstWhere(
      (variant) => variant.value == value,
      orElse: () => ThemeVariant.defaultTheme,
    );
  }
}

/// Theme configuration model
class ThemeConfig extends Equatable {
  final ThemeMode mode;
  final ThemeVariant variant;

  const ThemeConfig({required this.mode, required this.variant});

  /// Default theme configuration
  static const ThemeConfig defaultConfig = ThemeConfig(
    mode: ThemeMode.auto,
    variant: ThemeVariant.defaultTheme,
  );

  /// Create a copy with updated values
  ThemeConfig copyWith({ThemeMode? mode, ThemeVariant? variant}) {
    return ThemeConfig(
      mode: mode ?? this.mode,
      variant: variant ?? this.variant,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {'mode': mode.value, 'variant': variant.value};
  }

  /// Create from JSON
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      mode: ThemeMode.fromString(json['mode'] ?? 'auto'),
      variant: ThemeVariant.fromString(json['variant'] ?? 'default'),
    );
  }

  @override
  List<Object?> get props => [mode, variant];
}

/// Theme variant preview colors
class ThemeVariantPreview {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  const ThemeVariantPreview({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });
}

/// Theme variant definitions with preview colors
class ThemeVariantDefinition {
  final ThemeVariant variant;
  final ThemeVariantPreview preview;
  final Color seedColor;

  const ThemeVariantDefinition({
    required this.variant,
    required this.preview,
    required this.seedColor,
  });

  static const Map<ThemeVariant, ThemeVariantDefinition> definitions = {
    ThemeVariant.defaultTheme: ThemeVariantDefinition(
      variant: ThemeVariant.defaultTheme,
      seedColor: Color(0xFF2563EB), // Blue primary color
      preview: ThemeVariantPreview(
        primaryColor: Color(0xFF1E293B), // Dark blue-gray
        secondaryColor: Color(0xFFF1F5F9), // Light gray
        accentColor: Color(0xFFF1F5F9), // Light gray
      ),
    ),
    ThemeVariant.ocean: ThemeVariantDefinition(
      variant: ThemeVariant.ocean,
      seedColor: Color(0xFF0077BE), // Deep blue
      preview: ThemeVariantPreview(
        primaryColor: Color(0xFF0077BE), // Deep blue
        secondaryColor: Color(0xFFE0F2FE), // Light blue-gray
        accentColor: Color(0xFFBAE6FD), // Light cyan
      ),
    ),
    ThemeVariant.forest: ThemeVariantDefinition(
      variant: ThemeVariant.forest,
      seedColor: Color(0xFF16A34A), // Green
      preview: ThemeVariantPreview(
        primaryColor: Color(0xFF15803D), // Dark green
        secondaryColor: Color(0xFFF0FDF4), // Light green-gray
        accentColor: Color(0xFFBBF7D0), // Light lime
      ),
    ),
    ThemeVariant.sunset: ThemeVariantDefinition(
      variant: ThemeVariant.sunset,
      seedColor: Color(0xFFEA580C), // Orange
      preview: ThemeVariantPreview(
        primaryColor: Color(0xFFEA580C), // Orange-red
        secondaryColor: Color(0xFFFFF7ED), // Light orange
        accentColor: Color(0xFFFED7AA), // Light yellow
      ),
    ),
  };

  static ThemeVariantDefinition getDefinition(ThemeVariant variant) {
    return definitions[variant] ?? definitions[ThemeVariant.defaultTheme]!;
  }
}
