import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/errors/failure.dart';
import 'package:kamkaj_pro/core/errors/result.dart';
import 'package:kamkaj_pro/features/catalog/data/datasources/catalog_mock_data.dart';
import 'package:kamkaj_pro/features/catalog/domain/entities/catalog_entities.dart';
import 'package:kamkaj_pro/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:kamkaj_pro/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatalog extends Mock implements CatalogRepository {}

void main() {
  late _MockCatalog repository;

  setUp(() {
    repository = _MockCatalog();
    when(() => repository.getCategories())
        .thenAnswer((_) async => const Result.success(CatalogMockData.categories));
    when(() => repository.getDailyPicks()).thenAnswer((_) async => const Result.success(<Product>[]));
    when(() => repository.getNearbyShops())
        .thenAnswer((_) async => Result.success(CatalogMockData.stores.take(2).toList()));
    when(() => repository.getFeaturedStores())
        .thenAnswer((_) async => const Result.failure(NetworkFailure()));
  });

  test('shows only featured categories and tolerates partial failures', () async {
    final result = await GetDashboard(repository)();

    final data = result.valueOrNull!;
    expect(data.categories.map((c) => c.name), ['Food', 'Grocery', 'Pharmacy', 'Flowers']);
    expect(data.nearbyShops, hasLength(2));
    expect(data.featuredStores, isEmpty);
  });

  test('fails only when every section fails', () async {
    when(() => repository.getCategories())
        .thenAnswer((_) async => const Result.failure(NetworkFailure()));
    when(() => repository.getDailyPicks())
        .thenAnswer((_) async => const Result.failure(NetworkFailure()));
    when(() => repository.getNearbyShops())
        .thenAnswer((_) async => const Result.failure(NetworkFailure()));

    final result = await GetDashboard(repository)();

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('SearchCategories filters case-insensitively', () async {
    final result = await SearchCategories(repository)('flow');
    expect(result.valueOrNull!.map((c) => c.name), containsAll(<String>['Flowers', 'Flower Shop']));
  });
}
