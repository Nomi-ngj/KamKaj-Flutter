import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/app_logger.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'di/injection.dart';

/// Initialises platform services, wires DI overrides and runs the app inside
/// a guarded zone so uncaught errors are logged instead of crashing silently.
Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      FlutterError.onError = (details) {
        AppLogger.error('Flutter error', error: details.exception, stackTrace: details.stack);
      };

      final config = AppConfig.fromEnvironment();
      final prefs = await SharedPreferences.getInstance();
      AppLogger.debug('Starting in ${config.environment.name} (mock API: ${config.useMockApi})');

      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const KamKajApp(),
        ),
      );
    },
    (error, stack) => AppLogger.error('Uncaught error', error: error, stackTrace: stack),
  );
}
