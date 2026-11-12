import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

abstract final class AppTheme {
  static final ThemeData light = buildLightTheme();
  static final ThemeData dark = buildDarkTheme();
}
