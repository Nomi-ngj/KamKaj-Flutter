import '../../../../core/utils/json_reader.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/catalog_entities.dart';

/// JSON ⇄ entity mapping for the catalog API. Prices are minor units.
abstract final class CatalogMapper {
  static Category category(Map<String, Object?> json) => Category(
        id: json.readString('id'),
        name: json.readString('name'),
        subtitle: json.readStringOrNull('subtitle') ?? '',
        iconKey: json.readStringOrNull('icon') ?? 'store',
        tint: CategoryTint.values.firstWhere(
          (t) => t.name == json.readStringOrNull('tint'),
          orElse: () => CategoryTint.red,
        ),
        isFeatured: json.readBool('featured'),
      );

  static Store store(Map<String, Object?> json) => Store(
        id: json.readString('id'),
        name: json.readString('name'),
        categoryLabel: json.readStringOrNull('category') ?? '',
        address: json.readStringOrNull('address') ?? '',
        rating: json.readDouble('rating', fallback: 0),
        deliveryTime: json.readStringOrNull('deliveryTime') ?? '',
        deliveryFee: Money(json.readInt('deliveryFee', fallback: 0)),
        imageUrl: json.readStringOrNull('imageUrl'),
        openUntil: json.readStringOrNull('openUntil'),
        menuSections: json.readStringList('menuSections'),
        tagline: json.readStringOrNull('tagline'),
        categoryIds: json.readStringList('categoryIds'),
      );

  static Product product(Map<String, Object?> json) => Product(
        id: json.readString('id'),
        storeId: json.readString('storeId'),
        storeName: json.readStringOrNull('storeName') ?? '',
        name: json.readString('name'),
        description: json.readStringOrNull('description') ?? '',
        shortDescription: json.readStringOrNull('shortDescription'),
        price: Money(json.readInt('price')),
        section: json.readStringOrNull('section'),
        unitLabel: json.readStringOrNull('unit'),
        imageUrl: json.readStringOrNull('imageUrl'),
      );
}
