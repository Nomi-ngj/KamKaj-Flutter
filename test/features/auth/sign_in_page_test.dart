@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/features/auth/presentation/pages/sign_in_page.dart';
import 'package:kamkaj_pro/features/auth/presentation/viewmodels/session_view_model.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('shows validation errors for empty fields', (tester) async {
    final container = await createTestContainer();
    await pumpApp(tester, const SignInPage(), container: container);

    await tester.ensureVisible(find.byKey(const Key('signIn_submit')));
    await tester.tap(find.byKey(const Key('signIn_submit')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('signs in with the demo account', (tester) async {
    final container = await createTestContainer();
    await pumpApp(tester, const SignInPage(), container: container);

    await tester.enterText(find.byKey(const Key('signIn_email')), 'hello@appname.com');
    await tester.enterText(find.byKey(const Key('signIn_password')), 'Password1');
    await tester.ensureVisible(find.byKey(const Key('signIn_submit')));
    await tester.tap(find.byKey(const Key('signIn_submit')));
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider).isAuthenticated, isTrue);
  });

  testWidgets('shows the server error for a wrong password', (tester) async {
    final container = await createTestContainer();
    await pumpApp(tester, const SignInPage(), container: container);

    await tester.enterText(find.byKey(const Key('signIn_email')), 'hello@appname.com');
    await tester.enterText(find.byKey(const Key('signIn_password')), 'nope');
    await tester.ensureVisible(find.byKey(const Key('signIn_submit')));
    await tester.tap(find.byKey(const Key('signIn_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });
}
