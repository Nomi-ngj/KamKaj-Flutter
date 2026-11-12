import '../../../../core/errors/result.dart';
import '../entities/order.dart';

abstract interface class OrdersRepository {
  Future<Result<List<Order>>> getOrders(OrderScope scope);
  Future<Result<Order>> placeOrder(PlaceOrderRequest request);
  Future<Result<Order>> payOrder(String orderId);

  /// Creates a new order with the same items and route as [orderId].
  Future<Result<Order>> reorder(String orderId);
}
