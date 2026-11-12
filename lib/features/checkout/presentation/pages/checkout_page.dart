import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../design_system/assets/app_images.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../domain/entities/checkout_entities.dart';
import '../viewmodels/checkout_view_model.dart';
import '../widgets/checkout_widgets.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final order = await ref.read(checkoutViewModelProvider.notifier).placeOrder();
    if (!context.mounted) return;
    if (order == null) {
      final message = ref.read(checkoutViewModelProvider).submit.errorMessage;
      if (message != null) AppToast.show(context, message);
      return;
    }
    AppToast.show(context, 'Order #${order.number} placed!');
    context.goNamed(RouteNames.orders);
  }

  Future<void> _choosePayment(BuildContext context, WidgetRef ref, CheckoutState state) async {
    final methods = state.paymentMethods.dataOrNull ?? const <PaymentMethod>[];
    if (methods.isEmpty) {
      await ref.read(checkoutViewModelProvider.notifier).retryPaymentMethods();
      return;
    }
    final selected = await AppBottomSheet.show<String>(
      context,
      builder: (sheetContext) => PaymentMethodSheet(
        methods: methods,
        selectedId: state.selectedPayment?.id,
      ),
    );
    if (selected != null) ref.read(checkoutViewModelProvider.notifier).selectPayment(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutViewModelProvider);
    final viewModel = ref.read(checkoutViewModelProvider.notifier);

    if (state.cart.isEmpty && !state.submit.isSuccess) {
      return Scaffold(
        appBar: const AppAppBar(title: 'Checkout'),
        body: AppEmptyView(
          icon: Icons.shopping_basket_outlined,
          title: 'Your basket is empty',
          message: 'Add something delicious from a local store.',
          actionLabel: 'Browse stores',
          onAction: () => context.goNamed(RouteNames.home),
        ),
      );
    }

    final address = state.address;
    return Scaffold(
      appBar: AppAppBar(
        title: 'Checkout',
        actions: [
          AppMoreButton(onPressed: () => AppToast.show(context, 'Need help? Contact Support')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        children: [
          const SizedBox(height: AppSpacing.sm),
          const CheckoutStepper(currentStep: 2, totalSteps: 3),
          const SizedBox(height: AppSpacing.xxl),
          AppSectionHeader(
            title: 'Delivery Address',
            trailing: TextButton.icon(
              onPressed: () => context.pushNamed(RouteNames.addresses),
              style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
              icon: const Icon(Icons.edit_outlined, size: AppDimensions.iconSm),
              label: Text(
                address == null ? 'Add' : 'Edit',
                style: AppTypography.caption1Medium.copyWith(color: AppColors.secondary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AddressPreview(
            title: address?.streetLine ?? 'No delivery address yet',
            subtitle: address?.driverNotes ?? address?.city ?? 'Tap Add to choose one',
          ),
          const SizedBox(height: AppSpacing.xxl),
          StoreSummaryRow(storeName: state.cart.storeName ?? ''),
          const SizedBox(height: AppSpacing.lg),
          for (final item in state.cart.items) ...[
            CartItemRow(
              item: item,
              onTap: () => AppBottomSheet.show<void>(
                context,
                builder: (_) => _QuantitySheet(item: item, onChanged: viewModel.setQuantity),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text('Payment Method', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.md),
          PaymentMethodTile(
            method: state.selectedPayment,
            isLoading: state.paymentMethods.isLoading,
            onTap: () => _choosePayment(context, ref, state),
          ),
          const SizedBox(height: AppSpacing.xxl),
          OrderSummaryCard(summary: state.summary),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: AppButton(
            label: 'Place Order',
            trailingIcon: Icons.arrow_forward_rounded,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.large,
            isLoading: state.submit.isSubmitting,
            onPressed: state.canPlaceOrder ? () => _placeOrder(context, ref) : null,
          ),
        ),
      ),
    );
  }
}

class _AddressPreview extends StatelessWidget {
  const _AddressPreview({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.checkoutMapHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AppAssetImage(
            path: AppImages.mapPlaceholder,
            fit: BoxFit.cover,
            borderRadius: AppRadius.brMd,
            semanticLabel: 'Map of the delivery address',
            placeholderIcon: Icons.map_outlined,
          ),
          PositionedDirectional(
            start: AppSpacing.md,
            bottom: AppSpacing.md,
            end: AppSpacing.giant,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: AppRadius.brSm,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: AppSpacing.md,
                    backgroundColor: AppColors.secondary,
                    child: Icon(
                      Icons.location_on_outlined,
                      size: AppDimensions.iconSm,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption1Medium,
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({required this.item, required this.onChanged});

  final CartItem item;
  final void Function(String productId, int quantity) onChanged;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late int _quantity = widget.item.quantity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.item.product.name, style: AppTypography.subhead),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: Text('Quantity', style: AppTypography.titleSmall)),
              AppQuantityStepper(
                quantity: _quantity,
                max: Cart.maxQuantityPerItem,
                onChanged: (q) => setState(() => _quantity = q),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: 'Update',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              widget.onChanged(widget.item.product.id, _quantity);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Remove from basket',
            variant: AppButtonVariant.text,
            onPressed: () {
              widget.onChanged(widget.item.product.id, 0);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
