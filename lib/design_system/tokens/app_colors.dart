import 'package:flutter/painting.dart';

/// Colour tokens from the Figma variables (`PrimaryColor`, `SecondaryColor`,
/// `GaryColor`, …) plus semantic colours derived from them.
abstract final class AppColors {
  // Brand (Figma variables)
  static const primary = Color(0xFF205695);
  static const secondary = Color(0xFFF97316);
  static const gray = Color(0xFF555555);
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Brand tints
  static const primarySoft = Color(0xFFE8EFF8);
  static const primaryBorder = Color(0xFFC9D7EA);
  static const secondarySoft = Color(0xFFFFEDE0);

  // Backgrounds
  /// Peach background of onboarding & auth screens.
  static const backgroundWarm = Color(0xFFFFE4D6);

  /// Input fill on the warm background.
  static const inputFillWarm = Color(0xFFFFE8DC);

  /// Off-white background of shopping screens.
  static const background = Color(0xFFF8F7F5);
  static const surface = white;
  static const surfaceMuted = Color(0xFFF3F1EE);

  // Text
  static const textPrimary = Color(0xFF1B1B1F);
  static const textSecondary = gray;
  static const textTertiary = Color(0xFF8A8A8E);
  static const textOnPrimary = white;
  static const textAccent = secondary;

  // Lines
  static const border = Color(0xFFE6E3DF);
  static const divider = Color(0xFFEDEBE8);

  // Status
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFE7F6EC);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFFF7E6);
  static const warningBorder = Color(0xFFFDE68A);
  static const info = Color(0xFF0369A1);
  static const infoSoft = Color(0xFFF0F9FF);
  static const infoBorder = Color(0xFFBAE6FD);
  static const error = Color(0xFFE11D48);
  static const errorSoft = Color(0xFFFFF1F2);
  static const errorBorder = Color(0xFFFFE4E6);

  // States
  static const disabled = Color(0xFFBDBDBD);
  static const disabledText = Color(0xFF9E9E9E);
  static const overlay = Color(0x66000000);
  static const splashVeil = Color(0x99FFFFFF);
  static const scrim = Color(0x8A000000);
  static const imageGradientEnd = Color(0xB3000000);
  static const shadow = Color(0x1A000000);
  static const shadowSoft = Color(0x0D000000);

  // Category tile tints (Categories screen)
  static const tintRed = Color(0xFFFDECEC);
  static const tintGreen = Color(0xFFE5F1EC);
  static const tintYellow = Color(0xFFFFF5D6);
  static const tintBlue = Color(0xFFE6EEF8);
  static const tintPurple = Color(0xFFF0E9F7);
  static const tintRedIcon = Color(0xFFE0473E);
  static const tintGreenIcon = Color(0xFF2F7D5B);
  static const tintYellowIcon = Color(0xFFC99300);
  static const tintBlueIcon = primary;
  static const tintPurpleIcon = Color(0xFF7B4FA6);

  static const rating = Color(0xFFF59E0B);
  static const darkSurface = Color(0xFF111111);
}
