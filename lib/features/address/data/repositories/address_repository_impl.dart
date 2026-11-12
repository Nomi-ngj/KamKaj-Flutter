import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_data_sources.dart';

final class AddressRepositoryImpl implements AddressRepository {
  const AddressRepositoryImpl(this._remote);
  final AddressRemoteDataSource _remote;

  @override
  Future<Result<List<Address>>> getAddresses() => ErrorMapper.guard(_remote.list);

  @override
  Future<Result<Address>> addAddress(AddressDraft draft) =>
      ErrorMapper.guard(() => _remote.create(draft));

  @override
  Future<Result<Address>> updateAddress(String id, AddressDraft draft) =>
      ErrorMapper.guard(() => _remote.update(id, draft));

  @override
  Future<Result<List<Address>>> setDefault(String id) => ErrorMapper.guard(() async {
        await _remote.setDefault(id);
        return _remote.list();
      });
}
