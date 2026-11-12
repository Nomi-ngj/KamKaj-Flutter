import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/app/config/app_config.dart';
import 'package:kamkaj_pro/app/config/environment.dart';
import 'package:kamkaj_pro/app/di/injection.dart';
import 'package:kamkaj_pro/core/storage/secure_storage.dart';
import 'package:kamkaj_pro/design_system/theme/app_theme.dart';
import 'package:kamkaj_pro/features/address/data/datasources/address_data_sources.dart';
import 'package:kamkaj_pro/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:kamkaj_pro/features/catalog/data/datasources/catalog_data_sources.dart';
import 'package:kamkaj_pro/features/orders/data/datasources/orders_data_sources.dart';
import 'package:kamkaj_pro/features/services/data/datasources/services_data_sources.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage that lives in memory (no platform channel in tests).
final class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

const testConfig = AppConfig(
  environment: Environment.development,
  apiBaseUrl: 'https://test.invalid',
  useMockApi: true,
  connectTimeout: Duration(seconds: 1),
  receiveTimeout: Duration(seconds: 1),
);

/// A container where the whole app runs in-memory with zero latency.
Future<ProviderContainer> createTestContainer({
  Map<String, Object> prefs = const {},
  SecureStorage? secureStorage,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPreferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(testConfig),
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      secureStorageProvider.overrideWithValue(secureStorage ?? InMemorySecureStorage()),
      authRemoteDataSourceProvider.overrideWithValue(AuthMockDataSource(latency: Duration.zero)),
      catalogRemoteDataSourceProvider
          .overrideWithValue(const CatalogMockDataSource(latency: Duration.zero)),
      addressRemoteDataSourceProvider
          .overrideWithValue(AddressMockDataSource(latency: Duration.zero)),
      ordersRemoteDataSourceProvider
          .overrideWithValue(OrdersMockDataSource(latency: Duration.zero)),
      servicesRemoteDataSourceProvider
          .overrideWithValue(const ServicesMockDataSource(latency: Duration.zero)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Pumps [child] inside the app theme, backed by [container].
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  required ProviderContainer container,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: child),
    ),
  );
}
