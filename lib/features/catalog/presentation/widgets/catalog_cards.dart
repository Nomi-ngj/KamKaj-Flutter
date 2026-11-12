import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../domain/entities/catalog_entities.dart';
import '../viewmodels/catalog_view_models.dart';

/// Square tile + label (Dashboard "Categories" row).
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: category.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDimensions.categoryTile,
              height: AppDimensions.categoryTile,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brMd,
                boxShadow: AppShadows.card,
              ),
              child: Icon(
                CategoryVisuals.icon(category.iconKey),
                color: AppColors.secondary,
                size: AppDimensions.iconXl,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(category.name, style: AppTypography.caption1, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

/// "Fresh Today" product card.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider.select((f) => f.contains(product.id)));
    return SizedBox(
      width: AppDimensions.productCardWidth,
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: product.imageUrl,
                  height: AppDimensions.productCardImageHeight,
                  width: AppDimensions.productCardWidth,
                  semanticLabel: product.name,
                ),
                PositionedDirectional(
                  top: AppSpacing.sm,
                  end: AppSpacing.sm,
                  child: AppCircleIconButton(
                    icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    tooltip: isFavorite ? 'Remove from favourites' : 'Add to favourites',
                    color: isFavorite ? AppColors.error : AppColors.textSecondary,
                    size: AppDimensions.iconBox,
                    onPressed: () => ref.read(favoritesProvider.notifier).toggle(product.id),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1Medium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    product.priceLabel,
                    style: AppTypography.caption2Medium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Nearby Shops" card.
class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.store, required this.onTap});

  final Store store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.shopCardWidth,
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: store.imageUrl,
                  width: AppDimensions.shopCardWidth,
                  height: AppDimensions.shopCardImageHeight,
                  semanticLabel: store.name,
                ),
                PositionedDirectional(
                  top: AppSpacing.sm,
                  end: AppSpacing.sm,
                  child: AppRatingChip(rating: store.rating, onDark: true),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1Medium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppTag(label: store.categoryLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width "Featured Stores" card.
class FeaturedStoreCard extends StatelessWidget {
  const FeaturedStoreCard({super.key, required this.store, required this.onTap});

  final Store store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AppNetworkImage(
                url: store.imageUrl,
                height: AppDimensions.featuredImageHeight,
                width: double.infinity,
                semanticLabel: store.name,
              ),
              PositionedDirectional(
                top: AppSpacing.md,
                start: AppSpacing.md,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: AppDimensions.iconSm,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          store.deliveryFee.isZero
                              ? 'Free Delivery'
                              : '${store.deliveryFee.format()} Delivery',
                          style: AppTypography.caption2Medium.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.name, style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: AppDimensions.iconSm,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(store.deliveryTime, style: AppTypography.caption1),
                          const SizedBox(width: AppSpacing.xl),
                          Flexible(
                            child: AppTag(
                              label: store.categoryLabel,
                              icon: Icons.storefront_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppRatingChip(rating: store.rating),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
