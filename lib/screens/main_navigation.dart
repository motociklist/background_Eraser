import 'package:flutter/material.dart';
import 'package:mst_projectfoto/l10n/app_localizations.dart';
import 'background_editor_page.dart';
import 'profile_page.dart';
import '../services/analytics_service.dart';
import '../services/ad_service.dart';

/// Главный экран с навигацией
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BackgroundEditorPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Аналитика: просмотр главного экрана
    AnalyticsService.instance.logScreenView('main_navigation');
    // App Open реклама теперь показывается в AuthWrapper при обнаружении нового входа
  }

  void _onTabTapped(int index) async {
    if (_currentIndex != index) {
      // Показываем interstitial рекламу при переключении вкладок (если доступна)
      // Показываем не каждый раз, а периодически, чтобы не раздражать пользователя
      await AdService.instance.showInterstitialAdIfNeeded();

      setState(() {
        _currentIndex = index;
      });

      // Аналитика: переключение вкладок
      final screenName = index == 0 ? 'background_editor' : 'profile';
      AnalyticsService.instance.logScreenView(screenName);
      AnalyticsService.instance.logEvent(
        'tab_switched',
        parameters: {'tab_index': index, 'tab_name': screenName},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Безопасное получение локализации с fallback
    final l10n = AppLocalizations.of(context);

    // Fallback строки если локализация не загрузилась
    final editorLabel = l10n?.editor ?? 'Редактор';
    final profileLabel = l10n?.profile ?? 'Профиль';

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.photo_library),
              activeIcon: const Icon(Icons.photo_library),
              label: editorLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: profileLabel,
            ),
          ],
        ),
      ),
    );
  }
}
