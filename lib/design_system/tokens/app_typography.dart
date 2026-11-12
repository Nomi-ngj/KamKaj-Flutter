import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Text styles from the Figma text styles (Poppins, −2 % letter spacing).
abstract final class AppTypography {
  static const String fontFamily = 'Poppins';

  /// Figma letter spacing is −2 % of the font size.
  static double _tracking(double size) => size * -0.02;

  static TextStyle _style(double size, FontWeight weight, {double height = 1.4}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: _tracking(size),
        color: AppColors.textPrimary,
      );

  // Display / headings
  /// Figma "Header 2" — 24 / Bold.
  static final TextStyle header2 = _style(24, FontWeight.w700, height: 1.25);
  static final TextStyle header3 = _style(20, FontWeight.w700, height: 1.3);

  /// Figma "Subhead" — 17 / SemiBold.
  static final TextStyle subhead = _style(17, FontWeight.w600, height: 1.3);
  static final TextStyle titleMedium = _style(16, FontWeight.w600);
  static final TextStyle titleSmall = _style(14, FontWeight.w600);

  // Body
  /// Figma "Callout" — 16 / Regular.
  static final TextStyle callout = _style(16, FontWeight.w400, height: 1.5);

  /// Figma "Caption 1" — 14 / Regular.
  static final TextStyle caption1 = _style(14, FontWeight.w400, height: 1.5);

  /// Figma "Caption 1 Med" — 14 / Medium.
  static final TextStyle caption1Medium = _style(14, FontWeight.w500, height: 1.5);
  static final TextStyle caption2 = _style(12, FontWeight.w400);
  static final TextStyle caption2Medium = _style(12, FontWeight.w500);
  static final TextStyle caption2SemiBold = _style(12, FontWeight.w600);
  static final TextStyle caption3 = _style(11, FontWeight.w500);

  /// Figma "Caption 4 Med" — 10 / Medium.
  static final TextStyle caption4Medium = _style(10, FontWeight.w500);

  // Controls
  static final TextStyle button = _style(16, FontWeight.w600, height: 1.2);
  static final TextStyle buttonSmall = _style(13, FontWeight.w600, height: 1.2);
  static final TextStyle label = _style(12, FontWeight.w500, height: 1.2);
  static final TextStyle overline = _style(11, FontWeight.w600, height: 1.2);
}
