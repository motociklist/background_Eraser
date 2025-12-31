import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'widgets/app_lifecycle_wrapper.dart';
import 'config/analytics_config.dart';
import 'config/api_config.dart';

void main() async {
  // Инициализация логирования (один раз для всего приложения)
  final logger = LoggerService();
  logger.init();

  // Обработка ошибок Flutter для предотвращения белого экрана
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logger.logError(
      message: 'Flutter error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Обработка асинхронных ошибок
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.logError(
      message: 'Platform error: $error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
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
      String? rewardedInterstitialAdUnitId;
      String? nativeAdUnitId;
      String? appOpenAdUnitId;

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          bannerAdUnitId = AnalyticsConfig.androidBannerAdUnitId;
          interstitialAdUnitId = AnalyticsConfig.androidInterstitialAdUnitId;
          rewardedAdUnitId = AnalyticsConfig.androidRewardedAdUnitId;
          rewardedInterstitialAdUnitId =
              AnalyticsConfig.androidRewardedInterstitialAdUnitId;
          nativeAdUnitId = AnalyticsConfig.androidNativeAdUnitId;
          appOpenAdUnitId = AnalyticsConfig.androidAppOpenAdUnitId;
        } else if (Platform.isIOS) {
          bannerAdUnitId = AnalyticsConfig.iosBannerAdUnitId;
          interstitialAdUnitId = AnalyticsConfig.iosInterstitialAdUnitId;
          rewardedAdUnitId = AnalyticsConfig.iosRewardedAdUnitId;
          rewardedInterstitialAdUnitId =
              AnalyticsConfig.iosRewardedInterstitialAdUnitId;
          nativeAdUnitId = AnalyticsConfig.iosNativeAdUnitId;
          appOpenAdUnitId = AnalyticsConfig.iosAppOpenAdUnitId;
        }
      }

      await AdService.instance.init(
        bannerAdUnitId: bannerAdUnitId,
        interstitialAdUnitId: interstitialAdUnitId,
        rewardedAdUnitId: rewardedAdUnitId,
        rewardedInterstitialAdUnitId: rewardedInterstitialAdUnitId,
        nativeAdUnitId: nativeAdUnitId,
        appOpenAdUnitId: appOpenAdUnitId,
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
      home: AppLifecycleWrapper(
        child: LocaleProvider(
          onLocaleChanged: onLocaleChanged,
          child: const AuthWrapper(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Обертка для проверки авторизации
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _previousUser;
  bool _isInitialLoad = true;
  bool _hasShownAdForCurrentLogin = false;
  bool _isShowingAd = false; // Флаг для отслеживания процесса показа рекламы

  @override
  void initState() {
    super.initState();
  }

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

        final currentUser = snapshot.data;

        // Определяем, произошел ли новый вход в аккаунт (переход из неавторизованного в авторизованное)
        final isNewLogin =
            _previousUser == null && currentUser != null && !_isInitialLoad;

        // Если пользователь авторизован - показываем главный экран с навигацией
        if (currentUser != null) {
          // Показываем App Open рекламу:
          // 1. При первом запуске приложения (если пользователь уже авторизован)
          // 2. При каждом новом входе в аккаунт после выхода
          final shouldShowAd =
              (!_hasShownAdForCurrentLogin &&
              !_isShowingAd &&
              (isNewLogin || _isInitialLoad) &&
              !kIsWeb);

          if (shouldShowAd) {
            // ВАЖНО: Помечаем СРАЗУ оба флага, чтобы предотвратить повторные вызовы
            _hasShownAdForCurrentLogin = true;
            _isShowingAd = true;

            // Загружаем рекламу сразу (только один раз)
            AdService.instance.loadAppOpenAd();

            // Небольшая задержка, чтобы пользователь увидел главный экран
            // и реклама успела загрузиться
            Future.delayed(const Duration(milliseconds: 2000), () async {
              // Проверяем, что виджет еще смонтирован и флаг не сброшен
              if (!mounted || !_isShowingAd) {
                return;
              }

              try {
                await AdService.instance.showAppOpenAd();
              } catch (e) {
                final logger = LoggerService();
                logger.init();
                logger.logError(
                  message: 'Failed to show App Open ad: $e',
                  error: e,
                );
              } finally {
                // Сбрасываем флаг показа после завершения (успешного или с ошибкой)
                if (mounted) {
                  setState(() {
                    _isShowingAd = false;
                  });
                }
              }
            });
          }

          // Обновляем предыдущего пользователя
          _previousUser = currentUser;
          _isInitialLoad = false;

          // Используем ключ с userId, чтобы пересоздать виджет при смене пользователя
          return MainNavigation(key: ValueKey(currentUser.uid));
        }

        // Если не авторизован - сбрасываем флаги и показываем экран входа/регистрации
        _previousUser = null;
        _hasShownAdForCurrentLogin = false; // Сбрасываем флаг при выходе
        _isShowingAd = false; // Сбрасываем флаг показа при выходе
        _isInitialLoad = false;
        return const AuthScreen();
      },
    );
  }
}
