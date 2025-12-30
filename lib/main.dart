import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:mst_projectfoto/l10n/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation.dart';
import 'services/logger_service.dart';
import 'services/analytics_service.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/apphud_service.dart';
import 'services/att_service.dart';
import 'services/locale_service.dart';
import 'widgets/locale_provider.dart';
import 'config/analytics_config.dart';
import 'config/api_config.dart';

void main() async {
  // Обработка ошибок Flutter для предотвращения белого экрана
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Логируем критическую ошибку
    final logger = LoggerService();
    logger.init();
    logger.logError(
      message: 'Flutter error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Обработка асинхронных ошибок
  PlatformDispatcher.instance.onError = (error, stack) {
    final logger = LoggerService();
    logger.init();
    logger.logError(
      message: 'Platform error: $error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация логирования
  final logger = LoggerService();
  logger.init();
  logger.logInfo(message: 'Application started');

  // Инициализация Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.logInfo(message: 'Firebase initialized successfully');
  } catch (e) {
    logger.logError(
      message: 'Failed to initialize Firebase',
      error: e,
      stackTrace: null,
    );
    // Продолжаем работу даже если Firebase не инициализирован
  }

  // Инициализация ATT (App Tracking Transparency) для iOS
  try {
    await AttService.instance.init();
    logger.logInfo(message: 'ATT service initialized');

    // Запрашиваем разрешение на трекинг (можно вызвать позже, например, после onboarding)
    // await AttService.instance.requestTrackingPermission();
  } catch (e) {
    logger.logError(
      message: 'Failed to initialize ATT Service',
      error: e,
      stackTrace: null,
    );
  }

  // Инициализация аналитики
  try {
    await AnalyticsService.instance.init(
      appMetricaApiKey:
          AnalyticsConfig.appMetricaApiKey != 'YOUR_APPMETRICA_API_KEY'
          ? AnalyticsConfig.appMetricaApiKey
          : null,
      appsFlyerDevKey: AnalyticsConfig.appsFlyerDevKey,
      appsFlyerAppId: AnalyticsConfig.appsFlyerAppId,
      enableFirebase: AnalyticsConfig.enableFirebase,
    );
    logger.logInfo(message: 'Analytics initialized');

    // Логируем запуск приложения
    await AnalyticsService.instance.logEvent('app_launched');
  } catch (e) {
    logger.logError(
      message: 'Failed to initialize Analytics',
      error: e,
      stackTrace: null,
    );
  }

  // Инициализация аутентификации
  try {
    AuthService.instance.init();
    logger.logInfo(message: 'Auth service initialized');
  } catch (e) {
    logger.logError(
      message: 'Failed to initialize Auth Service',
      error: e,
      stackTrace: null,
    );
  }

  // Инициализация AppHud (подписки)
  // Запускаем в фоне, чтобы не блокировать UI
  AppHudService.instance
      .init(apiKey: ApiConfig.appHudApiKey, enableAttribution: true)
      .then((_) {
        logger.logInfo(message: 'AppHud service initialized');
      })
      .catchError((e) {
        logger.logError(
          message: 'Failed to initialize AppHud Service',
          error: e,
          stackTrace: null,
        );
      });

  // Инициализация рекламы
  // Запускаем в фоне, чтобы не блокировать UI
  Future.microtask(() async {
    try {
      // Определяем Ad Unit IDs в зависимости от платформы
      String? bannerAdUnitId;
      String? interstitialAdUnitId;
      String? rewardedAdUnitId;

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          bannerAdUnitId = AnalyticsConfig.androidBannerAdUnitId;
          interstitialAdUnitId = AnalyticsConfig.androidInterstitialAdUnitId;
          rewardedAdUnitId = AnalyticsConfig.androidRewardedAdUnitId;
        } else if (Platform.isIOS) {
          bannerAdUnitId = AnalyticsConfig.iosBannerAdUnitId;
          interstitialAdUnitId = AnalyticsConfig.iosInterstitialAdUnitId;
          rewardedAdUnitId = AnalyticsConfig.iosRewardedAdUnitId;
        }
      }

      await AdService.instance.init(
        bannerAdUnitId: bannerAdUnitId,
        interstitialAdUnitId: interstitialAdUnitId,
        rewardedAdUnitId: rewardedAdUnitId,
        interstitialShowInterval: AnalyticsConfig.interstitialShowInterval,
      );
      logger.logInfo(message: 'Ad service initialized');
    } catch (e) {
      logger.logError(
        message: 'Failed to initialize Ad Service',
        error: e,
        stackTrace: null,
      );
    }
  });

  // Запускаем приложение сразу, не дожидаясь инициализации рекламы
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');
  bool _isLoadingLocale = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
    // Слушаем изменения аутентификации для загрузки языка из Firestore
    AuthService.instance.authStateChanges.listen((user) {
      if (user != null) {
        // Пользователь вошел - загружаем язык из Firestore
        _loadSavedLocale();
      }
    });
  }

  Future<void> _loadSavedLocale() async {
    // Загружаем язык (из Firestore, если пользователь авторизован, иначе из SharedPreferences)
    final savedLocale = await LocaleService.instance.getSavedLocale();
    if (mounted) {
      setState(() {
        _locale = savedLocale ?? const Locale('en', '');
        _isLoadingLocale = false;
      });
    }
  }

  void changeLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
    // Сохраняем язык (в Firestore и локально)
    LocaleService.instance.setLocale(newLocale);
  }

  @override
  Widget build(BuildContext context) {
    // Показываем загрузку пока определяем язык
    if (_isLoadingLocale) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return _MaterialAppWithLocale(
      locale: _locale,
      onLocaleChanged: changeLocale,
    );
  }
}

class _MaterialAppWithLocale extends StatelessWidget {
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  const _MaterialAppWithLocale({
    required this.locale,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Eraser / Blur',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      // Обработка ошибок в build методах
      builder: (context, child) {
        // Перехватываем ошибки в виджетах
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Ошибка отображения: ${details.exception}',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Индиго
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: LocaleProvider(
        onLocaleChanged: onLocaleChanged,
        child: const AuthWrapper(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Обертка для проверки авторизации
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // Обработка ошибок
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Попытка перезапуска
                      runApp(const MyApp());
                    },
                    child: const Text('Перезапустить'),
                  ),
                ],
              ),
            ),
          );
        }

        // Показываем загрузку пока проверяем состояние
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Если пользователь авторизован - показываем главный экран с навигацией
        // Используем ключ с userId, чтобы пересоздать виджет при смене пользователя
        if (snapshot.hasData && snapshot.data != null) {
          return MainNavigation(key: ValueKey(snapshot.data!.uid));
        }

        // Если не авторизован - показываем экран входа/регистрации
        return const AuthScreen();
      },
    );
  }
}
