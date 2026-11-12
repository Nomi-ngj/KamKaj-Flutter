import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../viewmodels/cart_view_model.dart';

/// Floating "View your basket" bar (Store Detail).
class BasketBar extends ConsumerWidget {
  const BasketBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final enabled = !cart.isEmpty;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'View your basket, ${cart.itemCount} items, ${cart.subtotal.formatFixed()}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.brMd,
        elevation: 0,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: enabled ? () => context.pushNamed(RouteNames.checkout) : null,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: AppRadius.brMd,
              boxShadow: AppShadows.floating,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Badge(
                    label: Text('${cart.itemCount}'),
                    backgroundColor: AppColors.secondary,
                    child: const Icon(Icons.shopping_basket_outlined, color: AppColors.white),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View your basket',
                          style: AppTypography.caption1Medium.copyWith(color: AppColors.white),
                        ),
                        Text(
                          cart.subtotal.formatFixed(),
                          style: AppTypography.caption2.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
