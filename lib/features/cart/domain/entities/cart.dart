import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';

final class CartItem extends Equatable {
  const CartItem({required this.product, required this.quantity, this.note});

  final Product product;
  final int quantity;

  /// "Special Instructions" from Product Detail.
  final String? note;

  Money get total => product.price * quantity;

  CartItem copyWith({int? quantity, String? note}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity, note: note ?? this.note);

  @override
  List<Object?> get props => [product, quantity, note];
}

/// A basket from a single store. Business rules live here, not in widgets.
final class Cart extends Equatable {
  const Cart({this.items = const [], this.storeId, this.storeName});

  static const int maxQuantityPerItem = 99;

  final List<CartItem> items;
  final String? storeId;
  final String? storeName;

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  Money get subtotal => items.fold(const Money.zero(), (sum, item) => sum + item.total);

  int quantityOf(String productId) =>
      items.where((i) => i.product.id == productId).fold(0, (s, i) => s + i.quantity);

  bool belongsToOtherStore(Product product) => storeId != null && storeId != product.storeId;

  /// Adds [quantity] of [product]. A product from another store starts a new cart.
  Cart add(Product product, {int quantity = 1, String? note}) {
    final base = belongsToOtherStore(product) ? const Cart() : this;
    final index = base.items.indexWhere((i) => i.product.id == product.id);
    final updated = [...base.items];
    if (index == -1) {
      updated.add(CartItem(product: product, quantity: _clamp(quantity), note: note));
    } else {
      final existing = updated[index];
      updated[index] = existing.copyWith(
        quantity: _clamp(existing.quantity + quantity),
        note: note,
      );
    }
    return Cart(items: updated, storeId: product.storeId, storeName: product.storeName);
  }

  Cart setQuantity(String productId, int quantity) {
    if (quantity <= 0) return remove(productId);
    return _copyItems([
      for (final item in items)
        item.product.id == productId ? item.copyWith(quantity: _clamp(quantity)) : item,
    ]);
  }

  Cart remove(String productId) =>
      _copyItems(items.where((i) => i.product.id != productId).toList(growable: false));

  Cart _copyItems(List<CartItem> next) => next.isEmpty
      ? const Cart()
      : Cart(items: next, storeId: storeId, storeName: storeName);

  static int _clamp(int quantity) => quantity.clamp(1, maxQuantityPerItem);

  @override
  List<Object?> get props => [items, storeId, storeName];
}
