import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/base/submit_state.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/errors/failure.dart';
import '../../../address/domain/entities/address.dart';
import '../../../address/presentation/viewmodels/address_view_models.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../cart/presentation/viewmodels/cart_view_model.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/checkout_entities.dart';

final class CheckoutState extends Equatable {
  const CheckoutState({
    required this.cart,
    required this.summary,
    this.address,
    this.paymentMethods = const ViewLoading(),
    this.selectedPaymentId,
    this.submit = const SubmitState.idle(),
  });

  final Cart cart;
  final CheckoutSummary summary;
  final Address? address;
  final ViewState<List<PaymentMethod>> paymentMethods;
  final String? selectedPaymentId;
  final SubmitState submit;

  PaymentMethod? get selectedPayment {
    final methods = paymentMethods.dataOrNull ?? const <PaymentMethod>[];
    return methods.where((m) => m.id == selectedPaymentId).firstOrNull ?? methods.firstOrNull;
  }

  bool get canPlaceOrder =>
      !cart.isEmpty && address != null && selectedPayment != null && !submit.isSubmitting;

  CheckoutState copyWith({
    ViewState<List<PaymentMethod>>? paymentMethods,
    String? selectedPaymentId,
    SubmitState? submit,
  }) =>
      CheckoutState(
        cart: cart,
        summary: summary,
        address: address,
        paymentMethods: paymentMethods ?? this.paymentMethods,
        selectedPaymentId: selectedPaymentId ?? this.selectedPaymentId,
        submit: submit ?? this.submit,
      );

  @override
  List<Object?> get props => [cart, summary, address, paymentMethods, selectedPaymentId, submit];
}

/// Saved payment methods.
final class PaymentMethodsViewModel extends Notifier<ViewState<List<PaymentMethod>>> {
  @override
  ViewState<List<PaymentMethod>> build() {
    Future.microtask(load);
    return const ViewLoading();
  }

  Future<void> load() async {
    state = const ViewLoading();
    final result = await ref.read(getPaymentMethodsProvider).call();
    if (!ref.mounted) return;
    state = result.when(
      success: (list) => list.isEmpty ? const ViewEmpty() : ViewSuccess(list),
      failure: (f) => ViewFailure(f),
    );
  }
}

final paymentMethodsViewModelProvider = NotifierProvider.autoDispose<PaymentMethodsViewModel,
    ViewState<List<PaymentMethod>>>(PaymentMethodsViewModel.new);

final class CheckoutViewModel extends Notifier<CheckoutState> {
  // Notifier instances survive rebuilds, so the user's choice is kept when
  // the cart or address changes.
  String? _selectedPaymentId;

  @override
  CheckoutState build() {
    final cart = ref.watch(cartProvider);
    return CheckoutState(
      cart: cart,
      summary: ref.read(calculateCheckoutSummaryProvider).call(cart.subtotal),
      address: ref.watch(defaultAddressProvider),
      paymentMethods: ref.watch(paymentMethodsViewModelProvider),
      selectedPaymentId: _selectedPaymentId,
    );
  }

  Future<void> retryPaymentMethods() => ref.read(paymentMethodsViewModelProvider.notifier).load();

  void selectPayment(String id) {
    _selectedPaymentId = id;
    state = state.copyWith(selectedPaymentId: id);
  }

  void setQuantity(String productId, int quantity) =>
      ref.read(cartProvider.notifier).setQuantity(productId, quantity);

  /// Places the order. Returns the created order, or `null` on failure.
  Future<Order?> placeOrder() async {
    final current = state;
    final address = current.address;
    final payment = current.selectedPayment;
    if (current.submit.isSubmitting) return null;
    if (address == null || payment == null || current.cart.isEmpty) {
      state = current.copyWith(
        submit: const SubmitState.failed(
          ValidationFailure('Add a delivery address and payment method to continue'),
        ),
      );
      return null;
    }
    state = current.copyWith(submit: const SubmitState.submitting());

    final request = PlaceOrderRequest(
      storeId: current.cart.storeId ?? '',
      storeName: current.cart.storeName ?? '',
      items: [
        for (final item in current.cart.items)
          PlaceOrderItem(productId: item.product.id, quantity: item.quantity, note: item.note),
      ],
      addressId: address.id,
      deliveryAddress: address.streetLine,
      paymentMethodId: payment.id,
      total: current.summary.total,
    );
    final result = await ref.read(placeOrderProvider).call(request);
    if (!ref.mounted) return null;

    return result.when(
      success: (order) {
        state = state.copyWith(submit: const SubmitState.success());
        ref.read(cartProvider.notifier).clear();
        return order;
      },
      failure: (f) {
        state = state.copyWith(submit: SubmitState.failed(f));
        return null;
      },
    );
  }
}

final checkoutViewModelProvider =
    NotifierProvider.autoDispose<CheckoutViewModel, CheckoutState>(CheckoutViewModel.new);
