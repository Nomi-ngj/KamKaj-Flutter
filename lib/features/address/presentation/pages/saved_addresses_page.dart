import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/base/view_state_builder.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/address.dart';
import '../viewmodels/address_view_models.dart';
import '../widgets/address_card.dart';

class SavedAddressesPage extends ConsumerWidget {
  const SavedAddressesPage({super.key});

  Future<void> _confirmDefault(BuildContext context, WidgetRef ref, Address address) async {
    if (address.isDefault) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Set as Default?',
      message: 'Are you sure you want to set this as your primary delivery address?',
      icon: Icons.location_on_outlined,
    );
    if (!confirmed) return;
    final failure = await ref.read(addressesProvider.notifier).setDefault(address.id);
    if (failure != null && context.mounted) AppToast.show(context, failure.message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressesProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Saved Addresses'),
      body: ViewStateBuilder<List<Address>>(
        state: state,
        onRetry: ref.read(addressesProvider.notifier).load,
        emptyTitle: 'No saved addresses',
        emptyMessage: 'Drop a pin anywhere in the neighborhood.',
        emptyIcon: Icons.add_location_alt_outlined,
        builder: (context, addresses) => RefreshIndicator(
          onRefresh: ref.read(addressesProvider.notifier).load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xxl,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              for (final address in addresses) ...[
                AddressCard(
                  address: address,
                  onSelect: () => _confirmDefault(context, ref, address),
                  onEdit: () => context.pushNamed(
                    RouteNames.editAddress,
                    pathParameters: {RouteParams.addressId: address.id},
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SizedBox(height: AppSpacing.xxl),
              const _MapHint(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: AppButton(
            label: 'Add New Address',
            leadingIcon: Icons.add_rounded,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.large,
            onPressed: () => context.pushNamed(RouteNames.addAddress),
          ),
        ),
      ),
    );
  }
}

/// "Subtle map graphic" delight element under the list.
class _MapHint extends StatelessWidget {
  const _MapHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: AppColors.secondarySoft, shape: BoxShape.circle),
          child: SizedBox.square(
            dimension: AppDimensions.emptyIllustration,
            child: Icon(Icons.location_on_rounded, size: AppSpacing.huge, color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Drop a pin anywhere in the neighborhood.',
          textAlign: TextAlign.center,
          style: AppTypography.caption1.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
