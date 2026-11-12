import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'app_button.dart';

/// Centered progress indicator.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.color = AppColors.primary});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Loading',
        child: CircularProgressIndicator(color: color),
      ),
    );
  }
}

/// Full-area error message with a retry action.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconColor: AppColors.error,
      title: 'Something went wrong',
      message: message,
      action: onRetry == null
          ? null
          : AppButton(label: 'Try again', onPressed: onRetry, expand: false),
    );
  }
}

/// Full-area empty state.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconColor: AppColors.textTertiary,
      title: title,
      message: message,
      action: actionLabel == null || onAction == null
          ? null
          : AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.secondary,
              expand: false,
            ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimensions.massiveIcon, color: iconColor),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.subhead, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.caption1.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
