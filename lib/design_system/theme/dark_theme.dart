import 'package:flutter/material.dart';

import 'light_theme.dart';

/// The Figma design defines a light theme only (see FIGMA_ANALYSIS.md §7).
/// Dark mode intentionally mirrors the light theme until a dark palette is designed.
ThemeData buildDarkTheme() => buildLightTheme();
