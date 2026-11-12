import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/checkout_entities.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_data_sources.dart';

final class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._remote);
  final PaymentRemoteDataSource _remote;

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods() =>
      ErrorMapper.guard(_remote.paymentMethods);
}
