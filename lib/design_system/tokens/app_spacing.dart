/// Spacing scale measured from the Figma frames (4-pt grid).
abstract final class AppSpacing {
  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
  static const double giant = 64;

  /// Horizontal page padding on shopping screens (440 − 400) / 2.
  static const double page = 20;

  /// Horizontal page padding on auth screens (440 − 365) / 2.
  static const double pageAuth = 37.5;
}
