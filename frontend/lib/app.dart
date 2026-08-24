import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/app_language.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class AgriVisionApp extends ConsumerWidget {
  const AgriVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localSettingsProvider).valueOrNull ?? 'en';
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AgriVision AI',
      theme: AppTheme.light,
      locale: Locale(language),
      supportedLocales: const [
        Locale('en', ''),
        Locale('ne', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
