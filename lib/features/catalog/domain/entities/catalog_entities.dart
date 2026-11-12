import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';

/// Colour family of a category tile (mapped to tokens in the UI).
enum CategoryTint { red, green, yellow, blue, purple }

final class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.iconKey,
    this.tint = CategoryTint.red,
    this.isFeatured = false,
  });

  final String id;
  final String name;

  /// e.g. "12 Markets".
  final String subtitle;

  /// Stable key the UI maps to an icon (keeps Flutter out of the domain).
  final String iconKey;
  final CategoryTint tint;

  /// Shown on the Dashboard "Categories" row.
  final bool isFeatured;

  @override
  List<Object?> get props => [id, name, subtitle, iconKey, tint, isFeatured];
}

final class Store extends Equatable {
  const Store({
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.address,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    this.imageUrl,
    this.openUntil,
    this.menuSections = const [],
    this.tagline,
    this.categoryIds = const [],
  });

  final String id;
  final String name;

  /// e.g. "Breads & Pastries".
  final String categoryLabel;
  final String address;
  final double rating;

  /// e.g. "20-30 min".
  final String deliveryTime;
  final Money deliveryFee;
  final String? imageUrl;

  /// e.g. "8:00 PM".
  final String? openUntil;
  final List<String> menuSections;

  /// e.g. "Local Favorite".
  final String? tagline;

  /// Categories this store appears under in Explore.
  final List<String> categoryIds;

  @override
  List<Object?> get props => [
        id, name, categoryLabel, address, rating, deliveryTime, deliveryFee,
        imageUrl, openUntil, menuSections, tagline, categoryIds,
      ];
}

final class Product extends Equatable {
  const Product({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.name,
    required this.description,
    required this.price,
    this.section,
    this.unitLabel,
    this.imageUrl,
    this.shortDescription,
  });

  final String id;
  final String storeId;
  final String storeName;
  final String name;
  final String description;

  /// One-line variant text, e.g. "Whole loaf, sliced".
  final String? shortDescription;
  final Money price;

  /// Store menu section, e.g. "Pastries".
  final String? section;

  /// e.g. "KG" → "PKR 400 / KG".
  final String? unitLabel;
  final String? imageUrl;

  String get priceLabel => unitLabel == null ? price.format() : '${price.format()} / $unitLabel';

  @override
  List<Object?> get props =>
      [id, storeId, storeName, name, description, shortDescription, price, section, unitLabel, imageUrl];
}

/// Everything the Dashboard needs, loaded in one go.
final class DashboardData extends Equatable {
  const DashboardData({
    required this.categories,
    required this.dailyPicks,
    required this.nearbyShops,
    required this.featuredStores,
  });

  final List<Category> categories;
  final List<Product> dailyPicks;
  final List<Store> nearbyShops;
  final List<Store> featuredStores;

  bool get isEmpty =>
      categories.isEmpty && dailyPicks.isEmpty && nearbyShops.isEmpty && featuredStores.isEmpty;

  @override
  List<Object?> get props => [categories, dailyPicks, nearbyShops, featuredStores];
}
