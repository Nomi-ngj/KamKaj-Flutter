import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/base/view_state.dart';
import '../../../../design_system/tokens/app_durations.dart';
import '../../domain/entities/catalog_entities.dart';
import '../../domain/usecases/catalog_usecases.dart';

// ── Favourites (session scoped) ─────────────────────────────────────────────

final class FavoritesViewModel extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String productId) {
    final next = {...state};
    if (!next.remove(productId)) next.add(productId);
    state = Set.unmodifiable(next);
  }
}

final favoritesProvider = NotifierProvider<FavoritesViewModel, Set<String>>(FavoritesViewModel.new);

// ── Categories (Explore tab) ────────────────────────────────────────────────

final class CategoriesState extends Equatable {
  const CategoriesState({this.query = '', this.categories = const ViewLoading()});

  final String query;
  final ViewState<List<Category>> categories;

  CategoriesState copyWith({String? query, ViewState<List<Category>>? categories}) =>
      CategoriesState(query: query ?? this.query, categories: categories ?? this.categories);

  @override
  List<Object?> get props => [query, categories];
}

final class CategoriesViewModel extends Notifier<CategoriesState> {
  Timer? _debounce;

  @override
  CategoriesState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_load);
    return const CategoriesState();
  }

  void search(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, _load);
  }

  Future<void> retry() => _load();

  Future<void> _load() async {
    final query = state.query;
    if (state.categories.dataOrNull == null) {
      state = state.copyWith(categories: const ViewLoading());
    }
    final result = await ref.read(searchCategoriesProvider).call(query);
    if (!ref.mounted || query != state.query) return;
    state = state.copyWith(
      categories: result.when(
        success: (list) => list.isEmpty ? const ViewEmpty() : ViewSuccess(list),
        failure: (f) => ViewFailure(f),
      ),
    );
  }
}

final categoriesViewModelProvider =
    NotifierProvider.autoDispose<CategoriesViewModel, CategoriesState>(CategoriesViewModel.new);

// ── Store detail ────────────────────────────────────────────────────────────

final class StoreDetailState extends Equatable {
  const StoreDetailState({this.detail = const ViewLoading(), this.selectedSection});

  final ViewState<StoreWithProducts> detail;
  final String? selectedSection;

  List<Product> get visibleProducts {
    final data = detail.dataOrNull;
    if (data == null) return const [];
    final section = selectedSection;
    if (section == null) return data.products;
    return data.products.where((p) => p.section == section).toList(growable: false);
  }

  StoreDetailState copyWith({ViewState<StoreWithProducts>? detail, String? selectedSection}) =>
      StoreDetailState(
        detail: detail ?? this.detail,
        selectedSection: selectedSection ?? this.selectedSection,
      );

  @override
  List<Object?> get props => [detail, selectedSection];
}

final class StoreDetailViewModel extends Notifier<StoreDetailState> {
  String? _storeId;

  @override
  StoreDetailState build() => const StoreDetailState();

  Future<void> load(String storeId) async {
    _storeId = storeId;
    state = state.copyWith(detail: const ViewLoading());
    final result = await ref.read(getStoreDetailProvider).call(storeId);
    if (!ref.mounted) return;
    state = result.when(
      success: (data) => StoreDetailState(
        detail: ViewSuccess(data),
        selectedSection: data.store.menuSections.firstOrNull,
      ),
      failure: (f) => state.copyWith(detail: ViewFailure(f)),
    );
  }

  Future<void> retry() async {
    final id = _storeId;
    if (id != null) await load(id);
  }

  void selectSection(String section) => state = state.copyWith(selectedSection: section);
}

final storeDetailViewModelProvider =
    NotifierProvider.autoDispose<StoreDetailViewModel, StoreDetailState>(StoreDetailViewModel.new);

// ── Product detail ──────────────────────────────────────────────────────────

final class ProductDetailState extends Equatable {
  const ProductDetailState({this.product = const ViewLoading(), this.quantity = 1, this.note = ''});

  final ViewState<Product> product;
  final int quantity;
  final String note;

  ProductDetailState copyWith({ViewState<Product>? product, int? quantity, String? note}) =>
      ProductDetailState(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
        note: note ?? this.note,
      );

  @override
  List<Object?> get props => [product, quantity, note];
}

final class ProductDetailViewModel extends Notifier<ProductDetailState> {
  String? _productId;

  @override
  ProductDetailState build() => const ProductDetailState();

  Future<void> load(String productId) async {
    _productId = productId;
    state = state.copyWith(product: const ViewLoading());
    final result = await ref.read(getProductProvider).call(productId);
    if (!ref.mounted) return;
    state = state.copyWith(
      product: result.when(success: (v) => ViewSuccess(v), failure: (f) => ViewFailure(f)),
    );
  }

  Future<void> retry() async {
    final id = _productId;
    if (id != null) await load(id);
  }

  void setQuantity(int quantity) => state = state.copyWith(quantity: quantity);

  void setNote(String note) => state = state.copyWith(note: note);
}

final productDetailViewModelProvider = NotifierProvider.autoDispose<ProductDetailViewModel,
    ProductDetailState>(ProductDetailViewModel.new);

// ── Stores in a category ────────────────────────────────────────────────────

final class CategoryStoresViewModel extends Notifier<ViewState<List<Store>>> {
  String? _categoryId;

  @override
  ViewState<List<Store>> build() => const ViewLoading();

  Future<void> load(String categoryId) async {
    _categoryId = categoryId;
    state = const ViewLoading();
    final result = await ref.read(getStoresByCategoryProvider).call(categoryId);
    if (!ref.mounted) return;
    state = result.when(
      success: (stores) => stores.isEmpty ? const ViewEmpty() : ViewSuccess(stores),
      failure: (f) => ViewFailure(f),
    );
  }

  Future<void> retry() async {
    final id = _categoryId;
    if (id != null) await load(id);
  }
}

final categoryStoresViewModelProvider =
    NotifierProvider.autoDispose<CategoryStoresViewModel, ViewState<List<Store>>>(
  CategoryStoresViewModel.new,
);
