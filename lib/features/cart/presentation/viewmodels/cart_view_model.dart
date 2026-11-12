import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/session_view_model.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../domain/entities/cart.dart';

/// App-wide basket. Kept alive for the session.
final class CartViewModel extends Notifier<Cart> {
  @override
  Cart build() {
    // A new session always starts with an empty basket.
    ref.watch(sessionProvider.select((s) => s.user?.id));
    return const Cart();
  }

  /// Returns `true` if adding replaced a basket from another store.
  bool add(Product product, {int quantity = 1, String? note}) {
    final replaced = state.belongsToOtherStore(product);
    state = state.add(product, quantity: quantity, note: note);
    return replaced;
  }

  void setQuantity(String productId, int quantity) =>
      state = state.setQuantity(productId, quantity);

  void remove(String productId) => state = state.remove(productId);

  void clear() => state = const Cart();
}

final cartProvider = NotifierProvider<CartViewModel, Cart>(CartViewModel.new);
