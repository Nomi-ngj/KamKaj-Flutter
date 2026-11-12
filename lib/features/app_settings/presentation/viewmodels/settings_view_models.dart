import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/app_language.dart';

/// Current app language. Drives `MaterialApp.locale` and text direction.
final class LanguageViewModel extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => ref.read(settingsRepositoryProvider).language ?? AppLanguage.english;

  bool get hasChosenLanguage => ref.read(settingsRepositoryProvider).language != null;

  Future<void> select(AppLanguage language) async {
    state = language;
    await ref.read(settingsRepositoryProvider).saveLanguage(language);
  }
}

final languageProvider = NotifierProvider<LanguageViewModel, AppLanguage>(LanguageViewModel.new);

/// Onboarding pager state: current page index.
final class OnboardingViewModel extends Notifier<int> {
  static const pageCount = 3;

  @override
  int build() => 0;

  bool get isLastPage => state == pageCount - 1;

  void setPage(int index) => state = index.clamp(0, pageCount - 1);

  Future<void> complete() => ref.read(settingsRepositoryProvider).completeOnboarding();
}

final onboardingViewModelProvider =
    NotifierProvider.autoDispose<OnboardingViewModel, int>(OnboardingViewModel.new);
