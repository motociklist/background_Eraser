import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_state.dart';
import '../services/background_service.dart';
import '../services/logger_service.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

/// Контроллер для управления обработкой изображений
class ImageProcessingController extends ChangeNotifier {
  final BackgroundService _backgroundService = BackgroundService();
  final ImagePicker _imagePicker = ImagePicker();
  final LoggerService _logger = LoggerService();
  final FirestoreService _firestoreService = FirestoreService.instance;
  final AuthService _authService = AuthService.instance;

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
      // Если пользователь авторизован, загружаем из Firestore
      if (_authService.isAuthenticated) {
        final firestoreSettings = await _firestoreService.loadUserSettings();
        if (firestoreSettings != null) {
          // Загружаем API ключ из Firestore
          if (firestoreSettings['apiKey'] != null &&
              firestoreSettings['apiKey'].toString().isNotEmpty) {
            apiKeyController.text = firestoreSettings['apiKey'].toString();
          }

          // Загружаем провайдера из Firestore
          if (firestoreSettings['apiProvider'] != null &&
              firestoreSettings['apiProvider'].toString().isNotEmpty) {
            _state = _state.copyWith(
              selectedProvider: firestoreSettings['apiProvider'].toString(),
            );
          }

          // Загружаем радиус размытия из Firestore
          if (firestoreSettings['blurRadius'] != null) {
            final radius = firestoreSettings['blurRadius'] as double?;
            if (radius != null && radius > 0) {
              _state = _state.copyWith(blurRadius: radius);
            }
          }

          _logger.logInfo(
            message: 'Settings loaded from Firestore',
            data: {
              'provider': firestoreSettings['apiProvider']?.toString() ?? '',
              'has_api_key': firestoreSettings['apiKey'] != null &&
                  firestoreSettings['apiKey'].toString().isNotEmpty,
              'blur_radius': firestoreSettings['blurRadius']?.toString() ?? '',
            },
          );

          notifyListeners();
          return;
        }
      }

      // Если пользователь не авторизован, настройки не загружаются
      _logger.logInfo(message: 'User not authenticated, settings not loaded');
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

      // Если пользователь авторизован, сохраняем в Firestore
      if (_authService.isAuthenticated && currentKey.isNotEmpty) {
        _firestoreService.saveApiKey(currentKey).catchError((e) {
          _logger.logError(
            message: 'Failed to save API key to Firestore',
            error: e,
            stackTrace: null,
          );
        });
      }
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

        // Аналитика: изображение выбрано
        await AnalyticsService.instance.logEvent(
          'image_picked',
          parameters: {
            'source': source == ImageSource.camera ? 'camera' : 'gallery',
            'image_size': bytes.length,
          },
        );
      } else {
        // Аналитика: отмена выбора изображения
        await AnalyticsService.instance.logEvent('image_pick_cancelled');
      }
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error picking image',
        error: e,
        stackTrace: stackTrace,
      );
      _state = _state.copyWith(errorMessage: 'Ошибка выбора изображения: $e');
      notifyListeners();

      // Аналитика: ошибка выбора изображения
      await AnalyticsService.instance.logError(
        errorName: 'image_pick_error',
        errorMessage: e.toString(),
      );
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

    // Аналитика: начало удаления фона
    await AnalyticsService.instance.logImageProcessingStarted(
      operation: 'background_removal',
      provider: _state.selectedProvider,
      imageSize: _state.selectedImageBytes!.length,
    );

    // Логирование откладываем, чтобы не блокировать UI
    Future.microtask(() {
      _logger.logAppState(
        action: 'Starting background removal',
        state: {
          'provider': _state.selectedProvider,
          'image_size': _state.selectedImageBytes!.length,
        },
      );
    });

    final stopwatch = Stopwatch()..start();

    try {
      // Используем API ключ из контроллера
      _backgroundService.apiKey = apiKey;
      _backgroundService.apiProvider = _state.selectedProvider;

      final result = await _backgroundService.removeBackgroundFromBytes(
        _state.selectedImageBytes!,
      );

      stopwatch.stop();

      if (result != null) {
        // Устанавливаем результат и завершаем обработку одновременно
        _state = _state.copyWith(
          processedImage: result,
          isProcessing: false,
          errorMessage: null, // Явно очищаем ошибку при успехе
        );
        notifyListeners();

        // Аналитика: успешное удаление фона
        await AnalyticsService.instance.logImageProcessingCompleted(
          operation: 'background_removal',
          provider: _state.selectedProvider,
          durationMs: stopwatch.elapsedMilliseconds,
          resultSize: result.length,
        );

        // Логирование после обновления UI
        Future.microtask(() {
          _logger.logAppState(
            action: 'Background removal completed',
            state: {'result_size': result.length},
          );
        });
      } else {
        stopwatch.stop();

        _state = _state.copyWith(
          errorMessage: 'Не удалось обработать изображение',
          isProcessing: false,
        );
        notifyListeners();

        // Аналитика: ошибка удаления фона
        await AnalyticsService.instance.logImageProcessingFailed(
          operation: 'background_removal',
          provider: _state.selectedProvider,
          errorMessage: 'Result is null',
        );

        // Логирование после обновления UI
        Future.microtask(() {
          _logger.logWarning(
            message: 'Background removal returned null',
            context: {'provider': _state.selectedProvider},
          );
        });
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      _state = _state.copyWith(
        errorMessage: _formatErrorMessage(e.toString()),
        isProcessing: false,
      );
      notifyListeners();

      // Аналитика: ошибка удаления фона
      await AnalyticsService.instance.logImageProcessingFailed(
        operation: 'background_removal',
        provider: _state.selectedProvider,
        errorMessage: e.toString(),
      );

      // Логирование после обновления UI
      Future.microtask(() {
        _logger.logError(
          message: 'Background removal failed',
          error: e,
          stackTrace: stackTrace,
        );
      });
    }
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

    // Аналитика: начало размытия фона
    await AnalyticsService.instance.logImageProcessingStarted(
      operation: 'background_blur',
      provider: _state.selectedProvider,
      imageSize: _state.selectedImageBytes!.length,
      blurRadius: _state.blurRadius,
    );

    final stopwatch = Stopwatch()..start();

    try {
      // Используем API ключ из контроллера
      _backgroundService.apiKey = apiKey;
      _backgroundService.apiProvider = _state.selectedProvider;

      // Вызываем размытие напрямую, без промежуточного показа изображения без фона
      final result = await _backgroundService.blurBackgroundFromBytes(
        _state.selectedImageBytes!,
        blurRadius: _state.blurRadius,
      );

      stopwatch.stop();

      if (result != null) {
        // Устанавливаем результат и завершаем обработку одновременно
        _state = _state.copyWith(
          processedImage: result,
          isProcessing: false,
          errorMessage: null, // Явно очищаем ошибку при успехе
        );
        notifyListeners();

        // Аналитика: успешное размытие фона
        await AnalyticsService.instance.logImageProcessingCompleted(
          operation: 'background_blur',
          provider: _state.selectedProvider,
          durationMs: stopwatch.elapsedMilliseconds,
          resultSize: result.length,
          blurRadius: _state.blurRadius,
        );

        // Логирование после обновления UI
        Future.microtask(() {
          _logger.logAppState(
            action: 'Background blur completed',
            state: {'result_size': result.length},
          );
        });
      } else {
        stopwatch.stop();

        _state = _state.copyWith(
          errorMessage: 'Не удалось размыть фон',
          isProcessing: false,
        );
        notifyListeners();

        // Аналитика: ошибка размытия фона
        await AnalyticsService.instance.logImageProcessingFailed(
          operation: 'background_blur',
          provider: _state.selectedProvider,
          errorMessage: 'Result is null',
          blurRadius: _state.blurRadius,
        );

        // Логирование после обновления UI
        Future.microtask(() {
          _logger.logWarning(
            message: 'Background blur returned null',
            context: {
              'provider': _state.selectedProvider,
              'blur_radius': _state.blurRadius,
            },
          );
        });
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      _state = _state.copyWith(
        errorMessage: _formatErrorMessage(e.toString()),
        isProcessing: false,
      );
      notifyListeners();

      // Аналитика: ошибка размытия фона
      await AnalyticsService.instance.logImageProcessingFailed(
        operation: 'background_blur',
        provider: _state.selectedProvider,
        errorMessage: e.toString(),
        blurRadius: _state.blurRadius,
      );

      // Логирование после обновления UI
      Future.microtask(() {
        _logger.logError(
          message: 'Background blur failed',
          error: e,
          stackTrace: stackTrace,
        );
      });
    }
  }

  /// Обновление провайдера
  void updateProvider(String provider) {
    _state = _state.copyWith(selectedProvider: provider);

    // Если пользователь авторизован, сохраняем в Firestore
    if (_authService.isAuthenticated) {
      _firestoreService.saveApiProvider(provider).catchError((e) {
        _logger.logError(
          message: 'Failed to save provider to Firestore',
          error: e,
          stackTrace: null,
        );
      });
    }
    notifyListeners();

    // Аналитика: изменение провайдера
    AnalyticsService.instance.logEvent(
      'provider_changed',
      parameters: {'provider': provider},
    );
  }

  /// Обновление радиуса размытия
  void updateBlurRadius(double radius) {
    _state = _state.copyWith(blurRadius: radius);

    // Если пользователь авторизован, сохраняем в Firestore
    if (_authService.isAuthenticated) {
      _firestoreService.saveBlurRadius(radius).catchError((e) {
        _logger.logError(
          message: 'Failed to save blur radius to Firestore',
          error: e,
          stackTrace: null,
        );
      });
    }
    notifyListeners();

    // Аналитика: изменение радиуса размытия
    AnalyticsService.instance.logEvent(
      'blur_radius_changed',
      parameters: {'blur_radius': radius},
    );
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
