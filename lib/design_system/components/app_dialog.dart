import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'app_button.dart';

/// Confirmation dialog ("Set as Default?"). Resolves to `true` on confirm.
abstract final class AppDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xxl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.secondarySoft,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: AppDimensions.iconBoxLarge,
                  child: Icon(icon, color: AppColors.secondary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppTypography.subhead, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.caption1.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: confirmLabel,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: cancelLabel,
                variant: AppButtonVariant.text,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}

/// Modal bottom sheet with the app's shape and safe-area handling.
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: builder(sheetContext),
      ),
    );
  }
}

/// Snackbar helper so screens don't build SnackBars by hand.
abstract final class AppToast {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
