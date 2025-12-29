import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/background_editor_page.dart';
import 'services/logger_service.dart';
import 'services/storage_service.dart';
import 'services/analytics_service.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'config/analytics_config.dart';

void main() async {
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

  // Инициализация Hive
  try {
    final storageService = StorageService();
    await storageService.init();
    logger.logInfo(message: 'Hive initialized successfully');
  } catch (e) {
    logger.logError(
      message: 'Failed to initialize Hive',
      error: e,
      stackTrace: null,
    );
  }

  // Инициализация аналитики
  try {
    await AnalyticsService.instance.init(
      appMetricaApiKey: AnalyticsConfig.appMetricaApiKey != 'YOUR_APPMETRICA_API_KEY'
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

  // Инициализация рекламы
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Eraser / Blur',
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
      home: const AuthWrapper(),
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
        // Показываем загрузку пока проверяем состояние
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Если пользователь авторизован - показываем главный экран
        if (snapshot.hasData && snapshot.data != null) {
          return const BackgroundEditorPage();
        }

        // Если не авторизован - показываем экран входа/регистрации
        return const AuthScreen();
      },
    );
  }
}
