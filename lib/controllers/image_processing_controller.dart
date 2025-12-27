import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_state.dart';
import '../services/background_service.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';

/// Контроллер для управления обработкой изображений
class ImageProcessingController extends ChangeNotifier {
  final BackgroundService _backgroundService = BackgroundService();
  final ImagePicker _imagePicker = ImagePicker();
  final LoggerService _logger = LoggerService();
  final StorageService _storageService = StorageService();

  AppState _state = const AppState();
  AppState get state => _state;

  final TextEditingController apiKeyController = TextEditingController();

  ImageProcessingController() {
    _logger.init();
    apiKeyController.addListener(_onApiKeyChanged);
    _logger.logAppState(action: 'Controller initialized');
    // Загружаем настройки асинхронно после инициализации
    loadSettings();
  }

  /// Загрузка сохраненных настроек
  Future<void> loadSettings() async {
    try {
      // Убеждаемся, что Hive инициализирован
      if (_storageService.settingsBox == null) {
        await _storageService.init();
      }

      final settings = _storageService.loadSettings();
      if (settings != null) {
        // Загружаем API ключ
        if (settings.apiKey != null && settings.apiKey!.isNotEmpty) {
          apiKeyController.text = settings.apiKey!;
        }

        // Загружаем провайдера
        if (settings.apiProvider.isNotEmpty) {
          _state = _state.copyWith(selectedProvider: settings.apiProvider);
        }

        // Загружаем радиус размытия
        if (settings.blurRadius > 0) {
          _state = _state.copyWith(blurRadius: settings.blurRadius);
        }

        _logger.logInfo(
          message: 'Settings loaded from storage',
          data: {
            'provider': settings.apiProvider,
            'has_api_key':
                settings.apiKey != null && settings.apiKey!.isNotEmpty,
            'blur_radius': settings.blurRadius,
          },
        );

        notifyListeners();
      } else {
        _logger.logInfo(message: 'No saved settings found');
      }
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to load settings',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Timer? _saveApiKeyTimer;

  void _onApiKeyChanged() {
    final apiKey = apiKeyController.text.trim();
    _state = _state.copyWith(apiKey: apiKey);

    // Отменяем предыдущий таймер, если он есть
    _saveApiKeyTimer?.cancel();

    // Сохраняем API ключ при изменении (с небольшой задержкой, чтобы не сохранять при каждом символе)
    _saveApiKeyTimer = Timer(const Duration(milliseconds: 1000), () {
      final currentKey = apiKeyController.text.trim();
      _storageService
          .saveApiKey(currentKey.isEmpty ? null : currentKey)
          .catchError((e) {
            _logger.logError(
              message: 'Failed to save API key',
              error: e,
              stackTrace: null,
            );
          });
    });

    notifyListeners();
  }

  /// Выбор изображения
  Future<void> pickImage(ImageSource source) async {
    try {
      _logger.logInfo(
        message: 'Picking image',
        data: {'source': source.toString()},
      );

      final XFile? image = await _imagePicker.pickImage(source: source);

      if (image != null) {
        final bytes = await image.readAsBytes();
        _logger.logImagePick(
          source: source.toString(),
          imageSize: bytes.length,
          path: image.path,
        );

        _state = _state.copyWith(
          selectedImageBytes: bytes,
          processedImage: null,
          errorMessage: null,
        );
        notifyListeners();

        _logger.logAppState(
          action: 'Image selected',
          state: {'size': bytes.length},
        );
      }
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error picking image',
        error: e,
        stackTrace: stackTrace,
      );
      _state = _state.copyWith(errorMessage: 'Ошибка выбора изображения: $e');
      notifyListeners();
    }
  }

  /// Удаление фона
  Future<void> removeBackground() async {
    if (_state.selectedImageBytes == null) {
      _state = _state.copyWith(
        errorMessage: 'Пожалуйста, выберите изображение',
      );
      notifyListeners();
      return;
    }

    // Проверяем API ключ напрямую из контроллера
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _state = _state.copyWith(errorMessage: 'Пожалуйста, введите API ключ');
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      isProcessing: true,
      errorMessage: null,
      processedImage: null,
    );
    notifyListeners();

    _logger.logAppState(
      action: 'Starting background removal',
      state: {
        'provider': _state.selectedProvider,
        'image_size': _state.selectedImageBytes!.length,
      },
    );

    try {
      // Используем API ключ из контроллера
      _backgroundService.apiKey = apiKey;
      _backgroundService.apiProvider = _state.selectedProvider;

      final result = await _backgroundService.removeBackgroundFromBytes(
        _state.selectedImageBytes!,
      );

      if (result != null) {
        _logger.logAppState(
          action: 'Background removal completed',
          state: {'result_size': result.length},
        );
        _state = _state.copyWith(
          processedImage: result,
          isProcessing: false,
          errorMessage: null, // Явно очищаем ошибку при успехе
        );
      } else {
        _logger.logWarning(
          message: 'Background removal returned null',
          context: {'provider': _state.selectedProvider},
        );
        _state = _state.copyWith(
          errorMessage: 'Не удалось обработать изображение',
          isProcessing: false,
        );
      }
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Background removal failed',
        error: e,
        stackTrace: stackTrace,
      );
      _state = _state.copyWith(
        errorMessage: _formatErrorMessage(e.toString()),
        isProcessing: false,
      );
    }
    notifyListeners();
  }

  /// Размытие фона
  Future<void> blurBackground() async {
    if (_state.selectedImageBytes == null) {
      _state = _state.copyWith(
        errorMessage: 'Пожалуйста, выберите изображение',
      );
      notifyListeners();
      return;
    }

    // Проверяем API ключ напрямую из контроллера
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _state = _state.copyWith(errorMessage: 'Пожалуйста, введите API ключ');
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      isProcessing: true,
      errorMessage: null,
      processedImage: null, // Очищаем предыдущий результат
    );
    notifyListeners();

    try {
      // Используем API ключ из контроллера
      _backgroundService.apiKey = apiKey;
      _backgroundService.apiProvider = _state.selectedProvider;

      // Вызываем размытие напрямую, без промежуточного показа изображения без фона
      final result = await _backgroundService.blurBackgroundFromBytes(
        _state.selectedImageBytes!,
        blurRadius: _state.blurRadius,
      );

      if (result != null) {
        _logger.logAppState(
          action: 'Background blur completed',
          state: {'result_size': result.length},
        );
        _state = _state.copyWith(
          processedImage: result,
          isProcessing: false,
          errorMessage: null, // Явно очищаем ошибку при успехе
        );
      } else {
        _logger.logWarning(
          message: 'Background blur returned null',
          context: {
            'provider': _state.selectedProvider,
            'blur_radius': _state.blurRadius,
          },
        );
        _state = _state.copyWith(
          errorMessage: 'Не удалось размыть фон',
          isProcessing: false,
        );
      }
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Background blur failed',
        error: e,
        stackTrace: stackTrace,
      );
      _state = _state.copyWith(
        errorMessage: _formatErrorMessage(e.toString()),
        isProcessing: false,
      );
    }
    notifyListeners();
  }

  /// Обновление провайдера
  void updateProvider(String provider) {
    _state = _state.copyWith(selectedProvider: provider);
    _storageService.saveProvider(provider);
    notifyListeners();
  }

  /// Обновление радиуса размытия
  void updateBlurRadius(double radius) {
    _state = _state.copyWith(blurRadius: radius);
    _storageService.saveBlurRadius(radius);
    notifyListeners();
  }

  String _formatErrorMessage(String errorStr) {
    if (errorStr.contains('Недостаточно')) {
      return errorStr.replaceAll('Exception: ', '');
    } else if (errorStr.contains('Не удалось определить')) {
      return errorStr.replaceAll('Exception: ', '');
    } else if (errorStr.contains('Превышен лимит')) {
      return errorStr.replaceAll('Exception: ', '');
    } else if (errorStr.contains('Неверный API')) {
      return errorStr.replaceAll('Exception: ', '');
    } else {
      return 'Ошибка: ${errorStr.replaceAll('Exception: ', '')}';
    }
  }

  @override
  void dispose() {
    _saveApiKeyTimer?.cancel();
    apiKeyController.dispose();
    super.dispose();
  }
}
