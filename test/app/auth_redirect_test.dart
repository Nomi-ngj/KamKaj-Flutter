import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/app/router/app_router.dart';
import 'package:kamkaj_pro/app/router/route_names.dart';
import 'package:kamkaj_pro/features/auth/domain/entities/user.dart';
import 'package:kamkaj_pro/features/auth/presentation/viewmodels/session_view_model.dart';

void main() {
  const unknown = SessionState();
  const signedOut = SessionState(status: SessionStatus.unauthenticated);
  const signedIn = SessionState(
    status: SessionStatus.authenticated,
    user: User(id: '1', firstName: 'A', lastName: 'B', email: 'a@b.co'),
  );

  test('keeps the user on splash until the session is restored', () {
    expect(authRedirect(session: unknown, location: RoutePaths.splash), isNull);
    expect(authRedirect(session: unknown, location: RoutePaths.home), RoutePaths.splash);
  });

  test('guards private routes when signed out', () {
    expect(authRedirect(session: signedOut, location: RoutePaths.orders), RoutePaths.signIn);
    expect(authRedirect(session: signedOut, location: '/store/s1'), RoutePaths.signIn);
    expect(authRedirect(session: signedOut, location: RoutePaths.signUp), isNull);
    expect(authRedirect(session: signedOut, location: RoutePaths.onboarding), isNull);
  });

  test('sends signed-in users away from auth screens', () {
    expect(authRedirect(session: signedIn, location: RoutePaths.signIn), RoutePaths.home);
    expect(authRedirect(session: signedIn, location: RoutePaths.verifyEmail), RoutePaths.home);
    expect(authRedirect(session: signedIn, location: RoutePaths.checkout), isNull);
    expect(authRedirect(session: signedIn, location: '/profile/change-password'), isNull);
  });
}
