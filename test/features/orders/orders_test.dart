import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/base/view_state.dart';
import 'package:kamkaj_pro/core/errors/failure.dart';
import 'package:kamkaj_pro/core/utils/money.dart';
import 'package:kamkaj_pro/features/orders/domain/entities/order.dart';
import 'package:kamkaj_pro/features/orders/domain/repositories/orders_repository.dart';
import 'package:kamkaj_pro/features/orders/domain/usecases/orders_usecases.dart';
import 'package:kamkaj_pro/features/orders/presentation/viewmodels/orders_view_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockOrders extends Mock implements OrdersRepository {}

void main() {
  group('PlaceOrder', () {
    test('rejects an order without items', () async {
      final repository = _MockOrders();
      final result = await PlaceOrder(repository)(
        PlaceOrderRequest(
          storeId: 's',
          storeName: 'S',
          items: const [],
          addressId: 'a',
          deliveryAddress: 'x',
          paymentMethodId: 'p',
          total: Money.fromMajor(10),
        ),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(repository);
    });
  });

  group('OrdersViewModel', () {
    test('loads both tabs and puts orders needing payment first', () async {
      final container = await createTestContainer();
      final sub = container.listen(ordersViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(ordersViewModelProvider.notifier).refresh();
      final state = container.read(ordersViewModelProvider);

      expect(state.countOf(OrderScope.current), 4);
      expect(state.countOf(OrderScope.past), 18);
      final current = (state.current as ViewSuccess<List<Order>>).data;
      expect(current.first.canPay, isTrue);
    });

    test('paying an order moves it to pending', () async {
      final container = await createTestContainer();
      final sub = container.listen(ordersViewModelProvider, (_, _) {});
      addTearDown(sub.close);
      final viewModel = container.read(ordersViewModelProvider.notifier);
      await viewModel.refresh();

      final unpaid = container.read(ordersViewModelProvider).current.dataOrNull!.first;
      final failure = await viewModel.pay(unpaid);

      expect(failure, isNull);
      final updated = container
          .read(ordersViewModelProvider)
          .current
          .dataOrNull!
          .firstWhere((o) => o.id == unpaid.id);
      expect(updated.status, OrderStatus.pending);
      expect(updated.canPay, isFalse);
    });
  });
}
