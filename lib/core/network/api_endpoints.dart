/// Relative API paths. The base URL comes from [AppConfig].
abstract final class ApiEndpoints {
  // Auth
  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const refreshToken = '/auth/refresh';
  static const signOut = '/auth/sign-out';
  static const forgotPassword = '/auth/forgot-password';
  static const verifyCode = '/auth/verify-code';
  static const resendCode = '/auth/resend-code';
  static const resetPassword = '/auth/reset-password';
  static const changePassword = '/auth/change-password';
  static const me = '/users/me';

  // Catalog
  static const categories = '/categories';
  static const dailyPicks = '/products/daily-picks';
  static const nearbyShops = '/stores/nearby';
  static const featuredStores = '/stores/featured';
  static const stores = '/stores';
  static String store(String id) => '/stores/$id';
  static String storeProducts(String id) => '/stores/$id/products';
  static String product(String id) => '/products/$id';

  // Addresses
  static const addresses = '/addresses';
  static String address(String id) => '/addresses/$id';
  static String setDefaultAddress(String id) => '/addresses/$id/default';

  // Orders & checkout
  static const orders = '/orders';
  static const paymentMethods = '/payment-methods';
  static String payOrder(String id) => '/orders/$id/pay';
  static String reorder(String id) => '/orders/$id/reorder';

  // Services
  static const services = '/services';
  static const vehicleTypes = '/rides/vehicle-types';
  static const rides = '/rides';
}
