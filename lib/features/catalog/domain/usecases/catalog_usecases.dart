import '../../../../core/errors/result.dart';
import '../entities/catalog_entities.dart';
import '../repositories/catalog_repository.dart';

/// Loads the Dashboard sections in parallel. Fails only if every section
/// fails; otherwise shows what loaded.
final class GetDashboard {
  const GetDashboard(this._repository);
  final CatalogRepository _repository;

  Future<Result<DashboardData>> call() async {
    final results = await Future.wait<Result<Object>>([
      _repository.getCategories(),
      _repository.getDailyPicks(),
      _repository.getNearbyShops(),
      _repository.getFeaturedStores(),
    ]);
    if (results.every((r) => !r.isSuccess)) {
      return Result.failure(results.first.failureOrNull!);
    }
    List<T> list<T>(int i) => (results[i].valueOrNull as List<T>?) ?? <T>[];
    return Result.success(
      DashboardData(
        categories: list<Category>(0).where((c) => c.isFeatured).toList(growable: false),
        dailyPicks: list<Product>(1),
        nearbyShops: list<Store>(2),
        featuredStores: list<Store>(3),
      ),
    );
  }
}

/// Categories filtered by a search query (case-insensitive).
final class SearchCategories {
  const SearchCategories(this._repository);
  final CatalogRepository _repository;

  Future<Result<List<Category>>> call([String query = '']) async {
    final result = await _repository.getCategories();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return result;
    return result.when(
      success: (all) => Result.success(
        all.where((c) => c.name.toLowerCase().contains(q)).toList(growable: false),
      ),
      failure: (f) => Result.failure(f),
    );
  }
}

final class GetStoresByCategory {
  const GetStoresByCategory(this._repository);
  final CatalogRepository _repository;

  /// Highest rated first.
  Future<Result<List<Store>>> call(String categoryId) async {
    final result = await _repository.getStoresByCategory(categoryId);
    return result.when(
      success: (stores) => Result.success([...stores]..sort((a, b) => b.rating.compareTo(a.rating))),
      failure: (f) => Result.failure(f),
    );
  }
}

final class StoreWithProducts {
  const StoreWithProducts(this.store, this.products);
  final Store store;
  final List<Product> products;
}

final class GetStoreDetail {
  const GetStoreDetail(this._repository);
  final CatalogRepository _repository;

  Future<Result<StoreWithProducts>> call(String storeId) async {
    final results = await Future.wait<Result<Object>>([
      _repository.getStore(storeId),
      _repository.getStoreProducts(storeId),
    ]);
    final failure = results.map((r) => r.failureOrNull).nonNulls.firstOrNull;
    if (failure != null) return Result.failure(failure);
    return Result.success(
      StoreWithProducts(
        results[0].valueOrNull! as Store,
        results[1].valueOrNull! as List<Product>,
      ),
    );
  }
}

final class GetProduct {
  const GetProduct(this._repository);
  final CatalogRepository _repository;

  Future<Result<Product>> call(String productId) => _repository.getProduct(productId);
}
