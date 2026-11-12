import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/base/view_state_builder.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../../cart/presentation/viewmodels/cart_view_model.dart';
import '../../../cart/presentation/widgets/basket_bar.dart';
import '../../domain/entities/catalog_entities.dart';
import '../../domain/usecases/catalog_usecases.dart';
import '../viewmodels/catalog_view_models.dart';

class StoreDetailPage extends ConsumerStatefulWidget {
  const StoreDetailPage({super.key, required this.storeId});

  final String storeId;

  @override
  ConsumerState<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends ConsumerState<StoreDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(storeDetailViewModelProvider.notifier).load(widget.storeId),
    );
  }

  void _add(Product product) {
    final replaced = ref.read(cartProvider.notifier).add(product);
    AppToast.show(
      context,
      replaced
          ? 'Started a new basket from ${product.storeName}'
          : '${product.name} added to your basket',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeDetailViewModelProvider);
    final viewModel = ref.read(storeDetailViewModelProvider.notifier);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Store Detail',
        actions: [
          AppMoreButton(onPressed: () => AppToast.show(context, 'Store info coming soon')),
        ],
      ),
      body: ViewStateBuilder<StoreWithProducts>(
        state: state.detail,
        onRetry: viewModel.retry,
        builder: (context, data) => Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _StoreHero(store: data.store)),
                if (data.store.menuSections.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionChips(
                      sections: data.store.menuSections,
                      selected: state.selectedSection,
                      onSelected: viewModel.selectSection,
                    ),
                  ),
                if (state.visibleProducts.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyView(
                      title: 'Nothing in this section yet',
                      icon: Icons.bakery_dining_outlined,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.sm,
                      AppSpacing.page,
                      AppDimensions.buttonHeightLarge * 2,
                    ),
                    sliver: SliverList.separated(
                      itemCount: state.visibleProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xl),
                      itemBuilder: (_, i) {
                        final product = state.visibleProducts[i];
                        return _MenuItemCard(
                          product: product,
                          onTap: () => context.pushNamed(
                            RouteNames.productDetail,
                            pathParameters: {RouteParams.productId: product.id},
                          ),
                          onAdd: () => _add(product),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const PositionedDirectional(
              start: AppSpacing.page,
              end: AppSpacing.page,
              bottom: AppSpacing.xxl,
              child: SafeArea(top: false, child: BasketBar()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreHero extends StatelessWidget {
  const _StoreHero({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.storeHeroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(url: store.imageUrl, semanticLabel: store.name),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.imageGradientEnd],
              ),
            ),
          ),
          PositionedDirectional(
            start: AppSpacing.page,
            end: AppSpacing.page,
            bottom: AppSpacing.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppRatingChip(rating: store.rating, onDark: true),
                    if (store.openUntil != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Open until ${store.openUntil}',
                        style: AppTypography.caption2Medium.copyWith(color: AppColors.white),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(store.name, style: AppTypography.titleMedium.copyWith(color: AppColors.white)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.white,
                      size: AppDimensions.iconSm,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        store.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption1.copyWith(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionChips extends StatelessWidget {
  const _SectionChips({required this.sections, required this.selected, required this.onSelected});

  final List<String> sections;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.buttonHeight + AppSpacing.xxl,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.md),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => AppChoiceChip(
          label: sections[i],
          selected: sections[i] == selected,
          onTap: () => onSelected(sections[i]),
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.product, required this.onTap, required this.onAdd});

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppNetworkImage(
            url: product.imageUrl,
            width: AppDimensions.menuThumb,
            height: AppDimensions.menuThumb,
            borderRadius: AppRadius.brSm,
            semanticLabel: product.name,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTypography.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.priceLabel,
                        style: AppTypography.caption1Medium.copyWith(color: AppColors.secondary),
                      ),
                    ),
                    AppCircleIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Add ${product.name} to basket',
                      color: AppColors.white,
                      background: AppColors.secondary,
                      size: AppDimensions.iconBox,
                      onPressed: onAdd,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
