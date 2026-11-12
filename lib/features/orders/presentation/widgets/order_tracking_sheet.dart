import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/order.dart';

/// Order status timeline shown when an order is tapped or "Track Live" is used.
class OrderTrackingSheet extends StatelessWidget {
  const OrderTrackingSheet({super.key, required this.order});

  final Order order;

  static Future<void> show(BuildContext context, Order order) =>
      AppBottomSheet.show<void>(context, builder: (_) => OrderTrackingSheet(order: order));

  static const _steps = [
    (status: OrderStatus.awaitingPayment, label: 'Order placed'),
    (status: OrderStatus.pending, label: 'Rider assigned'),
    (status: OrderStatus.inTransit, label: 'On the way'),
    (status: OrderStatus.delivered, label: 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == OrderStatus.cancelled;
    final reached = cancelled ? 0 : _steps.indexWhere((s) => s.status == order.status);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.number}', style: AppTypography.subhead),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${order.from} → ${order.to}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (cancelled)
              Text(
                order.cancelReason ?? 'This order was cancelled.',
                style: AppTypography.caption1.copyWith(color: AppColors.error),
              )
            else
              for (var i = 0; i < _steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        i <= reached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: i <= reached ? AppColors.secondary : AppColors.textTertiary,
                        size: AppDimensions.iconMd,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _steps[i].label,
                        style: i <= reached ? AppTypography.caption1Medium : AppTypography.caption1,
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${order.status.isActive ? 'Estimated delivery' : 'Delivered on'}: '
              '${DateFormatter.long(order.deliveryDate)}',
              style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
