import '../exceptions/app_exception.dart';

/// Type-safe accessors for decoded JSON. Throw [ParsingException] on bad data
/// so malformed API responses never crash the UI with a cast error.
extension JsonReader on Map<String, Object?> {
  String readString(String key) {
    final value = this[key];
    if (value is String) return value;
    if (value is num) return value.toString();
    throw ParsingException('Missing string "$key"');
  }

  String? readStringOrNull(String key) {
    final value = this[key];
    return value is String ? value : null;
  }

  int readInt(String key, {int? fallback}) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (fallback != null) return fallback;
    throw ParsingException('Missing int "$key"');
  }

  double readDouble(String key, {double? fallback}) {
    final value = this[key];
    if (value is num) return value.toDouble();
    if (fallback != null) return fallback;
    throw ParsingException('Missing double "$key"');
  }

  bool readBool(String key, {bool fallback = false}) {
    final value = this[key];
    return value is bool ? value : fallback;
  }

  DateTime? readDateOrNull(String key) {
    final value = this[key];
    return value is String ? DateTime.tryParse(value) : null;
  }

  List<Map<String, Object?>> readObjectList(String key) {
    final value = this[key];
    if (value is! List<Object?>) return const [];
    return value.whereType<Map<String, Object?>>().toList(growable: false);
  }

  List<String> readStringList(String key) {
    final value = this[key];
    if (value is! List<Object?>) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}
