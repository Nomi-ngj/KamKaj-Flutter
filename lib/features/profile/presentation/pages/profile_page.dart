import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../../app_settings/presentation/viewmodels/settings_view_models.dart';
import '../../../auth/presentation/viewmodels/session_view_model.dart';

/// Profile tab. Not in the Figma file — composed from existing tokens and
/// components (see FIGMA_ANALYSIS.md §7).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to place orders.',
      confirmLabel: 'Sign Out',
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;
    // The router redirects to Sign In once the session is cleared.
    await ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider.select((s) => s.user));
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Profile', showBack: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          AppCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: AppSpacing.xxl,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person_rounded, color: AppColors.white),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'Guest', style: AppTypography.titleMedium),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.caption2.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _MenuTile(
            icon: Icons.location_on_outlined,
            label: 'Saved Addresses',
            onTap: () => context.pushNamed(RouteNames.addresses),
          ),
          _MenuTile(
            icon: Icons.local_taxi_outlined,
            label: 'Ride & Delivery Services',
            onTap: () => context.pushNamed(RouteNames.services),
          ),
          _MenuTile(
            icon: Icons.translate_rounded,
            label: 'Language',
            trailing: language.nativeName,
            onTap: () => context.pushNamed(RouteNames.changeLanguage),
          ),
          _MenuTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () => context.pushNamed(RouteNames.changePassword),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: 'Sign Out',
            variant: AppButtonVariant.outline,
            leadingIcon: Icons.logout_rounded,
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.trailing});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Text(label, style: AppTypography.caption1Medium)),
            if (trailing != null)
              Text(trailing!, style: AppTypography.caption2.copyWith(color: AppColors.textSecondary)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
