import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/ad_service.dart';
import '../services/logger_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/common/confirm_dialog.dart';
import '../widgets/common/info_row.dart';
import '../widgets/ads/ad_test_button.dart';
import '../widgets/profile/profile_section.dart';
import '../widgets/profile/language_selector.dart';
import '../widgets/native_ad_widget.dart';
import '../utils/date_formatter.dart';

/// Страница профиля пользователя
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    final authService = AuthService.instance;
    final localizations = AppLocalizations.of(context)!;

    final shouldSignOut = await ConfirmDialog.show(
      context,
      title: localizations.signOutTitle,
      message: localizations.signOutConfirmation,
      confirmText: localizations.signOut,
      cancelText: localizations.cancel,
      icon: Icons.logout,
      iconColor: Colors.red,
      confirmButtonColor: Colors.red,
    );

    if (shouldSignOut == true) {
      try {
        await authService.signOut();
        await AnalyticsService.instance.logEvent('profile_sign_out');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.signOutError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = AuthService.instance.currentUser;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.secondaryContainer.withValues(alpha: 0.2),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  localizations.profile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Карточка с информацией о пользователе
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Аватар пользователя
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Email пользователя
                            Text(
                              user?.email ?? localizations.notSpecified,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // Дата создания аккаунта
                            if (user != null &&
                                user.metadata.creationTime != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            localizations.registrationDate,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormatter.formatDate(
                                              user.metadata.creationTime!,
                                            ),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Информационные карточки
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    localizations.accountInfo,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            InfoRow(
                              icon: Icons.email,
                              label: localizations.email,
                              value: user?.email ?? localizations.notSpecified,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 12),
                            InfoRow(
                              icon: Icons.person_outline,
                              label: localizations.userId,
                              value: user?.uid ?? localizations.notSpecified,
                              colorScheme: colorScheme,
                              isLongText: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Карточка настроек
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.settings,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Переключатель языка
                            LanguageSelector(
                              colorScheme: colorScheme,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Карточка тестирования рекламы
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: ProfileSection(
                          title: 'Тестирование рекламы',
                          icon: Icons.ads_click,
                          children: [
                            if (!kIsWeb) ...[
                              // Banner реклама
                              AdTestButton(
                                icon: Icons.view_carousel,
                                label: 'Banner (Баннер)',
                                description: 'Показать баннерную рекламу',
                                colorScheme: colorScheme,
                                onPressed: () async {
                                  await AdService.instance.loadBannerAd();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Баннер загружен! Проверьте главный экран.',
                                        ),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              // Interstitial реклама
                              AdTestButton(
                                icon: Icons.fullscreen,
                                label: 'Interstitial (Межстраничная)',
                                description: 'Показать межстраничную рекламу',
                                colorScheme: colorScheme,
                                onPressed: () async {
                                  await AdService.instance.loadInterstitialAd();
                                  await AdService.instance.showInterstitialAd();
                                },
                              ),
                              const SizedBox(height: 12),
                              // Rewarded реклама
                              AdTestButton(
                                icon: Icons.video_library,
                                label: 'Rewarded (Видео с наградой)',
                                description:
                                    'Посмотрите видео и получите награду',
                                colorScheme: colorScheme,
                                onPressed: () async {
                                  await AdService.instance.showRewardedAd(
                                    onRewarded: () {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '🎉 Награда получена!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              // Rewarded Interstitial реклама
                              AdTestButton(
                                icon: Icons.play_circle_outline,
                                label: 'Rewarded Interstitial',
                                description: 'Межстраничная реклама с наградой',
                                colorScheme: colorScheme,
                                onPressed: () async {
                                  await AdService.instance
                                      .showRewardedInterstitialAd(
                                        onRewarded: () {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '🎉 Награда получена!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        },
                                      );
                                },
                              ),
                              const SizedBox(height: 12),
                              // App Open реклама
                              _AppOpenAdButton(colorScheme: colorScheme),
                              const SizedBox(height: 12),
                              // Native реклама (кнопка для показа в диалоге)
                              AdTestButton(
                                icon: Icons.article,
                                label: 'Native (Нативная)',
                                description: 'Показать нативную рекламу',
                                colorScheme: colorScheme,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        constraints: const BoxConstraints(
                                          maxWidth: 400,
                                          maxHeight: 500,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Нативная реклама',
                                                  style: theme
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            const Expanded(
                                              child: NativeAdWidget(
                                                height: 400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              // Разделитель
                              Divider(color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              // Native реклама (встроенная)
                              Text(
                                'Native реклама (встроенная)',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const NativeAdWidget(height: 300),
                            ] else
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Реклама доступна только на мобильных платформах',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Кнопка выхода
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSignOut(context),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          localizations.signOut,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Отступ для нижней навигации
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет кнопки для показа App Open рекламы с защитой от множественных нажатий
class _AppOpenAdButton extends StatefulWidget {
  final ColorScheme colorScheme;

  const _AppOpenAdButton({required this.colorScheme});

  @override
  State<_AppOpenAdButton> createState() => _AppOpenAdButtonState();
}

class _AppOpenAdButtonState extends State<_AppOpenAdButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    // Предотвращаем множественные одновременные нажатия
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final logger = LoggerService();
      logger.init();
      logger.logInfo(
        message: 'App Open button pressed',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Загрузка App Open рекламы...'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Загружаем рекламу
      await AdService.instance.loadAppOpenAd();

      // Ждем загрузки (до 3 секунд)
      await Future.delayed(const Duration(seconds: 3));

      // Пытаемся показать рекламу
      final success = await AdService.instance.showAppOpenAd();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ App Open реклама показана'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Не удалось загрузить App Open рекламу.\n'
              'Проверьте Ad Unit ID в консоли AdMob.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      final logger = LoggerService();
      logger.init();
      logger.logError(
        message: 'Error showing App Open ad: $e',
        error: e,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdTestButton(
      icon: Icons.open_in_new,
      label: 'App Open (При открытии)',
      description: _isLoading
          ? 'Загрузка рекламы...'
          : 'Показать рекламу при открытии',
      colorScheme: widget.colorScheme,
      onPressed: _handlePress,
    );
  }
}
