import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/address.dart';
import '../models/address_mapper.dart';

abstract interface class AddressRemoteDataSource {
  Future<List<Address>> list();
  Future<Address> create(AddressDraft draft);
  Future<Address> update(String id, AddressDraft draft);
  Future<void> setDefault(String id);
}

final class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  const AddressRemoteDataSourceImpl(this._client);
  final DioClient _client;

  @override
  Future<List<Address>> list() async =>
      (await _client.getList(ApiEndpoints.addresses)).map(AddressMapper.fromJson).toList();

  @override
  Future<Address> create(AddressDraft draft) async => AddressMapper.fromJson(
        await _client.post(ApiEndpoints.addresses, body: AddressMapper.draftToJson(draft)),
      );

  @override
  Future<Address> update(String id, AddressDraft draft) async => AddressMapper.fromJson(
        await _client.put(ApiEndpoints.address(id), body: AddressMapper.draftToJson(draft)),
      );

  @override
  Future<void> setDefault(String id) => _client.post(ApiEndpoints.setDefaultAddress(id));
}

final class AddressMockDataSource implements AddressRemoteDataSource {
  AddressMockDataSource({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;
  int _nextId = 4;

  final List<Address> _addresses = [
    const Address(
      id: 'a_1',
      type: AddressType.home,
      label: 'My Home',
      street: '123 Maple Street, Apt 4B',
      city: 'Springfield, IL 62704',
      driverNotes: 'Front porch delivery',
      isDefault: true,
    ),
    const Address(
      id: 'a_2',
      type: AddressType.work,
      label: 'My Office Work Address',
      street: '450 Corporate Drive, Suite 200',
      city: 'Springfield, IL 62701',
    ),
    const Address(
      id: 'a_3',
      type: AddressType.other,
      label: 'Other',
      street: '88 Cherry Lane',
      city: 'Shelbyville, IL 62799',
    ),
  ];

  Future<void> _delay() => Future<void>.delayed(latency);

  Address _fromDraft(String id, AddressDraft draft, {required bool isDefault}) => Address(
        id: id,
        type: draft.type,
        label: draft.type == AddressType.work ? 'My Work' : 'My ${draft.type.label}',
        street: draft.street.trim(),
        city: draft.city.trim(),
        apartment: draft.apartment?.trim(),
        driverNotes: draft.driverNotes?.trim(),
        isDefault: isDefault,
      );

  @override
  Future<List<Address>> list() async {
    await _delay();
    return List.unmodifiable(_addresses);
  }

  @override
  Future<Address> create(AddressDraft draft) async {
    await _delay();
    final address = _fromDraft('a_${_nextId++}', draft, isDefault: _addresses.isEmpty);
    _addresses.add(address);
    return address;
  }

  @override
  Future<Address> update(String id, AddressDraft draft) async {
    await _delay();
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index == -1) throw const NotFoundException();
    final updated = _fromDraft(id, draft, isDefault: _addresses[index].isDefault);
    _addresses[index] = updated;
    return updated;
  }

  @override
  Future<void> setDefault(String id) async {
    await _delay();
    if (!_addresses.any((a) => a.id == id)) throw const NotFoundException();
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == id);
    }
  }
}
