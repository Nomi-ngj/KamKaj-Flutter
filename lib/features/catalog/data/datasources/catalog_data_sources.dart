import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/catalog_entities.dart';
import '../models/catalog_models.dart';
import 'catalog_mock_data.dart';

abstract interface class CatalogRemoteDataSource {
  Future<List<Category>> categories();
  Future<List<Product>> dailyPicks();
  Future<List<Store>> nearbyShops();
  Future<List<Store>> featuredStores();
  Future<List<Store>> storesByCategory(String categoryId);
  Future<Store> store(String id);
  Future<List<Product>> storeProducts(String id);
  Future<Product> product(String id);
}

final class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  const CatalogRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<List<Category>> categories() async =>
      (await _client.getList(ApiEndpoints.categories)).map(CatalogMapper.category).toList();

  @override
  Future<List<Product>> dailyPicks() async =>
      (await _client.getList(ApiEndpoints.dailyPicks)).map(CatalogMapper.product).toList();

  @override
  Future<List<Store>> nearbyShops() async =>
      (await _client.getList(ApiEndpoints.nearbyShops)).map(CatalogMapper.store).toList();

  @override
  Future<List<Store>> featuredStores() async =>
      (await _client.getList(ApiEndpoints.featuredStores)).map(CatalogMapper.store).toList();

  @override
  Future<List<Store>> storesByCategory(String categoryId) async => (await _client.getList(
        ApiEndpoints.stores,
        query: {'category': categoryId},
      ))
          .map(CatalogMapper.store)
          .toList();

  @override
  Future<Store> store(String id) async => CatalogMapper.store(await _client.get(ApiEndpoints.store(id)));

  @override
  Future<List<Product>> storeProducts(String id) async =>
      (await _client.getList(ApiEndpoints.storeProducts(id))).map(CatalogMapper.product).toList();

  @override
  Future<Product> product(String id) async =>
      CatalogMapper.product(await _client.get(ApiEndpoints.product(id)));
}

/// Serves the Figma content until the API exists.
final class CatalogMockDataSource implements CatalogRemoteDataSource {
  const CatalogMockDataSource({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;

  Future<T> _respond<T>(T Function() value) async {
    await Future<void>.delayed(latency);
    return value();
  }

  @override
  Future<List<Category>> categories() => _respond(() => CatalogMockData.categories);

  @override
  Future<List<Product>> dailyPicks() => _respond(
        () => CatalogMockData.products
            .where((p) => CatalogMockData.dailyPickIds.contains(p.id))
            .toList(),
      );

  @override
  Future<List<Store>> nearbyShops() => _respond(
        () => CatalogMockData.stores
            .where((s) => CatalogMockData.nearbyStoreIds.contains(s.id))
            .toList(),
      );

  @override
  Future<List<Store>> featuredStores() => _respond(
        () => CatalogMockData.stores
            .where((s) => CatalogMockData.featuredStoreIds.contains(s.id))
            .toList(),
      );

  @override
  Future<List<Store>> storesByCategory(String categoryId) => _respond(
        () => CatalogMockData.stores.where((s) => s.categoryIds.contains(categoryId)).toList(),
      );

  @override
  Future<Store> store(String id) => _respond(
        () => CatalogMockData.stores.firstWhere(
          (s) => s.id == id,
          orElse: () => throw const NotFoundException(),
        ),
      );

  @override
  Future<List<Product>> storeProducts(String id) =>
      _respond(() => CatalogMockData.products.where((p) => p.storeId == id).toList());

  @override
  Future<Product> product(String id) => _respond(
        () => CatalogMockData.products.firstWhere(
          (p) => p.id == id,
          orElse: () => throw const NotFoundException(),
        ),
      );
}
