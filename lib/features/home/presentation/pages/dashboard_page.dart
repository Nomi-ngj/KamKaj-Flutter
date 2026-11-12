import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/base/view_state_builder.dart';
import '../../../../design_system/assets/app_images.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../../address/presentation/viewmodels/address_view_models.dart';
import '../../../cart/presentation/viewmodels/cart_view_model.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../catalog/presentation/widgets/catalog_cards.dart';
import '../viewmodels/dashboard_view_model.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final viewModel = ref.read(dashboardViewModelProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _DashboardHeader(),
            Expanded(
              child: ViewStateBuilder<DashboardData>(
                state: state,
                onRetry: viewModel.load,
                emptyTitle: 'No stores near you yet',
                emptyMessage: "We're expanding fast. Check back soon!",
                builder: (context, data) => RefreshIndicator(
                  onRefresh: viewModel.load,
                  child: _DashboardContent(data: data),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final street = ref.watch(defaultAddressProvider)?.street ?? 'Your Street Name Here';
    final basketCount = ref.watch(cartProvider.select((c) => c.itemCount));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          const AppAssetImage(
            path: AppImages.appLogo,
            width: AppDimensions.iconBoxLarge,
            height: AppDimensions.iconBox,
            placeholderIcon: Icons.local_shipping_rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: InkWell(
              onTap: () => context.pushNamed(RouteNames.addresses),
              borderRadius: AppRadius.brSm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: AppTypography.titleMedium.copyWith(color: AppColors.secondary),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: AppDimensions.iconSm,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(
                          street,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption2Medium,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: AppDimensions.iconSm),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Badge(
            isLabelVisible: basketCount > 0,
            label: Text('$basketCount'),
            backgroundColor: AppColors.secondary,
            child: IconButton(
              tooltip: 'Basket',
              icon: const Icon(Icons.shopping_basket_outlined, color: AppColors.textPrimary),
              onPressed: basketCount == 0
                  ? () => AppToast.show(context, 'Your basket is empty')
                  : () => context.pushNamed(RouteNames.checkout),
            ),
          ),
          AppCircleIconButton(
            icon: Icons.person_rounded,
            tooltip: 'Profile',
            color: AppColors.white,
            background: AppColors.primary,
            onPressed: () => context.goNamed(RouteNames.profile),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final DashboardData data;

  void _openStore(BuildContext context, Store store) =>
      context.pushNamed(RouteNames.storeDetail, pathParameters: {RouteParams.storeId: store.id});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (data.categories.isNotEmpty) ...[
          _Section(
            child: AppSectionHeader(
              title: 'Categories',
              actionLabel: 'View All',
              onAction: () => context.goNamed(RouteNames.explore),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final category in data.categories.take(4))
                  CategoryTile(
                    category: category,
                    onTap: () => context.goNamed(
                      RouteNames.explore,
                      queryParameters: {RouteParams.category: category.name},
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (data.dailyPicks.isNotEmpty) ...[
          const _Section(
            child: AppSectionHeader(
              title: 'Fresh Today',
              trailing: AppStatusBadge(
                label: 'Daily Picks',
                foreground: AppColors.white,
                background: AppColors.primary,
              ),
            ),
          ),
          _HorizontalList(
            height: AppDimensions.productListHeight,
            itemCount: data.dailyPicks.length,
            itemBuilder: (context, i) {
              final product = data.dailyPicks[i];
              return ProductCard(
                product: product,
                onTap: () => context.pushNamed(
                  RouteNames.productDetail,
                  pathParameters: {RouteParams.productId: product.id},
                ),
              );
            },
          ),
        ],
        if (data.nearbyShops.isNotEmpty) ...[
          _Section(
            child: AppSectionHeader(
              title: 'Nearby Shops',
              actionLabel: 'View All',
              onAction: () => context.goNamed(RouteNames.explore),
            ),
          ),
          _HorizontalList(
            height: AppDimensions.shopListHeight,
            itemCount: data.nearbyShops.length,
            itemBuilder: (context, i) => ShopCard(
              store: data.nearbyShops[i],
              onTap: () => _openStore(context, data.nearbyShops[i]),
            ),
          ),
        ],
        if (data.featuredStores.isNotEmpty) ...[
          const _Section(child: AppSectionHeader(title: 'Featured Stores')),
          for (final store in data.featuredStores)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              child: FeaturedStoreCard(store: store, onTap: () => _openStore(context, store)),
            ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xxl,
        AppSpacing.page,
        AppSpacing.md,
      ),
      child: child,
    );
  }
}

class _HorizontalList extends StatelessWidget {
  const _HorizontalList({
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.page,
          vertical: AppSpacing.xs,
        ),
        clipBehavior: Clip.none,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
