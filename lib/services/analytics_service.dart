// import 'package:appmetrica_flutter/appmetrica_flutter.dart'; // Установите: flutter pub add appmetrica_flutter
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

/// Унифицированный сервис для работы с аналитикой
/// Поддерживает AppMetrica, AppsFlyer и Firebase Analytics
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  AnalyticsService._();

  final LoggerService _logger = LoggerService();
  bool _isInitialized = false;

  // Firebase Analytics
  FirebaseAnalytics? _firebaseAnalytics;

  // AppsFlyer
  AppsflyerSdk? _appsflyerSdk;

  /// Инициализация аналитики
  Future<void> init({
    String? appMetricaApiKey,
    String? appsFlyerDevKey,
    String? appsFlyerAppId,
    bool enableFirebase = true,
  }) async {
    if (_isInitialized) {
      _logger.logWarning(
        message: 'AnalyticsService already initialized',
        context: {},
      );
      return;
    }

    try {
      _logger.init();

      // Инициализация AppMetrica
      if (appMetricaApiKey != null && appMetricaApiKey.isNotEmpty) {
        await _initAppMetrica(appMetricaApiKey);
      }

      // Инициализация AppsFlyer
      if (appsFlyerDevKey != null &&
          appsFlyerDevKey.isNotEmpty &&
          appsFlyerAppId != null &&
          appsFlyerAppId.isNotEmpty) {
        await _initAppsFlyer(appsFlyerDevKey, appsFlyerAppId);
      }

      // Инициализация Firebase Analytics
      if (enableFirebase) {
        await _initFirebase();
      }

      _isInitialized = true;

      _logger.logInfo(
        message: 'AnalyticsService initialized successfully',
        data: {
          'appmetrica': appMetricaApiKey != null && appMetricaApiKey.isNotEmpty,
          'appsflyer': appsFlyerDevKey != null && appsFlyerDevKey.isNotEmpty,
          'firebase': enableFirebase,
        },
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to initialize AnalyticsService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Инициализация AppMetrica
  Future<void> _initAppMetrica(String apiKey) async {
    try {
      // Раскомментируйте после установки пакета appmetrica_flutter
      // await AppMetrica.activate(
      //   AppMetricaConfig(
      //     apiKey,
      //     sessionTimeout: 10,
      //     firstActivationAsUpdate: false,
      //   ),
      // );

      _logger.logInfo(
        message: 'AppMetrica initialization skipped (package not installed)',
        data: {'api_key': '***'},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to initialize AppMetrica',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Инициализация AppsFlyer
  Future<void> _initAppsFlyer(String devKey, String appId) async {
    try {
      final options = AppsFlyerOptions(
        afDevKey: devKey,
        appId: appId,
        showDebug: kDebugMode,
        timeToWaitForATTUserAuthorization: 60,
      );

      _appsflyerSdk = AppsflyerSdk(options);
      await _appsflyerSdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );

      _logger.logInfo(
        message: 'AppsFlyer initialized',
        data: {'dev_key': '***', 'app_id': appId},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to initialize AppsFlyer',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Инициализация Firebase Analytics
  Future<void> _initFirebase() async {
    try {
      _firebaseAnalytics = FirebaseAnalytics.instance;

      _logger.logInfo(
        message: 'Firebase Analytics initialized',
        data: {},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to initialize Firebase Analytics',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Отправка события во все активные системы аналитики
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      _logger.logWarning(
        message: 'AnalyticsService not initialized, skipping event',
        context: {'event_name': eventName},
      );
      return;
    }

    try {
      // AppMetrica (раскомментируйте после установки пакета)
      // try {
      //   await AppMetrica.reportEventWithMap(eventName, parameters ?? {});
      // } catch (e) {
      //   _logger.logWarning(
      //     message: 'Failed to log event to AppMetrica',
      //     context: {'event_name': eventName, 'error': e.toString()},
      //   );
      // }

      // AppsFlyer
      try {
        if (_appsflyerSdk != null) {
          await _appsflyerSdk!.logEvent(eventName, parameters ?? {});
        }
      } catch (e) {
        _logger.logWarning(
          message: 'Failed to log event to AppsFlyer',
          context: {'event_name': eventName, 'error': e.toString()},
        );
      }

      // Firebase Analytics
      try {
        if (_firebaseAnalytics != null) {
          // Конвертируем Map<String, dynamic>? в Map<String, Object>?
          Map<String, Object>? firebaseParams;
          if (parameters != null) {
            firebaseParams = parameters.map((key, value) => MapEntry(key, value as Object));
          }
          await _firebaseAnalytics!.logEvent(
            name: eventName,
            parameters: firebaseParams,
          );
        }
      } catch (e) {
        _logger.logWarning(
          message: 'Failed to log event to Firebase',
          context: {'event_name': eventName, 'error': e.toString()},
        );
      }

      // Локальное логирование
      Future.microtask(() {
        _logger.logInfo(
          message: 'Analytics event logged',
          data: {
            'event_name': eventName,
            'parameters': parameters ?? {},
          },
        );
      });
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error logging analytics event',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Отправка события с экраном
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', parameters: {'screen_name': screenName});
  }

  /// Отправка события ошибки
  Future<void> logError({
    required String errorName,
    required String errorMessage,
    Map<String, dynamic>? additionalParams,
  }) async {
    final params = {
      'error_name': errorName,
      'error_message': errorMessage,
      ...?additionalParams,
    };
    await logEvent('error_occurred', parameters: params);
  }

  /// Установка пользовательского свойства
  Future<void> setUserProperty(String name, String? value) async {
    if (!_isInitialized) return;

    try {
      // Firebase Analytics
      if (_firebaseAnalytics != null && value != null) {
        await _firebaseAnalytics!.setUserProperty(name: name, value: value);
      }

      // AppMetrica (раскомментируйте после установки пакета)
      // try {
      //   await AppMetrica.setUserProfileID(value ?? '');
      // } catch (e) {
      //   // Игнорируем ошибки
      // }
    } catch (e) {
      _logger.logWarning(
        message: 'Failed to set user property',
        context: {'name': name, 'error': e.toString()},
      );
    }
  }

  /// Отправка события начала обработки изображения
  Future<void> logImageProcessingStarted({
    required String operation,
    required String provider,
    required int imageSize,
    double? blurRadius,
  }) async {
    final params = <String, dynamic>{
      'operation': operation,
      'provider': provider,
      'image_size': imageSize,
    };
    if (blurRadius != null) {
      params['blur_radius'] = blurRadius;
    }
    await logEvent('${operation}_started', parameters: params);
  }

  /// Отправка события завершения обработки изображения
  Future<void> logImageProcessingCompleted({
    required String operation,
    required String provider,
    required int durationMs,
    required int resultSize,
    double? blurRadius,
  }) async {
    final params = <String, dynamic>{
      'operation': operation,
      'provider': provider,
      'duration_ms': durationMs,
      'result_size': resultSize,
    };
    if (blurRadius != null) {
      params['blur_radius'] = blurRadius;
    }
    await logEvent('${operation}_completed', parameters: params);
  }

  /// Отправка события ошибки обработки изображения
  Future<void> logImageProcessingFailed({
    required String operation,
    required String provider,
    required String errorMessage,
    String? errorCode,
    double? blurRadius,
  }) async {
    final params = <String, dynamic>{
      'operation': operation,
      'provider': provider,
      'error_message': errorMessage,
    };
    if (errorCode != null) {
      params['error_code'] = errorCode;
    }
    if (blurRadius != null) {
      params['blur_radius'] = blurRadius;
    }
    await logEvent('${operation}_failed', parameters: params);
  }
}

