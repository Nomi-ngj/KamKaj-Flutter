import '../../../../core/errors/result.dart';
import '../../../../core/utils/money.dart';
import '../entities/checkout_entities.dart';
import '../repositories/payment_repository.dart';

/// Pricing rules (pending confirmation from product — see API_DOCUMENTATION.md):
/// delivery is free from [freeDeliveryThreshold], otherwise [standardDeliveryFee];
/// a flat [serviceFee] applies to every non-empty order.
final class CalculateCheckoutSummary {
  const CalculateCheckoutSummary();

  static final freeDeliveryThreshold = Money.fromMajor(1000);
  static final standardDeliveryFee = Money.fromMajor(100);
  static final serviceFee = Money.fromMajor(150);

  CheckoutSummary call(Money subtotal) {
    if (subtotal.isZero) {
      return CheckoutSummary(
        subtotal: subtotal,
        deliveryFee: const Money.zero(),
        serviceFee: const Money.zero(),
      );
    }
    final delivery = subtotal.compareTo(freeDeliveryThreshold) >= 0
        ? const Money.zero()
        : standardDeliveryFee;
    return CheckoutSummary(subtotal: subtotal, deliveryFee: delivery, serviceFee: serviceFee);
  }
}

final class GetPaymentMethods {
  const GetPaymentMethods(this._repository);
  final PaymentRepository _repository;

  Future<Result<List<PaymentMethod>>> call() => _repository.getPaymentMethods();
}
