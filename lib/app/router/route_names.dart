/// Route names and paths. Navigate with `context.goNamed(RouteNames.x)`.
abstract final class RouteNames {
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const language = 'language';

  static const signIn = 'signIn';
  static const signUp = 'signUp';
  static const forgotPassword = 'forgotPassword';
  static const verifyEmail = 'verifyEmail';
  static const resetPassword = 'resetPassword';

  static const home = 'home';
  static const explore = 'explore';
  static const orders = 'orders';
  static const profile = 'profile';

  static const storeDetail = 'storeDetail';
  static const productDetail = 'productDetail';
  static const checkout = 'checkout';
  static const addresses = 'addresses';
  static const addAddress = 'addAddress';
  static const editAddress = 'editAddress';
  static const changePassword = 'changePassword';
  static const services = 'services';
  static const changeLanguage = 'changeLanguage';
}

abstract final class RoutePaths {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const language = '/language';

  static const auth = '/auth';
  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const forgotPassword = '/auth/forgot-password';
  static const verifyEmail = '/auth/verify-email';
  static const resetPassword = '/auth/reset-password';

  static const home = '/home';
  static const explore = '/explore';
  static const orders = '/orders';
  static const profile = '/profile';

  static const storeDetail = '/store/:storeId';
  static const productDetail = '/product/:productId';
  static const checkout = '/checkout';
  static const addresses = 'addresses';
  static const addAddress = 'new';
  static const editAddress = ':addressId/edit';
  static const changePassword = 'change-password';
  static const services = 'services';
  static const changeLanguage = 'language';

  /// Routes reachable without a session.
  static const publicPrefixes = [splash, onboarding, language, auth];
}

/// Query/path parameter keys.
abstract final class RouteParams {
  static const storeId = 'storeId';
  static const productId = 'productId';
  static const addressId = 'addressId';
  static const email = 'email';
  static const purpose = 'purpose';
  static const category = 'category';
}
