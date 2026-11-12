import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kamkaj_pro/app/app.dart';
import 'package:kamkaj_pro/core/storage/storage_keys.dart';

import '../test/helpers/test_helpers.dart';

/// Critical journey: splash → sign in → home → store → add to basket →
/// checkout → place order → My Orders.
///
/// Run: `flutter test integration_test` on a device or simulator.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a returning user can sign in and place an order', (tester) async {
    final container = await createTestContainer(
      prefs: {StorageKeys.onboardingCompleted: true, StorageKeys.languageCode: 'en'},
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const KamKajApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Sign in
    expect(find.text('Welcome to\nAppName'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('signIn_email')), 'hello@appname.com');
    await tester.enterText(find.byKey(const Key('signIn_password')), 'Password1');
    await tester.ensureVisible(find.byKey(const Key('signIn_submit')));
    await tester.tap(find.byKey(const Key('signIn_submit')));
    await tester.pumpAndSettle();

    // Home → store
    expect(find.text('Fresh Today'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('The Corner Bakery'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('The Corner Bakery'));
    await tester.pumpAndSettle();

    // Add to basket and open checkout
    await tester.tap(find.byTooltip('Add Almond Croissant to basket'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View your basket'));
    await tester.pumpAndSettle();

    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    // Lands on My Orders with the new order on top.
    expect(find.text('My Orders'), findsOneWidget);
  });
}
