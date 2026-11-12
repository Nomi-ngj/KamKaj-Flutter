import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Material theme built only from design tokens.
ThemeData buildLightTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.secondarySoft,
    onSecondaryContainer: AppColors.secondary,
    error: AppColors.error,
    onError: AppColors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
  );

  final textTheme = TextTheme(
    headlineMedium: AppTypography.header2,
    headlineSmall: AppTypography.header3,
    titleLarge: AppTypography.subhead,
    titleMedium: AppTypography.titleMedium,
    titleSmall: AppTypography.titleSmall,
    bodyLarge: AppTypography.callout,
    bodyMedium: AppTypography.caption1,
    bodySmall: AppTypography.caption2,
    labelLarge: AppTypography.button,
    labelMedium: AppTypography.label,
    labelSmall: AppTypography.caption4Medium,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: AppTypography.fontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.subhead,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: AppDimensions.dividerThickness,
      space: AppSpacing.lg,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: AppTypography.caption1.copyWith(color: AppColors.white),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      titleTextStyle: AppTypography.subhead,
      contentTextStyle: AppTypography.caption1.copyWith(color: AppColors.textSecondary),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
  );
}
