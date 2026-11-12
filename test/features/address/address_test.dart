import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/errors/failure.dart';
import 'package:kamkaj_pro/features/address/domain/entities/address.dart';
import 'package:kamkaj_pro/features/address/domain/repositories/address_repository.dart';
import 'package:kamkaj_pro/features/address/domain/usecases/address_usecases.dart';
import 'package:kamkaj_pro/features/address/presentation/viewmodels/address_view_models.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockAddresses extends Mock implements AddressRepository {}

void main() {
  test('SaveAddress requires a street', () async {
    final repository = _MockAddresses();
    final result = await SaveAddress(repository)(
      const AddressDraft(type: AddressType.home, street: '   '),
    );
    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyZeroInteractions(repository);
  });

  test('setting a default reorders the list with the default first', () async {
    final container = await createTestContainer();
    final sub = container.listen(addressesProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(addressesProvider.notifier).load();

    final failure = await container.read(addressesProvider.notifier).setDefault('a_3');
    await container.read(addressesProvider.notifier).load();

    expect(failure, isNull);
    final list = container.read(addressesProvider).dataOrNull!;
    expect(list.first.id, 'a_3');
    expect(list.where((a) => a.isDefault), hasLength(1));
    expect(container.read(defaultAddressProvider)?.id, 'a_3');
  });

  test('adding an address appends it to the list', () async {
    final container = await createTestContainer();
    final sub = container.listen(addressFormViewModelProvider, (_, _) {});
    addTearDown(sub.close);

    final ok = await container
        .read(addressFormViewModelProvider.notifier)
        .save(street: '12 New Road', apartment: 'Flat 2');

    expect(ok, isTrue);
    final list = container.read(addressesProvider).dataOrNull!;
    expect(list.map((a) => a.street), contains('12 New Road'));
  });
}
