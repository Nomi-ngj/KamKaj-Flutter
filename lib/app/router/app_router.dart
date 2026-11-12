import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/address/presentation/pages/add_address_page.dart';
import '../../features/address/presentation/pages/saved_addresses_page.dart';
import '../../features/app_settings/presentation/pages/language_page.dart';
import '../../features/auth/domain/entities/verification_purpose.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/password_pages.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/presentation/viewmodels/session_view_model.dart';
import '../../features/catalog/presentation/pages/categories_page.dart';
import '../../features/catalog/presentation/pages/product_detail_page.dart';
import '../../features/catalog/presentation/pages/store_detail_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/home/presentation/pages/dashboard_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/orders/presentation/pages/my_orders_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/services/presentation/pages/services_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/not_found_page.dart';
import 'route_names.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Bridges Riverpod session changes to GoRouter's `refreshListenable`.
final class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen<SessionState>(sessionProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) => authRedirect(
      session: ref.read(sessionProvider),
      location: state.matchedLocation,
    ),
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: RoutePaths.language,
        name: RouteNames.language,
        builder: (_, _) => const LanguagePage(),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        name: RouteNames.signIn,
        builder: (_, _) => const SignInPage(),
      ),
      GoRoute(
        path: RoutePaths.signUp,
        name: RouteNames.signUp,
        builder: (_, _) => const SignUpPage(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RoutePaths.verifyEmail,
        name: RouteNames.verifyEmail,
        builder: (_, state) => VerifyEmailPage(
          email: state.uri.queryParameters[RouteParams.email] ?? '',
          purpose: VerificationPurpose.fromName(state.uri.queryParameters[RouteParams.purpose]),
        ),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        builder: (_, state) =>
            ResetPasswordPage(email: state.uri.queryParameters[RouteParams.email] ?? ''),
      ),

      // ── Signed-in shell with bottom navigation ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (_, _) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.explore,
                name: RouteNames.explore,
                builder: (_, state) => CategoriesPage(
                  initialQuery: state.uri.queryParameters[RouteParams.category],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.orders,
                name: RouteNames.orders,
                builder: (_, _) => const MyOrdersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (_, _) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: RoutePaths.addresses,
                    name: RouteNames.addresses,
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const SavedAddressesPage(),
                    routes: [
                      GoRoute(
                        path: RoutePaths.addAddress,
                        name: RouteNames.addAddress,
                        parentNavigatorKey: _rootKey,
                        builder: (_, _) => const AddAddressPage(),
                      ),
                      GoRoute(
                        path: RoutePaths.editAddress,
                        name: RouteNames.editAddress,
                        parentNavigatorKey: _rootKey,
                        builder: (_, state) =>
                            AddAddressPage(addressId: state.pathParameters[RouteParams.addressId]),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: RoutePaths.changePassword,
                    name: RouteNames.changePassword,
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const ChangePasswordPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.services,
                    name: RouteNames.services,
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const ServicesPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.changeLanguage,
                    name: RouteNames.changeLanguage,
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const LanguagePage(fromSettings: true),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes above the shell ──────────────────────────────────
      GoRoute(
        path: RoutePaths.storeDetail,
        name: RouteNames.storeDetail,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => StoreDetailPage(storeId: state.pathParameters[RouteParams.storeId]!),
      ),
      GoRoute(
        path: RoutePaths.productDetail,
        name: RouteNames.productDetail,
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ProductDetailPage(productId: state.pathParameters[RouteParams.productId]!),
      ),
      GoRoute(
        path: RoutePaths.checkout,
        name: RouteNames.checkout,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CheckoutPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Pure redirect logic (unit-tested in `test/app/router/auth_redirect_test.dart`).
String? authRedirect({required SessionState session, required String location}) {
  final isPublic = RoutePaths.publicPrefixes.any(location.startsWith);
  if (session.status == SessionStatus.unknown) {
    // Session not restored yet — only the splash may decide.
    return location == RoutePaths.splash || isPublic ? null : RoutePaths.splash;
  }
  if (!session.isAuthenticated && !isPublic) return RoutePaths.signIn;
  if (session.isAuthenticated && location.startsWith(RoutePaths.auth)) return RoutePaths.home;
  return null;
}
