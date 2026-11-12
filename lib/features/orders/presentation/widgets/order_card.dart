import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/order.dart';

typedef _StatusStyle = ({
  String label,
  IconData icon,
  Color foreground,
  Color background,
  Color border,
});

_StatusStyle _styleFor(OrderStatus status) => switch (status) {
      OrderStatus.awaitingPayment => (
          label: 'Awaiting payment',
          icon: Icons.bolt_rounded,
          foreground: AppColors.warning,
          background: AppColors.warningSoft,
          border: AppColors.warningBorder,
        ),
      OrderStatus.pending => (
          label: 'Pending',
          icon: Icons.local_shipping_outlined,
          foreground: AppColors.info,
          background: AppColors.infoSoft,
          border: AppColors.infoBorder,
        ),
      OrderStatus.inTransit => (
          label: 'In transit',
          icon: Icons.local_shipping_outlined,
          foreground: AppColors.primary,
          background: AppColors.primarySoft,
          border: AppColors.primaryBorder,
        ),
      OrderStatus.delivered => (
          label: 'Delivered',
          icon: Icons.check_circle_outline_rounded,
          foreground: AppColors.success,
          background: AppColors.successSoft,
          border: AppColors.successSoft,
        ),
      OrderStatus.cancelled => (
          label: 'Cancelled',
          icon: Icons.close_rounded,
          foreground: AppColors.error,
          background: AppColors.errorSoft,
          border: AppColors.errorBorder,
        ),
    };

/// My Orders card. Shows payment / tracking / re-order actions by status.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.isBusy,
    required this.onTap,
    required this.onPay,
    required this.onTrack,
    required this.onReorder,
  });

  final Order order;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback onTrack;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(order.status);
    final muted = order.status == OrderStatus.cancelled;

    final card = AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      border: Border.all(
        color: order.canPay ? AppColors.warningBorder : AppColors.border,
        width: order.canPay ? 2 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(order: order, style: style, muted: muted),
                const SizedBox(height: AppSpacing.md),
                _Route(from: order.from, to: order.to, muted: muted),
                ..._actions(),
              ],
            ),
          ),
          _Footer(order: order, muted: muted),
        ],
      ),
    );
    return muted ? Opacity(opacity: 0.9, child: card) : card;
  }

  List<Widget> _actions() {
    if (order.canPay) {
      return [
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.warningBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Payment required to release vehicle',
                    style: AppTypography.caption2Medium.copyWith(color: AppColors.warning),
                  ),
                ),
                Text(
                  order.amountDue!.formatFixed(),
                  style: AppTypography.caption2SemiBold.copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Pay Now & Confirm Dispatch',
          leadingIcon: Icons.credit_card_rounded,
          isLoading: isBusy,
          onPressed: onPay,
        ),
      ];
    }
    if (order.canTrack) {
      return [
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                order.courierInfo!,
                style: AppTypography.caption3.copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton.icon(
              onPressed: onTrack,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primarySoft,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
              ),
              icon: const Icon(Icons.location_on_outlined, size: AppDimensions.iconXs),
              label: Text(
                'Track Live',
                style: AppTypography.caption2SemiBold.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ];
    }
    if (order.status == OrderStatus.cancelled) {
      return [
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                order.cancelReason ?? 'Cancelled',
                style: AppTypography.caption3.copyWith(color: AppColors.textTertiary),
              ),
            ),
            if (isBusy)
              const SizedBox.square(
                dimension: AppDimensions.iconMd,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: onReorder,
                child: Text(
                  'Re-order Shipment',
                  style: AppTypography.caption2SemiBold.copyWith(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ];
    }
    return const [];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order, required this.style, required this.muted});

  final Order order;
  final _StatusStyle style;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: AppRadius.brSm,
            border: Border.all(color: style.border),
          ),
          child: SizedBox.square(
            dimension: AppDimensions.iconBox,
            child: Icon(style.icon, size: AppDimensions.iconSm, color: style.foreground),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.title,
                style: AppTypography.titleSmall.copyWith(
                  color: muted ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
              if (order.subtitle != null)
                Text(
                  order.subtitle!,
                  style: AppTypography.caption3.copyWith(color: AppColors.success),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('Status', style: AppTypography.caption3.copyWith(color: AppColors.textTertiary)),
        const SizedBox(width: AppSpacing.xs),
        AppStatusBadge(
          label: style.label,
          foreground: style.foreground,
          background: style.background,
          borderColor: style.border,
          showDot: order.status == OrderStatus.awaitingPayment,
        ),
        const Icon(Icons.chevron_right_rounded, size: AppDimensions.iconSm, color: AppColors.textTertiary),
      ],
    );
  }
}

class _Route extends StatelessWidget {
  const _Route({required this.from, required this.to, required this.muted});

  final String from;
  final String to;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final start = muted ? AppColors.textTertiary : AppColors.primary;
    final end = muted ? AppColors.textTertiary : AppColors.textPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  width: AppSpacing.md - AppSpacing.xxs,
                  height: AppSpacing.md - AppSpacing.xxs,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: start, width: 2),
                  ),
                ),
                Container(
                  width: AppSpacing.xxs,
                  height: AppSpacing.md,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  color: AppColors.border,
                ),
                Container(
                  width: AppSpacing.md - AppSpacing.xxs,
                  height: AppSpacing.md - AppSpacing.xxs,
                  decoration: BoxDecoration(color: end, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteLine(label: 'From', value: from, muted: muted),
                  const SizedBox(height: AppSpacing.sm),
                  _RouteLine(label: 'To', value: to, muted: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.label, required this.value, required this.muted});

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.caption2SemiBold.copyWith(
            color: muted ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.order, required this.muted});

  final Order order;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final label = AppTypography.caption3.copyWith(color: AppColors.textTertiary);
    final value = AppTypography.caption3.copyWith(
      color: muted ? AppColors.textSecondary : AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: AppDimensions.iconXs, color: AppColors.textTertiary),
            const SizedBox(width: AppSpacing.xs),
            Text.rich(
              TextSpan(
                style: label,
                children: [const TextSpan(text: 'Order '), TextSpan(text: '#${order.number}', style: value)],
              ),
            ),
            const Spacer(),
            const Icon(Icons.calendar_today_outlined, size: AppDimensions.iconXs, color: AppColors.textTertiary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text.rich(
                TextSpan(
                  style: label,
                  children: [
                    TextSpan(text: order.status.isActive ? 'Est. Delivery: ' : 'Delivery Date: '),
                    TextSpan(text: DateFormatter.long(order.deliveryDate), style: value),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
