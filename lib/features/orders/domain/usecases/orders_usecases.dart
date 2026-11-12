import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

final class GetOrders {
  const GetOrders(this._repository);
  final OrdersRepository _repository;

  /// Orders needing payment come first, then newest delivery date.
  Future<Result<List<Order>>> call(OrderScope scope) async {
    final result = await _repository.getOrders(scope);
    return result.when(
      success: (orders) {
        final sorted = [...orders]..sort((a, b) {
            if (a.canPay != b.canPay) return a.canPay ? -1 : 1;
            return b.deliveryDate.compareTo(a.deliveryDate);
          });
        return Result.success(sorted);
      },
      failure: (f) => Result.failure(f),
    );
  }
}

final class PlaceOrder {
  const PlaceOrder(this._repository);
  final OrdersRepository _repository;

  Future<Result<Order>> call(PlaceOrderRequest request) async {
    if (request.items.isEmpty) {
      return const Result.failure(ValidationFailure('Your basket is empty'));
    }
    if (request.addressId.isEmpty) {
      return const Result.failure(ValidationFailure('Choose a delivery address'));
    }
    if (request.paymentMethodId.isEmpty) {
      return const Result.failure(ValidationFailure('Choose a payment method'));
    }
    return _repository.placeOrder(request);
  }
}

final class PayOrder {
  const PayOrder(this._repository);
  final OrdersRepository _repository;

  Future<Result<Order>> call(Order order) async {
    if (!order.canPay) {
      return const Result.failure(ValidationFailure('This order has nothing to pay'));
    }
    return _repository.payOrder(order.id);
  }
}

final class Reorder {
  const Reorder(this._repository);
  final OrdersRepository _repository;

  Future<Result<Order>> call(Order order) async {
    if (!order.canReorder) {
      return const Result.failure(ValidationFailure('This order is still active'));
    }
    return _repository.reorder(order.id);
  }
}
