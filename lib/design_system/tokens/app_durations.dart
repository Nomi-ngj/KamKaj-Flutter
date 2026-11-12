abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const splash = Duration(milliseconds: 1500);
  static const otpResend = Duration(seconds: 60);
  static const searchDebounce = Duration(milliseconds: 300);
}

/// Layout breakpoints (logical pixels).
abstract final class AppBreakpoints {
  static const double compact = 360;
  static const double medium = 600;
  static const double expanded = 840;
}
