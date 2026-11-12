import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Thin logging facade. Logs only in debug/profile builds and never
/// receives tokens, passwords or personal data (callers must redact).
abstract final class AppLogger {
  static void debug(String message, {String tag = 'App'}) {
    if (kReleaseMode) return;
    developer.log(message, name: tag);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String tag = 'App',
  }) {
    if (kReleaseMode) {
      // Hook a crash reporter (Crashlytics/Sentry) here.
      return;
    }
    developer.log(
      message,
      name: tag,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
