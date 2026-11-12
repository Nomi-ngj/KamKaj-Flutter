import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/order.dart';

final class OrdersState extends Equatable {
  const OrdersState({
    this.scope = OrderScope.current,
    this.current = const ViewLoading(),
    this.past = const ViewLoading(),
    this.busyOrderId,
  });

  final OrderScope scope;
  final ViewState<List<Order>> current;
  final ViewState<List<Order>> past;

  /// Order with an action in flight (pay / re-order) — its button shows a spinner.
  final String? busyOrderId;

  ViewState<List<Order>> get visible => scope == OrderScope.current ? current : past;

  int countOf(OrderScope s) =>
      (s == OrderScope.current ? current : past).dataOrNull?.length ?? 0;

  OrdersState copyWith({
    OrderScope? scope,
    ViewState<List<Order>>? current,
    ViewState<List<Order>>? past,
    String? busyOrderId,
    bool clearBusy = false,
  }) =>
      OrdersState(
        scope: scope ?? this.scope,
        current: current ?? this.current,
        past: past ?? this.past,
        busyOrderId: clearBusy ? null : busyOrderId ?? this.busyOrderId,
      );

  @override
  List<Object?> get props => [scope, current, past, busyOrderId];
}

final class OrdersViewModel extends Notifier<OrdersState> {
  @override
  OrdersState build() {
    Future.microtask(refresh);
    return const OrdersState();
  }

  void selectScope(OrderScope scope) => state = state.copyWith(scope: scope);

  /// Loads both tabs so the counts in the segmented control are accurate.
  Future<void> refresh() async {
    await Future.wait([_load(OrderScope.current), _load(OrderScope.past)]);
  }

  Future<void> retry() => _load(state.scope);

  Future<void> _load(OrderScope scope) async {
    final result = await ref.read(getOrdersProvider).call(scope);
    if (!ref.mounted) return;
    final view = result.when<ViewState<List<Order>>>(
      success: (orders) => orders.isEmpty ? const ViewEmpty() : ViewSuccess(orders),
      failure: (f) => ViewFailure(f),
    );
    state = scope == OrderScope.current
        ? state.copyWith(current: view)
        : state.copyWith(past: view);
  }

  /// Returns the failure, or `null` on success.
  Future<Failure?> pay(Order order) => _runAction(order, () => ref.read(payOrderProvider).call(order));

  Future<Failure?> reorder(Order order) =>
      _runAction(order, () => ref.read(reorderProvider).call(order));

  Future<Failure?> _runAction(Order order, Future<Result<Order>> Function() action) async {
    if (state.busyOrderId != null) return null;
    state = state.copyWith(busyOrderId: order.id);
    final result = await action();
    if (!ref.mounted) return null;
    state = state.copyWith(clearBusy: true);
    if (result.isSuccess) await _load(OrderScope.current);
    return result.failureOrNull;
  }
}

final ordersViewModelProvider =
    NotifierProvider.autoDispose<OrdersViewModel, OrdersState>(OrdersViewModel.new);
