import '../../../../core/errors/result.dart';
import '../entities/catalog_entities.dart';

abstract interface class CatalogRepository {
  Future<Result<List<Category>>> getCategories();
  Future<Result<List<Product>>> getDailyPicks();
  Future<Result<List<Store>>> getNearbyShops();
  Future<Result<List<Store>>> getFeaturedStores();
  Future<Result<List<Store>>> getStoresByCategory(String categoryId);
  Future<Result<Store>> getStore(String storeId);
  Future<Result<List<Product>>> getStoreProducts(String storeId);
  Future<Result<Product>> getProduct(String productId);
}
