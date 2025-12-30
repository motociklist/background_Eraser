import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/ad_service.dart';

/// Виджет-обертка для управления жизненным циклом приложения и показом App Open рекламы
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // App Open реклама теперь показывается только после авторизации
    // в MainNavigation, а не при запуске приложения
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kIsWeb) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        // Приложение вернулось на передний план
        if (!_isAppInForeground) {
          _isAppInForeground = true;
          // Показываем App Open рекламу при возврате в приложение
          AdService.instance.showAppOpenAd();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        break;
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

