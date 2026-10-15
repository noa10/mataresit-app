/// Defensive coercion helpers for the gamification payloads.
///
/// The gamification backend is heterogeneous: table rows are snake_case while
/// the nested `mission` payload of `get_gamification_missions` is camelCase,
/// numeric columns arrive as `int`, `double` or `String` depending on the
/// Postgres type, and dates can be either `date` or `timestamptz`. These
/// helpers keep that messiness out of the models.
class GamificationJson {
  const GamificationJson._();

  /// Reads [key] (camelCase) from [map], falling back to its snake_case form.
  ///
  /// Returns `null` when neither spelling is present.
  static dynamic pick(Map<String, dynamic> map, String key) {
    if (map.containsKey(key)) return map[key];
    final snake = camelToSnake(key);
    if (map.containsKey(snake)) return map[snake];
    return null;
  }

  /// `missionType` -> `mission_type`, `rewardXp` -> `reward_xp`.
  static String camelToSnake(String key) {
    final buffer = StringBuffer();
    for (var i = 0; i < key.length; i++) {
      final char = key[i];
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpper) {
        buffer.write('_');
        buffer.write(char.toLowerCase());
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String? asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static String stringOr(dynamic value, [String fallback = '']) =>
      asString(value) ?? fallback;

  static int asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
    }
    return fallback;
  }

  static double asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'true':
        case 't':
        case '1':
        case 'yes':
          return true;
        case 'false':
        case 'f':
        case '0':
        case 'no':
          return false;
      }
    }
    return fallback;
  }

  /// Parses a `date` (`2026-10-15`) or `timestamptz` value.
  static DateTime? asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return DateTime.tryParse(trimmed);
    }
    return null;
  }

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static List<String> asStringList(dynamic value) {
    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => item.toString())
          .toList();
    }
    return const <String>[];
  }

  /// Coerces a PostgREST/RPC array payload into a list of row maps.
  ///
  /// A `null` payload becomes an empty list; anything that is not a list is a
  /// contract violation and throws so the UI can surface it instead of silently
  /// rendering an empty state.
  static List<Map<String, dynamic>> asRows(
    dynamic value, {
    required String source,
  }) {
    if (value == null) return const <Map<String, dynamic>>[];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    throw FormatException(
      'Unexpected payload for $source: ${value.runtimeType}',
    );
  }

  /// Coerces an RPC result into a single row map.
  ///
  /// A composite (single-row) RPC result decodes to a map, but some client
  /// versions wrap it in a one-element list, so both shapes are accepted.
  static Map<String, dynamic>? asSingleRow(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }
}
