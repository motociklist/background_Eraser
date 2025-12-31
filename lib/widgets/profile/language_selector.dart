import 'package:flutter/material.dart';
import '../../services/locale_service.dart';
import '../../services/analytics_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/locale_provider.dart';

/// Виджет для выбора языка
class LanguageSelector extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const LanguageSelector({
    super.key,
    required this.colorScheme,
    required this.theme,
  });

  String _getLanguageName(Locale locale, AppLocalizations? localizations) {
    if (localizations != null) {
      switch (locale.languageCode) {
        case 'en':
          return localizations.english;
        case 'ru':
          return localizations.russian;
      }
    }
    return LocaleService.instance.getLanguageName(locale);
  }

  Future<void> _changeLanguage(
    BuildContext context,
    Locale newLocale,
  ) async {
    await LocaleService.instance.setLocale(newLocale);

    await AnalyticsService.instance.logEvent(
      'language_changed',
      parameters: {'locale': newLocale.languageCode},
    );

    if (!context.mounted) return;
    final localeProvider = LocaleProvider.of(context);
    if (localeProvider != null) {
      localeProvider.onLocaleChanged(newLocale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);
    final supportedLocales = LocaleService.instance.getSupportedLocales();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                localizations?.language ?? 'Language',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...supportedLocales.map((locale) {
            final isSelected =
                currentLocale.languageCode == locale.languageCode;
            final languageName = _getLanguageName(locale, localizations);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _changeLanguage(context, locale),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          languageName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

