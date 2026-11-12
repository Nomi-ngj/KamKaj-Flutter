import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../design_system/assets/app_images.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../viewmodels/splash_view_model.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashViewModelProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(splashViewModelProvider, (_, destination) {
      final route = switch (destination) {
        SplashDestination.onboarding => RouteNames.onboarding,
        SplashDestination.language => RouteNames.language,
        SplashDestination.signIn => RouteNames.signIn,
        SplashDestination.home => RouteNames.home,
        null => null,
      };
      if (route != null) context.goNamed(route);
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppAssetImage(
            path: AppImages.splashBackground,
            fit: BoxFit.cover,
            semanticLabel: 'Delivery van being loaded',
            placeholderIcon: Icons.local_shipping_outlined,
          ),
          const ColoredBox(color: AppColors.splashVeil),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  'App Name',
                  style: AppTypography.header2.copyWith(color: AppColors.secondary),
                ),
                Text(
                  'Pro',
                  style: AppTypography.header2.copyWith(color: AppColors.primary),
                ),
                const Spacer(flex: 3),
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.massive),
                  child: AppLoader(color: AppColors.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
