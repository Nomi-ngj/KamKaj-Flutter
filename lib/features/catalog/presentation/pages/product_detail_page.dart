import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/base/view_state_builder.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../cart/presentation/viewmodels/cart_view_model.dart';
import '../../domain/entities/catalog_entities.dart';
import '../viewmodels/catalog_view_models.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  static const _maxNoteLength = 140;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(productDetailViewModelProvider.notifier).load(widget.productId),
    );
  }

  void _addToCart(Product product) {
    final state = ref.read(productDetailViewModelProvider);
    final note = state.note.trim();
    ref.read(cartProvider.notifier).add(
          product,
          quantity: state.quantity,
          note: note.isEmpty ? null : note,
        );
    AppToast.show(context, '${state.quantity} × ${product.name} added to your basket');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailViewModelProvider);
    final viewModel = ref.read(productDetailViewModelProvider.notifier);
    final product = state.product.dataOrNull;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Product Detail',
        actions: [
          AppMoreButton(onPressed: () => AppToast.show(context, 'Report an issue coming soon')),
        ],
      ),
      body: ViewStateBuilder<Product>(
        state: state.product,
        onRetry: viewModel.retry,
        builder: (context, product) => GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _ProductHero(product: product),
              Transform.translate(
                offset: const Offset(0, -AppSpacing.xxl),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.sheetTop,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.xxl,
                      AppSpacing.page,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(product.name, style: AppTypography.subhead)),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              product.priceLabel,
                              style: AppTypography.titleMedium.copyWith(color: AppColors.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        InkWell(
                          onTap: () => context.pushReplacementNamed(
                            RouteNames.storeDetail,
                            pathParameters: {RouteParams.storeId: product.storeId},
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: AppSpacing.md,
                                backgroundColor: AppColors.tintGreen,
                                child: Icon(
                                  Icons.storefront_outlined,
                                  size: AppDimensions.iconXs,
                                  color: AppColors.tintGreenIcon,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text('by ', style: AppTypography.caption1),
                              Text(
                                product.storeName,
                                style: AppTypography.caption1Medium.copyWith(
                                  color: AppColors.tintGreenIcon,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          product.description,
                          style: AppTypography.caption1.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Row(
                          children: [
                            Expanded(child: Text('Quantity', style: AppTypography.subhead)),
                            AppQuantityStepper(
                              quantity: state.quantity,
                              max: Cart.maxQuantityPerItem,
                              onChanged: viewModel.setQuantity,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text('Special Instructions', style: AppTypography.subhead),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          onChanged: viewModel.setNote,
                          maxLines: 4,
                          minLines: 4,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(_maxNoteLength),
                          ],
                          style: AppTypography.caption1,
                          decoration: InputDecoration(
                            hintText: 'E.g. No sprinkles, please!',
                            hintStyle: AppTypography.caption1.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceMuted,
                            border: const OutlineInputBorder(
                              borderRadius: AppRadius.brMd,
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: product == null
          ? null
          : _AddToCartBar(
              total: (product.price * state.quantity).format(),
              onAdd: () => _addToCart(product),
            ),
    );
  }
}

class _ProductHero extends ConsumerWidget {
  const _ProductHero({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider.select((f) => f.contains(product.id)));
    return SizedBox(
      height: AppDimensions.productHeroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(url: product.imageUrl, semanticLabel: product.name),
          PositionedDirectional(
            top: AppSpacing.lg,
            end: AppSpacing.lg,
            child: Row(
              children: [
                AppCircleIconButton(
                  icon: Icons.share_outlined,
                  tooltip: 'Share',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '${product.name} — ${product.storeName}'));
                    AppToast.show(context, 'Product details copied to clipboard');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                AppCircleIconButton(
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  tooltip: isFavorite ? 'Remove from favourites' : 'Add to favourites',
                  color: isFavorite ? AppColors.error : AppColors.textPrimary,
                  onPressed: () => ref.read(favoritesProvider.notifier).toggle(product.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({required this.total, required this.onAdd});

  final String total;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.lg,
        ),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppRadius.brMd,
          shadows: AppShadows.floating,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: AppTypography.caption1),
                  Text(total, style: AppTypography.titleSmall),
                ],
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: AppButton(
                  label: 'Add to Cart',
                  leadingIcon: Icons.shopping_basket_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: onAdd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
