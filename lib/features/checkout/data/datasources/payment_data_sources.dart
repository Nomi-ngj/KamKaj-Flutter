import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_reader.dart';
import '../../domain/entities/checkout_entities.dart';

abstract interface class PaymentRemoteDataSource {
  Future<List<PaymentMethod>> paymentMethods();
}

final class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  const PaymentRemoteDataSourceImpl(this._client);
  final DioClient _client;

  @override
  Future<List<PaymentMethod>> paymentMethods() async =>
      (await _client.getList(ApiEndpoints.paymentMethods))
          .map(
            (json) => PaymentMethod(
              id: json.readString('id'),
              brand: json.readString('brand'),
              last4: json.readString('last4'),
              expiry: json.readString('expiry'),
            ),
          )
          .toList();
}

final class PaymentMockDataSource implements PaymentRemoteDataSource {
  const PaymentMockDataSource();

  @override
  Future<List<PaymentMethod>> paymentMethods() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [PaymentMethod(id: 'pm_1', brand: 'Visa', last4: '4242', expiry: '12/29')];
  }
}
