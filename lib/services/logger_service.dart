import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Сервис для логирования важных действий приложения
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  Logger? _loggerInstance;

  /// Получить экземпляр логгера (инициализирует при необходимости)
  Logger get logger {
    _loggerInstance ??= Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
      ),
      level: kDebugMode ? Level.debug : Level.info,
    );
    return _loggerInstance!;
  }

  /// Инициализация логгера (безопасно вызывать несколько раз)
  void init() {
    // Инициализация происходит автоматически при первом обращении к logger
    // Этот метод оставлен для обратной совместимости
    logger; // Доступ к logger для инициализации
  }

  /// Логирование API запросов
  void logApiRequest({
    required String provider,
    required String endpoint,
    Map<String, dynamic>? headers,
    int? imageSize,
  }) {
    logger.i('📡 API Request', error: null, stackTrace: null);
    logger.d('Provider: $provider');
    logger.d('Endpoint: $endpoint');
    if (headers != null && headers.isNotEmpty) {
      logger.d('Headers: ${_sanitizeHeaders(headers)}');
    }
    if (imageSize != null) {
      logger.d('Image size: ${_formatBytes(imageSize)}');
    }
  }

  /// Логирование успешного API ответа
  void logApiSuccess({
    required String provider,
    required int statusCode,
    int? responseSize,
    Duration? duration,
  }) {
    logger.i('✅ API Success', error: null, stackTrace: null);
    logger.d('Provider: $provider');
    logger.d('Status: $statusCode');
    if (responseSize != null) {
      logger.d('Response size: ${_formatBytes(responseSize)}');
    }
    if (duration != null) {
      logger.d('Duration: ${duration.inMilliseconds}ms');
    }
  }

  /// Логирование ошибки API
  void logApiError({
    required String provider,
    required int statusCode,
    required String error,
    String? errorBody,
    Duration? duration,
  }) {
    logger.e('❌ API Error', error: error, stackTrace: null);
    logger.e('Provider: $provider');
    logger.e('Status: $statusCode');
    logger.e('Error: $error');
    if (errorBody != null) {
      logger.e('Error body: $errorBody');
    }
    if (duration != null) {
      logger.e('Duration: ${duration.inMilliseconds}ms');
    }
  }

  /// Логирование обработки изображения
  void logImageProcessing({
    required String operation,
    int? imageSize,
    Map<String, dynamic>? parameters,
  }) {
    logger.i('🖼️ Image Processing: $operation', error: null, stackTrace: null);
    if (imageSize != null) {
      logger.d('Image size: ${_formatBytes(imageSize)}');
    }
    if (parameters != null && parameters.isNotEmpty) {
      logger.d('Parameters: $parameters');
    }
  }

  /// Логирование сохранения файла
  void logFileSave({
    required String path,
    required int fileSize,
    required bool success,
    String? error,
  }) {
    if (success) {
      logger.i('💾 File Saved', error: null, stackTrace: null);
      logger.d('Path: $path');
      logger.d('Size: ${_formatBytes(fileSize)}');
    } else {
      logger.e(
        '💾 File Save Failed',
        error: error ?? 'Unknown error',
        stackTrace: null,
      );
      logger.e('Path: $path');
    }
  }

  /// Логирование выбора изображения
  void logImagePick({
    required String source,
    required int imageSize,
    String? path,
  }) {
    logger.i('📸 Image Picked', error: null, stackTrace: null);
    logger.d('Source: $source');
    logger.d('Size: ${_formatBytes(imageSize)}');
    if (path != null) {
      logger.d('Path: $path');
    }
  }

  /// Логирование состояния приложения
  void logAppState({required String action, Map<String, dynamic>? state}) {
    logger.d('🔄 App State: $action', error: null, stackTrace: null);
    if (state != null && state.isNotEmpty) {
      logger.d('State: $state');
    }
  }

  /// Логирование ошибок приложения
  void logError({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.e('🚨 Error: $message', error: error, stackTrace: stackTrace);
  }

  /// Логирование предупреждений
  void logWarning({required String message, Map<String, dynamic>? context}) {
    logger.w('⚠️ Warning: $message', error: null, stackTrace: null);
    if (context != null && context.isNotEmpty) {
      logger.w('Context: $context');
    }
  }

  /// Логирование информационных сообщений
  void logInfo({required String message, Map<String, dynamic>? data}) {
    logger.i('ℹ️ Info: $message', error: null, stackTrace: null);
    if (data != null && data.isNotEmpty) {
      logger.i('Data: $data');
    }
  }

  /// Логирование отладки
  void logDebug({required String message, Map<String, dynamic>? data}) {
    logger.d('🔍 Debug: $message', error: null, stackTrace: null);
    if (data != null && data.isNotEmpty) {
      logger.d('Data: $data');
    }
  }

  /// Очистка чувствительных данных из заголовков
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    // Скрываем API ключи
    sanitized.forEach((key, value) {
      if (key.toLowerCase().contains('api') ||
          key.toLowerCase().contains('key') ||
          key.toLowerCase().contains('token') ||
          key.toLowerCase().contains('authorization')) {
        if (value is String && value.isNotEmpty) {
          sanitized[key] =
              '${value.substring(0, value.length > 8 ? 8 : value.length)}***';
        }
      }
    });
    return sanitized;
  }

  /// Форматирование размера в байтах
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
