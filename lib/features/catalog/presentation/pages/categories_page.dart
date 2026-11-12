import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/base/view_state_builder.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../domain/entities/catalog_entities.dart';
import '../viewmodels/catalog_view_models.dart';
import '../widgets/catalog_cards.dart';

/// Explore tab — searchable grid of all categories.
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key, this.initialQuery});

  /// Pre-filled search, e.g. when a Dashboard category tile is tapped.
  final String? initialQuery;

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  late final _search = TextEditingController(text: widget.initialQuery ?? '');

  @override
  void initState() {
    super.initState();
    final query = widget.initialQuery;
    if (query != null && query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(categoriesViewModelProvider.notifier).search(query),
      );
    }
  }

  @override
  void didUpdateWidget(CategoriesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.initialQuery;
    if (query != null && query != oldWidget.initialQuery) {
      _search.text = query;
      ref.read(categoriesViewModelProvider.notifier).search(query);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openCategory(Category category) {
    AppBottomSheet.show<void>(
      context,
      builder: (_) => _CategoryStoresSheet(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesViewModelProvider);
    final viewModel = ref.read(categoriesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Categories',
        showBack: false,
        actions: [
          AppMoreButton(onPressed: () => AppToast.show(context, 'More filters coming soon')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.lg,
            ),
            child: TextField(
              controller: _search,
              onChanged: viewModel.search,
              textInputAction: TextInputAction.search,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              style: AppTypography.caption1,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                hintStyle: AppTypography.caption1.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.secondarySoft,
                isDense: true,
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ViewStateBuilder<List<Category>>(
              state: state.categories,
              onRetry: viewModel.retry,
              emptyTitle: 'No categories found',
              emptyMessage: 'Try a different search term.',
              emptyIcon: Icons.search_off_rounded,
              builder: (context, categories) => LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= AppBreakpoints.medium ? 4 : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.xxl,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.lg,
                      crossAxisSpacing: AppSpacing.lg,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (_, i) => _CategoryGridCard(
                      category: categories[i],
                      onTap: () => _openCategory(categories[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CategoryVisuals.colors(category.tint);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: colors.background, shape: BoxShape.circle),
            child: SizedBox.square(
              dimension: AppDimensions.iconBoxLarge,
              child: Icon(
                CategoryVisuals.icon(category.iconKey),
                color: colors.foreground,
                size: AppDimensions.iconLg,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            category.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CategoryStoresSheet extends ConsumerStatefulWidget {
  const _CategoryStoresSheet({required this.category});

  final Category category;

  @override
  ConsumerState<_CategoryStoresSheet> createState() => _CategoryStoresSheetState();
}

class _CategoryStoresSheetState extends ConsumerState<_CategoryStoresSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(categoryStoresViewModelProvider.notifier).load(widget.category.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryStoresViewModelProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Text(widget.category.name, style: AppTypography.subhead),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ViewStateBuilder<List<Store>>(
              state: state,
              onRetry: ref.read(categoryStoresViewModelProvider.notifier).retry,
              emptyTitle: 'No stores here yet',
              emptyMessage: 'We are adding new local shops every week.',
              emptyIcon: Icons.storefront_outlined,
              builder: (context, stores) => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.page),
                itemCount: stores.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
                itemBuilder: (_, i) => FeaturedStoreCard(
                  store: stores[i],
                  onTap: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.pushNamed(
                      RouteNames.storeDetail,
                      pathParameters: {RouteParams.storeId: stores[i].id},
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
