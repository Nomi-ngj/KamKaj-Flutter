import '../../../../core/errors/result.dart';
import '../entities/address.dart';

abstract interface class AddressRepository {
  Future<Result<List<Address>>> getAddresses();
  Future<Result<Address>> addAddress(AddressDraft draft);
  Future<Result<Address>> updateAddress(String id, AddressDraft draft);
  Future<Result<List<Address>>> setDefault(String id);
}
