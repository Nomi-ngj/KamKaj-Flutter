// Centralised dependency injection.
//
// Riverpod providers act as the DI container: every infrastructure object,
// data source, repository and use case is registered here, created lazily and
// overridable in tests (`ProviderScope(overrides: [...])`).
// ViewModel providers live next to their ViewModels in each feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/session_events.dart';
import '../../core/storage/preferences_storage.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/storage/token_storage.dart';
import '../../features/address/data/datasources/address_data_sources.dart';
import '../../features/address/data/repositories/address_repository_impl.dart';
import '../../features/address/domain/repositories/address_repository.dart';
import '../../features/address/domain/usecases/address_usecases.dart';
import '../../features/app_settings/data/repositories/settings_repository_impl.dart';
import '../../features/app_settings/domain/repositories/settings_repository.dart';
import '../../features/auth/data/datasources/auth_mock_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/catalog/data/datasources/catalog_data_sources.dart';
import '../../features/catalog/data/repositories/catalog_repository_impl.dart';
import '../../features/catalog/domain/repositories/catalog_repository.dart';
import '../../features/catalog/domain/usecases/catalog_usecases.dart';
import '../../features/checkout/data/datasources/payment_data_sources.dart';
import '../../features/checkout/data/repositories/payment_repository_impl.dart';
import '../../features/checkout/domain/repositories/payment_repository.dart';
import '../../features/checkout/domain/usecases/checkout_usecases.dart';
import '../../features/orders/data/datasources/orders_data_sources.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/orders_usecases.dart';
import '../../features/services/data/datasources/services_data_sources.dart';
import '../../features/services/data/repositories/services_repository_impl.dart';
import '../../features/services/domain/repositories/services_repository.dart';
import '../../features/services/domain/usecases/services_usecases.dart';
import '../config/app_config.dart';

// ── Infrastructure ───────────────────────────────────────────────────────────

/// Overridden in `bootstrap.dart` with the build-time config.
final appConfigProvider = Provider<AppConfig>((_) => AppConfig.fromEnvironment());

/// Must be overridden in `bootstrap.dart` after `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final preferencesStorageProvider = Provider<PreferencesStorage>(
  (ref) => SharedPreferencesStorage(ref.watch(sharedPreferencesProvider)),
);

final secureStorageProvider = Provider<SecureStorage>((_) => FlutterSecureStorageImpl());

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    onSessionExpired: ref.watch(sessionEventsProvider).notifyExpired,
  ),
);

bool _useMock(Ref ref) => ref.watch(appConfigProvider).useMockApi;

// ── App settings ─────────────────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(preferencesStorageProvider)),
);

// ── Auth ─────────────────────────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => _useMock(ref)
      ? AuthMockDataSource()
      : AuthRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final getCurrentUserProvider = Provider((ref) => GetCurrentUser(ref.watch(authRepositoryProvider)));
final signInProvider = Provider((ref) => SignIn(ref.watch(authRepositoryProvider)));
final signUpProvider = Provider((ref) => SignUp(ref.watch(authRepositoryProvider)));
final requestPasswordResetProvider =
    Provider((ref) => RequestPasswordReset(ref.watch(authRepositoryProvider)));
final verifyCodeProvider = Provider((ref) => VerifyCode(ref.watch(authRepositoryProvider)));
final resendCodeProvider = Provider((ref) => ResendCode(ref.watch(authRepositoryProvider)));
final resetPasswordProvider = Provider((ref) => ResetPassword(ref.watch(authRepositoryProvider)));
final changePasswordProvider = Provider((ref) => ChangePassword(ref.watch(authRepositoryProvider)));
final signOutProvider = Provider((ref) => SignOut(ref.watch(authRepositoryProvider)));

// ── Catalog ──────────────────────────────────────────────────────────────────

final catalogRemoteDataSourceProvider = Provider<CatalogRemoteDataSource>(
  (ref) => _useMock(ref)
      ? const CatalogMockDataSource()
      : CatalogRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepositoryImpl(ref.watch(catalogRemoteDataSourceProvider)),
);

final getDashboardProvider = Provider((ref) => GetDashboard(ref.watch(catalogRepositoryProvider)));
final searchCategoriesProvider =
    Provider((ref) => SearchCategories(ref.watch(catalogRepositoryProvider)));
final getStoreDetailProvider =
    Provider((ref) => GetStoreDetail(ref.watch(catalogRepositoryProvider)));
final getStoresByCategoryProvider =
    Provider((ref) => GetStoresByCategory(ref.watch(catalogRepositoryProvider)));
final getProductProvider = Provider((ref) => GetProduct(ref.watch(catalogRepositoryProvider)));

// ── Addresses ────────────────────────────────────────────────────────────────

final addressRemoteDataSourceProvider = Provider<AddressRemoteDataSource>(
  (ref) => _useMock(ref)
      ? AddressMockDataSource()
      : AddressRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepositoryImpl(ref.watch(addressRemoteDataSourceProvider)),
);

final getAddressesProvider = Provider((ref) => GetAddresses(ref.watch(addressRepositoryProvider)));
final saveAddressProvider = Provider((ref) => SaveAddress(ref.watch(addressRepositoryProvider)));
final setDefaultAddressProvider =
    Provider((ref) => SetDefaultAddress(ref.watch(addressRepositoryProvider)));

// ── Orders & checkout ────────────────────────────────────────────────────────

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>(
  (ref) => _useMock(ref)
      ? OrdersMockDataSource()
      : OrdersRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(ref.watch(ordersRemoteDataSourceProvider)),
);

final getOrdersProvider = Provider((ref) => GetOrders(ref.watch(ordersRepositoryProvider)));
final placeOrderProvider = Provider((ref) => PlaceOrder(ref.watch(ordersRepositoryProvider)));
final payOrderProvider = Provider((ref) => PayOrder(ref.watch(ordersRepositoryProvider)));
final reorderProvider = Provider((ref) => Reorder(ref.watch(ordersRepositoryProvider)));

final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>(
  (ref) => _useMock(ref)
      ? const PaymentMockDataSource()
      : PaymentRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepositoryImpl(ref.watch(paymentRemoteDataSourceProvider)),
);

final getPaymentMethodsProvider =
    Provider((ref) => GetPaymentMethods(ref.watch(paymentRepositoryProvider)));
final calculateCheckoutSummaryProvider = Provider((_) => const CalculateCheckoutSummary());

// ── Services ─────────────────────────────────────────────────────────────────

final servicesRemoteDataSourceProvider = Provider<ServicesRemoteDataSource>(
  (ref) => _useMock(ref)
      ? const ServicesMockDataSource()
      : ServicesRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final servicesRepositoryProvider = Provider<ServicesRepository>(
  (ref) => ServicesRepositoryImpl(ref.watch(servicesRemoteDataSourceProvider)),
);

final getServicesProvider = Provider((ref) => GetServices(ref.watch(servicesRepositoryProvider)));
final requestRideProvider = Provider((ref) => RequestRide(ref.watch(servicesRepositoryProvider)));
