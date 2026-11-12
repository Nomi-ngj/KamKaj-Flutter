import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';

final class PaymentMethod extends Equatable {
  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
  });

  final String id;
  final String brand;
  final String last4;

  /// "12/29".
  final String expiry;

  String get title => '$brand ending in $last4';

  @override
  List<Object?> get props => [id, brand, last4, expiry];
}

final class CheckoutSummary extends Equatable {
  const CheckoutSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
  });

  final Money subtotal;
  final Money deliveryFee;
  final Money serviceFee;

  Money get total => subtotal + deliveryFee + serviceFee;
  bool get isFreeDelivery => deliveryFee.isZero;

  @override
  List<Object?> get props => [subtotal, deliveryFee, serviceFee];
}
