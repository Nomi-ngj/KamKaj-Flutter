import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../design_system/assets/app_images.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../../app_settings/presentation/viewmodels/settings_view_models.dart';

class _OnboardingSlide {
  const _OnboardingSlide(this.image, this.title, this.body);

  final String image;
  final String title;
  final String body;
}

const _slides = [
  _OnboardingSlide(
    AppImages.onboarding1,
    'Get Anything Delivered',
    'Need something from nearby? KamKaj Pro connects you with helpers to bring it right to your doorstep.',
  ),
  _OnboardingSlide(
    AppImages.onboarding2,
    'Your Delivery Partner',
    'From groceries to daily needs, get everything delivered quickly within your area—fast, simple, and reliable.',
  ),
  _OnboardingSlide(
    AppImages.onboarding3,
    'We Bring It To You',
    'Just tell us what you need, and our local riders will deliver it to your home in no time.',
  ),
];

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingViewModelProvider.notifier).complete();
    if (!mounted) return;
    context.goNamed(RouteNames.language);
  }

  void _next() {
    final viewModel = ref.read(onboardingViewModelProvider.notifier);
    if (viewModel.isLastPage) {
      _finish();
      return;
    }
    _controller.nextPage(duration: AppDurations.normal, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(onboardingViewModelProvider);
    final isLast = index == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: SafeArea(
        child: AppResponsiveCenter(
          child: Column(
            children: [
              SizedBox(
                height: AppDimensions.appBarHeight,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: AppDurations.fast,
                    child: TextButton(
                      onPressed: isLast ? null : _finish,
                      child: Text(
                        'Skip',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: ref.read(onboardingViewModelProvider.notifier).setPage,
                  itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              AppPageDots(count: _slides.length, index: index),
              const SizedBox(height: AppSpacing.huge),
              SizedBox(
                width: AppDimensions.onboardingButtonWidth,
                child: AppButton(
                  label: isLast ? 'Get Started' : 'Continue',
                  variant: AppButtonVariant.secondary,
                  onPressed: _next,
                ),
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.massive),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.giant),
          AppAssetImage(
            path: slide.image,
            width: AppDimensions.onboardingIllustration,
            height: AppDimensions.onboardingIllustration,
            semanticLabel: slide.title,
            placeholderIcon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Semantics(
            header: true,
            child: AppText.header(slide.title, textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppText.subtitle(slide.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
