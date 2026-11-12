import 'package:flutter/material.dart';

import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';

/// Peach background, centred 365-pt column, keyboard-safe scrolling and an
/// optional pinned footer — the shared layout of every auth screen.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.footer,
    this.showBack = false,
  });

  final List<Widget> children;
  final Widget? footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: showBack
          ? const AppAppBar(backgroundColor: AppColors.backgroundWarm)
          : null,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // The form is laid out normally (no intrinsic sizing), so it can
              // never overflow; only the footer fills the remaining space and
              // is pushed to the bottom on tall screens.
              SliverToBoxAdapter(
                child: _constrain(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              if (footer != null)
                // Pushes the footer to the bottom on tall screens without
                // intrinsic sizing (which mis-measures the wrapping footer).
                SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final remaining =
                        constraints.viewportMainAxisExtent -
                        constraints.precedingScrollExtent;
                    return SliverToBoxAdapter(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: remaining > 0 ? remaining : 0,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _constrain(
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AppSpacing.xxl),
                                footer!,
                                const SizedBox(height: AppSpacing.xxl),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _constrain(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageAuth),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDimensions.maxFormWidth),
        child: child,
      ),
    ),
  );
}

/// Bold title + orange subtitle block.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.topSpacing,
  });

  final String title;
  final String? subtitle;
  final double? topSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: topSpacing ?? AppSpacing.giant),
        Semantics(
          header: true,
          child: AppText.header(title, textAlign: TextAlign.center),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppText.subtitle(subtitle!, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

/// "Don't have an account?  Sign Up" style footer.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: AppTypography.caption1),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: Text(
            action,
            style: AppTypography.caption1.copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}

/// Inline error banner shown under forms.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return AnimatedSize(
      duration: AppDurations.fast,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption2Medium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Vertical gap between form fields (Figma: 24).
const kAuthFieldGap = SizedBox(height: AppSpacing.xxl);
