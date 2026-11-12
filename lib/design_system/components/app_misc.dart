import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// "Categories ......... View All" row.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppTypography.subhead),
          ),
        ),
        if (trailing != null) trailing!,
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: AppTypography.callout.copyWith(color: AppColors.secondary),
            ),
          ),
      ],
    );
  }
}

/// Onboarding page indicator.
class AppPageDots extends StatelessWidget {
  const AppPageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppDurations.normal,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              width: AppDimensions.dot,
              height: AppDimensions.dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= index ? AppColors.secondary : AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

/// − 1 + stepper (Product detail, basket).
class AppQuantityStepper extends StatelessWidget {
  const AppQuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: 'Decrease quantity',
            filled: false,
            onTap: quantity > min ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: AppSpacing.xxxl,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTypography.caption1Medium,
              semanticsLabel: 'Quantity $quantity',
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: 'Increase quantity',
            filled: true,
            onTap: quantity < max ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.secondary : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: AppDimensions.socialButton,
            child: Icon(
              icon,
              size: AppDimensions.iconMd,
              color: filled ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular icon button with white fill (Product hero share/favourite).
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.textPrimary,
    this.background = AppColors.surface,
    this.size = AppDimensions.socialButton,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: AppDimensions.iconMd, color: color),
          ),
        ),
      ),
    );
  }
}

/// Constrains content to the design width on tablets / landscape.
class AppResponsiveCenter extends StatelessWidget {
  const AppResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppDimensions.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
