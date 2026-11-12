import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';

enum OrderStatus {
  awaitingPayment,
  pending,
  inTransit,
  delivered,
  cancelled;

  bool get isActive => this == awaitingPayment || this == pending || this == inTransit;
}

enum OrderScope { current, past }

final class Order extends Equatable {
  const Order({
    required this.id,
    required this.number,
    required this.title,
    required this.status,
    required this.from,
    required this.to,
    required this.deliveryDate,
    this.subtitle,
    this.amountDue,
    this.courierInfo,
    this.cancelReason,
    this.total,
  });

  final String id;

  /// Human-readable number, e.g. "64947".
  final String number;
  final String title;
  final OrderStatus status;
  final String from;
  final String to;
  final DateTime deliveryDate;

  /// e.g. "Driver assigned • On schedule".
  final String? subtitle;

  /// Set when payment is required before dispatch.
  final Money? amountDue;

  /// e.g. "Express Courier • 2 parcels" — enables live tracking.
  final String? courierInfo;
  final String? cancelReason;
  final Money? total;

  bool get canPay => status == OrderStatus.awaitingPayment && amountDue != null;
  bool get canTrack => status.isActive && courierInfo != null;
  bool get canReorder => status == OrderStatus.cancelled || status == OrderStatus.delivered;

  Order copyWith({OrderStatus? status, String? subtitle}) => Order(
        id: id,
        number: number,
        title: title,
        status: status ?? this.status,
        from: from,
        to: to,
        deliveryDate: deliveryDate,
        subtitle: subtitle ?? this.subtitle,
        amountDue: status == OrderStatus.pending ? null : amountDue,
        courierInfo: courierInfo,
        cancelReason: cancelReason,
        total: total,
      );

  @override
  List<Object?> get props => [
        id, number, title, status, from, to, deliveryDate,
        subtitle, amountDue, courierInfo, cancelReason, total,
      ];
}

final class PlaceOrderItem extends Equatable {
  const PlaceOrderItem({required this.productId, required this.quantity, this.note});

  final String productId;
  final int quantity;
  final String? note;

  @override
  List<Object?> get props => [productId, quantity, note];
}

final class PlaceOrderRequest extends Equatable {
  const PlaceOrderRequest({
    required this.storeId,
    required this.storeName,
    required this.items,
    required this.addressId,
    required this.deliveryAddress,
    required this.paymentMethodId,
    required this.total,
  });

  final String storeId;
  final String storeName;
  final List<PlaceOrderItem> items;
  final String addressId;
  final String deliveryAddress;
  final String paymentMethodId;
  final Money total;

  @override
  List<Object?> get props =>
      [storeId, storeName, items, addressId, deliveryAddress, paymentMethodId, total];
}
