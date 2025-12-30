import 'dart:io';
import 'package:flutter/services.dart';
import 'logger_service.dart';
import 'analytics_service.dart';

/// Статус разрешения ATT
enum AttStatus {
  notDetermined, // Пользователь еще не ответил
  restricted, // Ограничено настройками устройства
  denied, // Пользователь отказал
  authorized, // Пользователь разрешил
}

/// Сервис для работы с App Tracking Transparency (ATT) на iOS
///
/// Требования:
/// - iOS 14.0+
/// - Добавить NSUserTrackingUsageDescription в Info.plist
/// - Добавить AppTrackingTransparency framework в проект
class AttService {
  static AttService? _instance;
  static AttService get instance {
    _instance ??= AttService._();
    return _instance!;
  }

  AttService._();

  final LoggerService _logger = LoggerService();
  final AnalyticsService _analytics = AnalyticsService.instance;

  bool _isInitialized = false;
  AttStatus? _currentStatus;

  /// Инициализация ATT сервиса
  Future<void> init() async {
    if (_isInitialized) {
      _logger.logWarning(
        message: 'AttService already initialized',
        context: {},
      );
      return;
    }

    // ATT доступен только на iOS 14.0+
    if (!Platform.isIOS) {
      _logger.logInfo(
        message: 'ATT is iOS only, skipping initialization',
      );
      _isInitialized = true;
      return;
    }

    try {
      _logger.init();

      // Проверяем текущий статус
      await checkTrackingStatus();

      _isInitialized = true;

      _logger.logInfo(
        message: 'AttService initialized',
        data: {
          'status': _currentStatus?.toString(),
        },
      );

      await _analytics.logEvent('att_service_initialized', parameters: {
        'status': _currentStatus?.toString() ?? 'unknown',
      });
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to initialize AttService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Запрос разрешения на трекинг
  ///
  /// ВАЖНО: Вызывайте этот метод только после того, как пользователь
  /// увидел объяснение, зачем нужно разрешение (например, в onboarding)
  Future<AttStatus> requestTrackingPermission() async {
    if (!Platform.isIOS) {
      return AttStatus.authorized; // На Android всегда разрешено
    }

    try {
      _logger.logInfo(message: 'Requesting ATT permission');

      const platform = MethodChannel('att_service');
      final result = await platform.invokeMethod<String>('requestTracking');
      _currentStatus = _parseStatus(result);

      // После получения разрешения передаем статус в AppsFlyer
      if (_currentStatus == AttStatus.authorized) {
        await _updateAppsFlyerAttStatus(_currentStatus!);
      }

      await _analytics.logEvent('att_permission_requested', parameters: {
        'status': _currentStatus?.toString() ?? 'unknown',
      });

      return _currentStatus ?? AttStatus.notDetermined;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to request ATT permission',
        error: e,
        stackTrace: stackTrace,
      );
      return AttStatus.notDetermined;
    }
  }

  /// Проверка текущего статуса разрешения
  Future<AttStatus> checkTrackingStatus() async {
    if (!Platform.isIOS) {
      return AttStatus.authorized; // На Android всегда разрешено
    }

    try {
      const platform = MethodChannel('att_service');
      final result = await platform.invokeMethod<String>('checkStatus');
      _currentStatus = _parseStatus(result);

      return _currentStatus ?? AttStatus.notDetermined;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to check ATT status',
        error: e,
        stackTrace: stackTrace,
      );
      return AttStatus.notDetermined;
    }
  }

  /// Парсинг статуса из строки
  AttStatus _parseStatus(String? statusString) {
    switch (statusString) {
      case 'authorized':
        return AttStatus.authorized;
      case 'denied':
        return AttStatus.denied;
      case 'restricted':
        return AttStatus.restricted;
      case 'notDetermined':
      default:
        return AttStatus.notDetermined;
    }
  }

  /// Обновление статуса ATT в AppsFlyer
  Future<void> _updateAppsFlyerAttStatus(AttStatus status) async {
    try {
      // AppsFlyer SDK автоматически получает статус ATT
      // Статус передается автоматически при инициализации AppsFlyer
      // с параметром timeToWaitForATTUserAuthorization

      _logger.logInfo(
        message: 'ATT status updated in AppsFlyer',
        data: {'status': status.toString()},
      );

      await _analytics.logEvent('att_status_updated', parameters: {
        'status': status.toString(),
        'platform': 'ios',
      });
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to update ATT status in AppsFlyer',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Получение текущего статуса
  AttStatus? get currentStatus => _currentStatus;

  /// Проверка, разрешен ли трекинг
  bool get isTrackingAuthorized {
    return _currentStatus == AttStatus.authorized;
  }
}

