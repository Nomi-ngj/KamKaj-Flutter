import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Star + rating number, e.g. on store cards.
class AppRatingChip extends StatelessWidget {
  const AppRatingChip({super.key, required this.rating, this.onDark = false});

  final double rating;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rated ${rating.toStringAsFixed(1)} out of 5',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: onDark ? AppColors.overlay : AppColors.surface,
          borderRadius: AppRadius.brSm,
          border: onDark ? null : Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: AppDimensions.iconSm, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                rating.toStringAsFixed(1),
                style: AppTypography.caption2Medium.copyWith(
                  color: onDark ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable pill (Store detail menu tabs, address "Save as").
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.secondary : AppColors.surfaceMuted,
        borderRadius: AppRadius.brPill,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppDimensions.iconSm, color: foreground),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label, style: AppTypography.caption1Medium.copyWith(color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small coloured label with optional leading icon (e.g. "Breads & Pastries").
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.secondary,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppDimensions.iconXs, color: color),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption2Medium.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Rounded status badge (Pending / Cancelled / Default …).
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.borderColor,
    this.showDot = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color? borderColor;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brPill,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              DecoratedBox(
                decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: AppDimensions.dot),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(label, style: AppTypography.caption2SemiBold.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}
