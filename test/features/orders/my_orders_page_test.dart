@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/features/orders/presentation/pages/my_orders_page.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders current orders with counts and switches tabs', (tester) async {
    final container = await createTestContainer();
    await pumpApp(tester, const MyOrdersPage(), container: container);
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Current Orders'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Pay Now & Confirm Dispatch'), findsOneWidget);

    await tester.tap(find.text('Past Orders'));
    await tester.pumpAndSettle();

    expect(find.text('Pay Now & Confirm Dispatch'), findsNothing);
    expect(find.text('Delivered'), findsWidgets);
  });
}
