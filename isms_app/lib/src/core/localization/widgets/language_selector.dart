import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_localizations.dart';
import '../locale_provider.dart';

/// Language selector widget
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: 'Change Language',
      onSelected: (locale) {
        localeNotifier.setLocale(locale);
      },
      itemBuilder: (context) {
        return AppLocalizations.supportedLocales.map((locale) {
          final isSelected = locale.languageCode == currentLocale.languageCode;
          return PopupMenuItem<Locale>(
            value: locale,
            child: Row(
              children: [
                if (isSelected)
                  const Icon(Icons.check, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Text(_getLanguageName(locale)),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ur':
        return 'اردو (Urdu)';
      case 'ar':
        return 'العربية (Arabic)';
      default:
        return locale.languageCode.toUpperCase();
    }
  }
}

