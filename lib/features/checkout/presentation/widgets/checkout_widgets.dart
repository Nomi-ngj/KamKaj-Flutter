import 'package:flutter/material.dart';

import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../domain/entities/checkout_entities.dart';

/// ● — ○ — ○  STEP 2 OF 3
class CheckoutStepper extends StatelessWidget {
  const CheckoutStepper({super.key, required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  static const _icons = [
    Icons.shopping_bag_outlined,
    Icons.payments_outlined,
    Icons.check_circle_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $currentStep of $totalSteps',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < totalSteps; i++) ...[
            if (i > 0)
              SizedBox(
                width: AppSpacing.xxl,
                child: Divider(
                  thickness: 2,
                  color: i < currentStep ? AppColors.secondary : AppColors.border,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: CircleAvatar(
                radius: AppSpacing.md + AppSpacing.xxs,
                backgroundColor: i == 0 ? AppColors.secondary : AppColors.surfaceMuted,
                child: Icon(
                  _icons[i % _icons.length],
                  size: AppDimensions.iconSm,
                  color: i == 0 ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            'STEP $currentStep OF $totalSteps',
            style: AppTypography.caption1Medium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class StoreSummaryRow extends StatelessWidget {
  const StoreSummaryRow({super.key, required this.storeName});

  final String storeName;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.tintGreen,
      borderRadius: AppRadius.brMd,
      padding: const EdgeInsets.all(AppSpacing.md),
      shadows: const [],
      child: Row(
        children: [
          const AppNetworkImage(
            url: null,
            width: AppDimensions.iconBoxLarge,
            height: AppDimensions.iconBoxLarge,
            borderRadius: AppRadius.brSm,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(storeName, style: AppTypography.titleSmall),
                Text(
                  'Est. 30-45 mins • Local Favorite',
                  style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartItemRow extends StatelessWidget {
  const CartItemRow({super.key, required this.item, required this.onTap});

  final CartItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Badge(
            isLabelVisible: item.quantity > 1,
            label: Text('${item.quantity}'),
            backgroundColor: AppColors.error,
            alignment: AlignmentDirectional.topStart,
            child: AppNetworkImage(
              url: product.imageUrl,
              width: AppDimensions.checkoutThumb,
              height: AppDimensions.checkoutThumb,
              borderRadius: AppRadius.brSm,
              semanticLabel: product.name,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTypography.caption1Medium),
                if (product.shortDescription != null || item.note != null)
                  Text(
                    item.note ?? product.shortDescription!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Text(item.total.format(), style: AppTypography.caption2SemiBold),
        ],
      ),
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.isLoading,
    required this.onTap,
  });

  final PaymentMethod? method;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = method;
    return AppCard(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      color: AppColors.surfaceMuted,
      shadows: const [],
      border: Border.all(color: AppColors.border),
      child: Row(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.brXs),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Icon(Icons.credit_card_rounded, color: AppColors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: isLoading
                ? const LinearProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current?.title ?? 'Add a payment method',
                        style: AppTypography.caption1Medium,
                      ),
                      if (current != null)
                        Text(
                          'Expires ${current.expiry}',
                          style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

class PaymentMethodSheet extends StatelessWidget {
  const PaymentMethodSheet({super.key, required this.methods, required this.selectedId});

  final List<PaymentMethod> methods;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final method in methods)
            ListTile(
              leading: const Icon(Icons.credit_card_rounded),
              title: Text(method.title, style: AppTypography.caption1Medium),
              subtitle: Text('Expires ${method.expiry}', style: AppTypography.caption2),
              trailing: method.id == selectedId
                  ? const Icon(Icons.check_rounded, color: AppColors.secondary)
                  : null,
              onTap: () => Navigator.of(context).pop(method.id),
            ),
        ],
      ),
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.summary});

  final CheckoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final label = AppTypography.caption1.copyWith(color: AppColors.textSecondary);
    return AppCard(
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: summary.subtotal.format(), labelStyle: AppTypography.caption1),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(
            label: 'Delivery Fee',
            value: summary.isFreeDelivery ? 'FREE' : summary.deliveryFee.format(),
            labelStyle: label,
            info: 'Free delivery on orders over PKR 1,000',
          ),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(label: 'Service Fee', value: summary.serviceFee.format(), labelStyle: label),
          const Divider(height: AppSpacing.xxl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL TO PAY',
                      style: AppTypography.overline.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(summary.total.format(), style: AppTypography.titleSmall),
                  ],
                ),
              ),
              const Icon(Icons.eco_outlined, size: AppDimensions.iconSm, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text('Supporting Local', style: AppTypography.caption2.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    this.info,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final String? info;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: labelStyle),
        if (info != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Tooltip(
            message: info,
            triggerMode: TooltipTriggerMode.tap,
            child: const Icon(
              Icons.info_outline_rounded,
              size: AppDimensions.iconXs,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const Spacer(),
        Text(value, style: AppTypography.caption1.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
