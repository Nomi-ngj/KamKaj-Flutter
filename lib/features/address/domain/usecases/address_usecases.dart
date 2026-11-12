import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../entities/address.dart';
import '../repositories/address_repository.dart';

final class GetAddresses {
  const GetAddresses(this._repository);
  final AddressRepository _repository;

  /// Default address first, then the rest in their original order.
  Future<Result<List<Address>>> call() async {
    final result = await _repository.getAddresses();
    return result.when(
      success: (list) => Result.success([
        ...list.where((a) => a.isDefault),
        ...list.where((a) => !a.isDefault),
      ]),
      failure: (f) => Result.failure(f),
    );
  }
}

final class SaveAddress {
  const SaveAddress(this._repository);
  final AddressRepository _repository;

  static const int maxNotesLength = 200;

  /// Creates when [id] is null, otherwise updates.
  Future<Result<Address>> call(AddressDraft draft, {String? id}) async {
    if (draft.street.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Street address is required'));
    }
    if ((draft.driverNotes?.length ?? 0) > maxNotesLength) {
      return const Result.failure(ValidationFailure('Driver notes are too long'));
    }
    return id == null ? _repository.addAddress(draft) : _repository.updateAddress(id, draft);
  }
}

final class SetDefaultAddress {
  const SetDefaultAddress(this._repository);
  final AddressRepository _repository;

  Future<Result<List<Address>>> call(String id) => _repository.setDefault(id);
}
