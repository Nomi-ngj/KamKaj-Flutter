import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/utils/money.dart';
import 'package:kamkaj_pro/features/cart/domain/entities/cart.dart';
import 'package:kamkaj_pro/features/catalog/domain/entities/catalog_entities.dart';

Product _product(String id, {String storeId = 's1', num price = 100}) => Product(
      id: id,
      storeId: storeId,
      storeName: 'Store $storeId',
      name: 'Product $id',
      description: '',
      price: Money.fromMajor(price),
    );

void main() {
  test('adding the same product increases its quantity', () {
    final cart = const Cart().add(_product('a')).add(_product('a'), quantity: 2);
    expect(cart.items, hasLength(1));
    expect(cart.quantityOf('a'), 3);
    expect(cart.itemCount, 3);
    expect(cart.subtotal, Money.fromMajor(300));
  });

  test('subtotal sums all line totals', () {
    final cart = const Cart()
        .add(_product('a', price: 850))
        .add(_product('b', price: 450), quantity: 2);
    expect(cart.subtotal, Money.fromMajor(1750));
  });

  test('a product from another store starts a new basket', () {
    final cart = const Cart().add(_product('a')).add(_product('b', storeId: 's2'));
    expect(cart.storeId, 's2');
    expect(cart.items.single.product.id, 'b');
  });

  test('quantity is clamped and zero removes the item', () {
    var cart = const Cart().add(_product('a'), quantity: 500);
    expect(cart.quantityOf('a'), Cart.maxQuantityPerItem);
    cart = cart.setQuantity('a', 0);
    expect(cart.isEmpty, isTrue);
    expect(cart.storeId, isNull);
  });
}
