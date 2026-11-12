import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/view_state_builder.dart';
import '../../../../core/errors/failure.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/order.dart';
import '../viewmodels/orders_view_model.dart';
import '../widgets/order_card.dart';
import '../widgets/order_tracking_sheet.dart';

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  Future<void> _handle(BuildContext context, Future<Failure?> action, String success) async {
    final failure = await action;
    if (!context.mounted) return;
    AppToast.show(context, failure?.message ?? success);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersViewModelProvider);
    final viewModel = ref.read(ordersViewModelProvider.notifier);

    return Scaffold(
      appBar: AppAppBar(
        title: 'My Orders',
        showBack: false,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: viewModel.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            child: _ScopeTabs(
              selected: state.scope,
              currentCount: state.countOf(OrderScope.current),
              pastCount: state.countOf(OrderScope.past),
              onChanged: viewModel.selectScope,
            ),
          ),
          Expanded(
            child: ViewStateBuilder<List<Order>>(
              state: state.visible,
              onRetry: viewModel.retry,
              emptyTitle: state.scope == OrderScope.current ? 'No current orders' : 'No past orders',
              emptyMessage: 'Your orders will show up here.',
              emptyIcon: Icons.receipt_long_outlined,
              builder: (context, orders) => RefreshIndicator(
                onRefresh: viewModel.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (_, i) {
                    final order = orders[i];
                    return OrderCard(
                      order: order,
                      isBusy: state.busyOrderId == order.id,
                      onTap: () => OrderTrackingSheet.show(context, order),
                      onTrack: () => OrderTrackingSheet.show(context, order),
                      onPay: () => _handle(context, viewModel.pay(order), 'Payment received. Dispatch confirmed!'),
                      onReorder: () => _handle(context, viewModel.reorder(order), 'Shipment re-ordered'),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({
    required this.selected,
    required this.currentCount,
    required this.pastCount,
    required this.onChanged,
  });

  final OrderScope selected;
  final int currentCount;
  final int pastCount;
  final ValueChanged<OrderScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: _Tab(
                label: 'Current Orders',
                count: currentCount,
                selected: selected == OrderScope.current,
                onTap: () => onChanged(OrderScope.current),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Tab(
                label: 'Past Orders',
                count: pastCount,
                selected: selected == OrderScope.past,
                onTap: () => onChanged(OrderScope.past),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '$label, $count',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xxs),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: selected ? AppColors.primaryBorder : Colors.transparent),
            boxShadow: selected ? AppShadows.field : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption1Medium.copyWith(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(
                label: '$count',
                foreground: selected ? AppColors.primary : AppColors.textSecondary,
                background: selected ? AppColors.primarySoft : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
