/// Helpers for Laravel JSON envelopes (`{ data: ... }`) and flexible id/enum parsing.
abstract final class JsonHelpers {
  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('Expected JSON object, got ${value.runtimeType}');
  }

  static List<dynamic> asList(Object? value) {
    if (value is List) return value;
    throw FormatException('Expected JSON array, got ${value.runtimeType}');
  }

  /// Unwraps `{ "data": T }` or returns [raw] when already unwrapped.
  static Object? unwrapData(Object? raw) {
    if (raw is Map) {
      final map = asMap(raw);
      if (map.containsKey('data')) return map['data'];
    }
    return raw;
  }

  static Map<String, dynamic> unwrapDataMap(Object? raw) =>
      asMap(unwrapData(raw));

  static List<dynamic> unwrapDataList(Object? raw) {
    final data = unwrapData(raw);
    if (data is List) return data;
    // Laravel Resource::collection sometimes nests again.
    if (data is Map && data['data'] is List) return data['data'] as List;
    throw FormatException('Expected data list, got ${data.runtimeType}');
  }

  static String id(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? optionalId(Object? value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  static double asDouble(Object? value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static int asInt(Object? value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool asBool(Object? value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return fallback;
  }

  static DateTime? asDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String? asString(Object? value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  /// Reads camelCase or snake_case keys.
  static Object? pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) return json[key];
    }
    return null;
  }
}
