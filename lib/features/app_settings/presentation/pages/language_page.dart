import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/app_language.dart';
import '../viewmodels/settings_view_models.dart';

/// "Choose your language". Used during onboarding and from Profile.
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key, this.fromSettings = false});

  /// When opened from Profile, pop back instead of continuing to Sign In.
  final bool fromSettings;

  Future<void> _select(BuildContext context, WidgetRef ref, AppLanguage language) async {
    await ref.read(languageProvider.notifier).select(language);
    if (!context.mounted) return;
    if (fromSettings) {
      context.pop();
    } else {
      context.goNamed(RouteNames.signIn);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: fromSettings ? const AppAppBar(backgroundColor: AppColors.backgroundWarm) : null,
      body: SafeArea(
        child: AppResponsiveCenter(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
            children: [
              SizedBox(height: fromSettings ? AppSpacing.xxl : AppSpacing.giant * 2),
              Semantics(
                header: true,
                child: const AppText(
                  'Choose your language',
                  variant: AppTextVariant.header3,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.giant + AppSpacing.xxl),
              for (final language in AppLanguage.values) ...[
                _LanguageButton(
                  language: language,
                  selected: language == selected,
                  onTap: () => _select(context, ref, language),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.language, required this.selected, required this.onTap});

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: language.nativeName,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.secondary,
        borderRadius: AppRadius.brSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brSm,
          child: SizedBox(
            height: AppDimensions.languageButtonHeight,
            child: Center(
              child: Text(
                language.nativeName,
                style: AppTypography.subhead.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
