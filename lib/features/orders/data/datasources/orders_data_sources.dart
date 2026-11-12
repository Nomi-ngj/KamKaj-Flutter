import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/order.dart';
import '../models/order_mapper.dart';

abstract interface class OrdersRemoteDataSource {
  Future<List<Order>> list(OrderScope scope);
  Future<Order> create(PlaceOrderRequest request);
  Future<Order> pay(String orderId);
  Future<Order> reorder(String orderId);
}

final class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  const OrdersRemoteDataSourceImpl(this._client);
  final DioClient _client;

  @override
  Future<List<Order>> list(OrderScope scope) async =>
      (await _client.getList(ApiEndpoints.orders, query: {'scope': scope.name}))
          .map(OrderMapper.fromJson)
          .toList();

  @override
  Future<Order> create(PlaceOrderRequest request) async => OrderMapper.fromJson(
        await _client.post(ApiEndpoints.orders, body: OrderMapper.requestToJson(request)),
      );

  @override
  Future<Order> pay(String orderId) async =>
      OrderMapper.fromJson(await _client.post(ApiEndpoints.payOrder(orderId)));

  @override
  Future<Order> reorder(String orderId) async =>
      OrderMapper.fromJson(await _client.post(ApiEndpoints.reorder(orderId)));
}

/// My Orders content from Figma, plus generated past orders.
final class OrdersMockDataSource implements OrdersRemoteDataSource {
  OrdersMockDataSource({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;
  int _nextNumber = 64948;

  static final _date = DateTime(2026, 10, 2);

  final List<Order> _current = [
    Order(
      id: 'o_64947',
      number: '64947',
      title: 'Shipment on the way',
      status: OrderStatus.awaitingPayment,
      from: 'Select Location, برج الفردوس, 503',
      to: 'none, 68, 108 Al Qayhawan Street',
      deliveryDate: _date,
      amountDue: Money.fromMajor(120),
    ),
    Order(
      id: 'o_64945',
      number: '64945',
      title: 'Shipment on the way',
      subtitle: 'Driver assigned • On schedule',
      status: OrderStatus.pending,
      from: 'al ferdous, office, F9WC+W',
      to: 'none, 68, 108 Al Qayhawan Street',
      deliveryDate: _date,
      courierInfo: 'Express Courier • 2 parcels',
    ),
    Order(
      id: 'o_64946',
      number: '64946',
      title: 'Shipment on the way',
      status: OrderStatus.pending,
      from: 'al ferdous, office, F9WC+W',
      to: 'Abu Dhabi, United Arab Emirates, المكتب ,000',
      deliveryDate: _date,
    ),
    Order(
      id: 'o_64940',
      number: '64940',
      title: 'Shipment on the way',
      status: OrderStatus.cancelled,
      from: 'al ferdous, office, F9WC+W',
      to: 'none, 68, 108 Al Qayhawan Street',
      deliveryDate: _date,
      cancelReason: 'Cancelled by customer request',
    ),
  ];

  late final List<Order> _past = List.generate(
    18,
    (i) => Order(
      id: 'o_past_$i',
      number: '${64900 - i}',
      title: 'Delivered',
      status: OrderStatus.delivered,
      from: 'The Corner Bakery, 124 Maple Avenue',
      to: '123 Maple Street, Apt 4B',
      deliveryDate: _date.subtract(Duration(days: 3 * (i + 1))),
      total: Money.fromMajor(650 + 50 * i),
    ),
  );

  Future<void> _delay() => Future<void>.delayed(latency);

  @override
  Future<List<Order>> list(OrderScope scope) async {
    await _delay();
    return List.unmodifiable(scope == OrderScope.current ? _current : _past);
  }

  @override
  Future<Order> create(PlaceOrderRequest request) async {
    await _delay();
    final number = '${_nextNumber++}';
    final order = Order(
      id: 'o_$number',
      number: number,
      title: 'Shipment on the way',
      subtitle: 'Finding a rider near ${request.storeName}',
      status: OrderStatus.pending,
      from: request.storeName,
      to: request.deliveryAddress,
      deliveryDate: DateTime.now(),
      courierInfo: 'Express Courier • ${request.items.length} parcels',
      total: request.total,
    );
    _current.insert(0, order);
    return order;
  }

  @override
  Future<Order> pay(String orderId) async {
    await _delay();
    final index = _current.indexWhere((o) => o.id == orderId);
    if (index == -1) throw const NotFoundException();
    final paid = _current[index].copyWith(
      status: OrderStatus.pending,
      subtitle: 'Payment received • Preparing dispatch',
    );
    _current[index] = paid;
    return paid;
  }

  @override
  Future<Order> reorder(String orderId) async {
    await _delay();
    final source = [..._current, ..._past].where((o) => o.id == orderId).firstOrNull;
    if (source == null) throw const NotFoundException();
    final number = '${_nextNumber++}';
    final order = Order(
      id: 'o_$number',
      number: number,
      title: 'Shipment on the way',
      subtitle: 'Re-ordered • Finding a rider',
      status: OrderStatus.pending,
      from: source.from,
      to: source.to,
      deliveryDate: DateTime.now(),
      total: source.total,
    );
    _current.insert(0, order);
    return order;
  }
}
