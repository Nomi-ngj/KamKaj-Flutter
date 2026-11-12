import 'package:flutter/material.dart';

import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/address.dart';

IconData addressTypeIcon(AddressType type) => switch (type) {
      AddressType.home => Icons.home_rounded,
      AddressType.work => Icons.work_rounded,
      AddressType.other => Icons.location_on_rounded,
    };

/// Saved address card: type icon, label + Default badge, lines, radio & edit.
class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.onSelect,
    required this.onEdit,
  });

  final Address address;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final selected = address.isDefault;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onSelect,
      border: Border.all(color: selected ? AppColors.secondary : AppColors.border),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent line marks the default address.
            SizedBox(
              width: AppDimensions.accentLine,
              child: ColoredBox(color: selected ? AppColors.secondary : AppColors.surface),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected ? AppColors.secondarySoft : AppColors.surfaceMuted,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: SizedBox.square(
                        dimension: AppDimensions.iconBoxLarge,
                        child: Icon(
                          addressTypeIcon(address.type),
                          color: selected ? AppColors.secondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(address.label, style: AppTypography.titleSmall),
                              if (selected)
                                const AppStatusBadge(
                                  label: 'Default',
                                  foreground: AppColors.secondary,
                                  background: AppColors.secondarySoft,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(address.streetLine, style: AppTypography.caption1),
                          Text(
                            address.city,
                            style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Semantics(
                          label: selected ? 'Default address' : 'Set as default',
                          selected: selected,
                          child: Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected ? AppColors.secondary : AppColors.textTertiary,
                            size: AppDimensions.iconMd,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppCircleIconButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit address',
                          size: AppDimensions.iconBox,
                          background: AppColors.surfaceMuted,
                          onPressed: onEdit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
