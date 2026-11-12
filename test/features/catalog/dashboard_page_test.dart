@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/features/home/presentation/pages/dashboard_page.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders all Dashboard sections from the catalog', (tester) async {
    final container = await createTestContainer();
    await pumpApp(tester, const DashboardPage(), container: container);
    await tester.pumpAndSettle();

    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Fresh Today'), findsOneWidget);
    expect(find.text('Handcrafted Sourdough'), findsOneWidget);
    expect(find.text('Nearby Shops'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Featured Stores'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Featured Stores'), findsOneWidget);
  });
}
