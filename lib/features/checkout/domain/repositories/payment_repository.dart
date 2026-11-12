import '../../../../core/errors/result.dart';
import '../entities/checkout_entities.dart';

abstract interface class PaymentRepository {
  Future<Result<List<PaymentMethod>>> getPaymentMethods();
}
