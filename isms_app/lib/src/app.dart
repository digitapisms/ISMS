import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/authentication/application/auth_providers.dart';
import 'features/authentication/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_shell.dart';

class ISMSApp extends ConsumerWidget {
  const ISMSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightTheme = ref.watch(appThemeProvider);
    final darkTheme = ref.watch(appDarkThemeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authUser = ref.watch(authStateProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'ILMA Cloud Portal',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode.toThemeMode(),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authUser == null
          ? const LoginScreen()
          : const DashboardShell(),
    );
  }
}


