import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../../../design_system/tokens/app_durations.dart';
import '../../../auth/presentation/viewmodels/session_view_model.dart';

enum SplashDestination { onboarding, language, signIn, home }

/// Restores the session while the splash shows, then picks the first screen.
final class SplashViewModel extends Notifier<SplashDestination?> {
  @override
  SplashDestination? build() => null;

  Future<void> start({Duration minimumDuration = AppDurations.splash}) async {
    await Future.wait<void>([
      Future<void>.delayed(minimumDuration),
      ref.read(sessionProvider.notifier).restore(),
    ]);
    if (!ref.mounted) return;

    final settings = ref.read(settingsRepositoryProvider);
    final session = ref.read(sessionProvider);
    state = switch (session.isAuthenticated) {
      true => SplashDestination.home,
      false when !settings.isOnboardingCompleted => SplashDestination.onboarding,
      false when settings.language == null => SplashDestination.language,
      false => SplashDestination.signIn,
    };
  }
}

final splashViewModelProvider =
    NotifierProvider.autoDispose<SplashViewModel, SplashDestination?>(SplashViewModel.new);
