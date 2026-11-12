import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/theme/app_theme.dart';
import '../features/app_settings/domain/entities/app_language.dart';
import '../features/app_settings/presentation/viewmodels/settings_view_models.dart';
import 'router/app_router.dart';

class KamKajApp extends ConsumerWidget {
  const KamKajApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final language = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'KamKaj Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: Locale(language.code),
      supportedLocales: [for (final l in AppLanguage.values) Locale(l.code)],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Respect user font scaling but cap it so layouts stay intact.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
