import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Back arrow + title + optional actions, as in Store/Product Detail,
/// Checkout and the address screens.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.actions = const [],
    this.onBack,
    this.showBack = true,
    this.backgroundColor = AppColors.background,
    this.centerTitle = false,
  });

  final String? title;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBack;
  final Color backgroundColor;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: AppDimensions.appBarHeight,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      titleSpacing: showBack ? 0 : AppSpacing.page,
      leading: showBack && (canPop || onBack != null)
          ? AppBackButton(onPressed: onBack)
          : null,
      title: title == null ? null : Text(title!, style: AppTypography.subhead),
      actions: [...actions, const SizedBox(width: AppSpacing.sm)],
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.arrow_forward_rounded
            : Icons.arrow_back_rounded,
        color: AppColors.textPrimary,
      ),
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}

/// Overflow "more" icon used in app bars.
class AppMoreButton extends StatelessWidget {
  const AppMoreButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'More options',
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
      onPressed: onPressed,
    );
  }
}
