import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import 'logger_service.dart';

/// Сервис для работы с локальным хранилищем (Hive)
class StorageService {
  static const String _settingsBoxName = 'app_settings';
  static const String _settingsKey = 'settings';

  final LoggerService _logger = LoggerService();
  Box? _settingsBox;

  // Публичный геттер для проверки инициализации
  Box? get settingsBox => _settingsBox;

  /// Инициализация Hive и открытие боксов
  Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Открываем бокс для настроек
      _settingsBox = await Hive.openBox(_settingsBoxName);

      _logger.logInfo(
        message: 'StorageService initialized',
        data: {'box_name': _settingsBoxName},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to initialize StorageService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Сохранение настроек приложения
  Future<void> saveSettings(AppSettings settings) async {
    try {
      if (_settingsBox == null) {
        await init();
      }

      await _settingsBox!.put(_settingsKey, settings.toMap());

      // Для веб-платформы принудительно сохраняем изменения
      await _settingsBox!.flush();

      _logger.logInfo(
        message: 'Settings saved successfully',
        data: {
          'provider': settings.apiProvider,
          'has_api_key': settings.apiKey != null && settings.apiKey!.isNotEmpty,
          'blur_radius': settings.blurRadius,
        },
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to save settings',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Загрузка настроек приложения
  AppSettings? loadSettings() {
    try {
      if (_settingsBox == null) {
        _logger.logWarning(
          message: 'Settings box not initialized, cannot load settings',
          context: null,
        );
        return null;
      }

      final data = _settingsBox!.get(_settingsKey);
      if (data == null) {
        _logger.logInfo(message: 'No settings found in storage');
        return null;
      }

      final settings = AppSettings.fromMap(data as Map<dynamic, dynamic>);

      _logger.logInfo(
        message: 'Settings loaded successfully',
        data: {
          'provider': settings.apiProvider,
          'has_api_key': settings.apiKey != null && settings.apiKey!.isNotEmpty,
          'blur_radius': settings.blurRadius,
        },
      );

      return settings;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to load settings',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Сохранение API ключа
  Future<void> saveApiKey(String? apiKey) async {
    try {
      AppSettings? currentSettings = loadSettings();
      AppSettings settings =
          currentSettings?.copyWith(apiKey: apiKey) ??
          AppSettings(apiKey: apiKey);
      await saveSettings(settings);
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to save API key',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Сохранение провайдера
  Future<void> saveProvider(String provider) async {
    try {
      AppSettings? currentSettings = loadSettings();
      AppSettings settings =
          currentSettings?.copyWith(apiProvider: provider) ??
          AppSettings(apiProvider: provider);
      await saveSettings(settings);
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to save provider',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Сохранение радиуса размытия
  Future<void> saveBlurRadius(double radius) async {
    try {
      AppSettings? currentSettings = loadSettings();
      AppSettings settings =
          currentSettings?.copyWith(blurRadius: radius) ??
          AppSettings(blurRadius: radius);
      await saveSettings(settings);
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to save blur radius',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Очистка всех данных
  Future<void> clearAll() async {
    try {
      if (_settingsBox != null) {
        await _settingsBox!.clear();
        _logger.logInfo(message: 'All settings cleared');
      }
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to clear settings',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
