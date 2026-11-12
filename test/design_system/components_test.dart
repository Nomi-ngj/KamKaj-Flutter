@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/design_system/components/components.dart';
import 'package:kamkaj_pro/design_system/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('AppButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(AppButton(label: 'Sign In', onPressed: () => taps++)));

      await tester.tap(find.text('Sign In'));
      expect(taps, 1);
    });

    testWidgets('shows a spinner and ignores taps while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppButton(label: 'Sign In', isLoading: true, onPressed: () => taps++)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
    });

    testWidgets('is announced as a disabled button without onPressed', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const AppButton(label: 'Submit', onPressed: null)));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Submit')),
        isSemantics(label: 'Submit', isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });
  });

  group('AppTextField', () {
    testWidgets('password visibility can be toggled', (tester) async {
      await tester.pumpWidget(_wrap(const AppTextField(hint: 'Password', isPassword: true)));

      EditableText editable() => tester.widget<EditableText>(find.byType(EditableText));
      expect(editable().obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(editable().obscureText, isFalse);
    });
  });

  group('AppQuantityStepper', () {
    testWidgets('respects the minimum', (tester) async {
      int? changed;
      await tester.pumpWidget(
        _wrap(AppQuantityStepper(quantity: 1, onChanged: (q) => changed = q)),
      );

      await tester.tap(find.byTooltip('Decrease quantity'));
      expect(changed, isNull);

      await tester.tap(find.byTooltip('Increase quantity'));
      expect(changed, 2);
    });
  });

  testWidgets('AppOtpField reports the combined code', (tester) async {
    var code = '';
    await tester.pumpWidget(_wrap(AppOtpField(onChanged: (c) => code = c)));

    for (var i = 0; i < 6; i++) {
      await tester.enterText(find.byKey(ValueKey('otp_$i')), '${i + 1}');
    }
    expect(code, '123456');
  });
}
