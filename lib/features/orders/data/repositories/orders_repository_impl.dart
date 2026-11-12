import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_data_sources.dart';

final class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._remote);
  final OrdersRemoteDataSource _remote;

  @override
  Future<Result<List<Order>>> getOrders(OrderScope scope) =>
      ErrorMapper.guard(() => _remote.list(scope));

  @override
  Future<Result<Order>> placeOrder(PlaceOrderRequest request) =>
      ErrorMapper.guard(() => _remote.create(request));

  @override
  Future<Result<Order>> payOrder(String orderId) => ErrorMapper.guard(() => _remote.pay(orderId));

  @override
  Future<Result<Order>> reorder(String orderId) => ErrorMapper.guard(() => _remote.reorder(orderId));
}
