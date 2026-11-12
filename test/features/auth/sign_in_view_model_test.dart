import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/base/submit_state.dart';
import 'package:kamkaj_pro/features/auth/presentation/viewmodels/auth_form_view_models.dart';
import 'package:kamkaj_pro/features/auth/presentation/viewmodels/session_view_model.dart';

import '../../helpers/test_helpers.dart';

void main() {
  test('successful sign in authenticates the session', () async {
    final container = await createTestContainer();
    final sub = container.listen(signInViewModelProvider, (_, _) {});
    addTearDown(sub.close);

    final ok = await container
        .read(signInViewModelProvider.notifier)
        .submit(email: 'hello@appname.com', password: 'Password1');

    expect(ok, isTrue);
    expect(container.read(signInViewModelProvider).status, SubmitStatus.success);
    expect(container.read(sessionProvider).isAuthenticated, isTrue);
  });

  test('wrong password surfaces the server message', () async {
    final container = await createTestContainer();
    final sub = container.listen(signInViewModelProvider, (_, _) {});
    addTearDown(sub.close);

    final ok = await container
        .read(signInViewModelProvider.notifier)
        .submit(email: 'hello@appname.com', password: 'wrong');

    expect(ok, isFalse);
    expect(container.read(signInViewModelProvider).errorMessage, 'Incorrect email or password.');
    expect(container.read(sessionProvider).isAuthenticated, isFalse);
  });
}
