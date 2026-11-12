import '../../../../core/utils/json_reader.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/order.dart';

abstract final class OrderMapper {
  static Order fromJson(Map<String, Object?> json) {
    final amountDue = json['amountDue'];
    final total = json['total'];
    return Order(
      id: json.readString('id'),
      number: json.readString('number'),
      title: json.readString('title'),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == json.readStringOrNull('status'),
        orElse: () => OrderStatus.pending,
      ),
      from: json.readStringOrNull('from') ?? '',
      to: json.readStringOrNull('to') ?? '',
      deliveryDate: json.readDateOrNull('deliveryDate') ?? DateTime.now(),
      subtitle: json.readStringOrNull('subtitle'),
      amountDue: amountDue is int ? Money(amountDue) : null,
      courierInfo: json.readStringOrNull('courierInfo'),
      cancelReason: json.readStringOrNull('cancelReason'),
      total: total is int ? Money(total) : null,
    );
  }

  static Map<String, Object?> requestToJson(PlaceOrderRequest request) => {
        'storeId': request.storeId,
        'addressId': request.addressId,
        'paymentMethodId': request.paymentMethodId,
        'items': [
          for (final item in request.items)
            {
              'productId': item.productId,
              'quantity': item.quantity,
              if (item.note != null && item.note!.isNotEmpty) 'note': item.note,
            },
        ],
      };
}
