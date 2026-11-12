import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppButtonVariant {
  /// Blue — Sign In, Sign Up, Submit, Verify, Update.
  primary,

  /// Orange — Continue, Get Started, Add to Cart, Place Order.
  secondary,

  /// Outlined, neutral.
  outline,

  /// Text only, e.g. "Cancel".
  text,
}

enum AppButtonSize { regular, large }

/// The single button used across the app. Handles loading & disabled states.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool expand;
  final String? semanticLabel;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    final height = size == AppButtonSize.large
        ? AppDimensions.buttonHeightLarge
        : AppDimensions.buttonHeight;
    final radius = size == AppButtonSize.large ? AppRadius.brMd : AppRadius.brSm;

    final content = isLoading
        ? SizedBox.square(
            dimension: AppDimensions.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: AppDimensions.iconMd, color: colors.foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.button.copyWith(color: colors.foreground),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailingIcon, size: AppDimensions.iconMd, color: colors.foreground),
              ],
            ],
          );

    final button = Semantics(
      button: true,
      enabled: _enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: colors.border == null ? BorderSide.none : BorderSide(color: colors.border!),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  _ButtonColors _colors() {
    if (!_enabled && !isLoading) {
      return variant == AppButtonVariant.text
          ? const _ButtonColors(Colors.transparent, AppColors.disabledText)
          : const _ButtonColors(AppColors.disabled, AppColors.white);
    }
    return switch (variant) {
      AppButtonVariant.primary => const _ButtonColors(AppColors.primary, AppColors.textOnPrimary),
      AppButtonVariant.secondary => const _ButtonColors(AppColors.secondary, AppColors.white),
      AppButtonVariant.outline =>
        const _ButtonColors(AppColors.surface, AppColors.textPrimary, AppColors.border),
      AppButtonVariant.text => const _ButtonColors(Colors.transparent, AppColors.primary),
    };
  }
}

class _ButtonColors {
  const _ButtonColors(this.background, this.foreground, [this.border]);

  final Color background;
  final Color foreground;
  final Color? border;
}
