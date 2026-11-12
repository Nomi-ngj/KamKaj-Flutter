import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_data_sources.dart';

/// Categories rarely change, so they are cached in memory for the session.
final class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._remote);

  final CatalogRemoteDataSource _remote;
  List<Category>? _categoriesCache;

  @override
  Future<Result<List<Category>>> getCategories() => ErrorMapper.guard(() async {
        return _categoriesCache ??= await _remote.categories();
      });

  @override
  Future<Result<List<Product>>> getDailyPicks() => ErrorMapper.guard(_remote.dailyPicks);

  @override
  Future<Result<List<Store>>> getNearbyShops() => ErrorMapper.guard(_remote.nearbyShops);

  @override
  Future<Result<List<Store>>> getFeaturedStores() => ErrorMapper.guard(_remote.featuredStores);

  @override
  Future<Result<List<Store>>> getStoresByCategory(String categoryId) =>
      ErrorMapper.guard(() => _remote.storesByCategory(categoryId));

  @override
  Future<Result<Store>> getStore(String storeId) => ErrorMapper.guard(() => _remote.store(storeId));

  @override
  Future<Result<List<Product>>> getStoreProducts(String storeId) =>
      ErrorMapper.guard(() => _remote.storeProducts(storeId));

  @override
  Future<Result<Product>> getProduct(String productId) =>
      ErrorMapper.guard(() => _remote.product(productId));
}
