import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_state.dart';
import '../services/background_service.dart';

/// Контроллер для управления обработкой изображений
class ImageProcessingController extends ChangeNotifier {
  final BackgroundService _backgroundService = BackgroundService();
  final ImagePicker _imagePicker = ImagePicker();

  AppState _state = const AppState();
  AppState get state => _state;

  final TextEditingController apiKeyController = TextEditingController();

  ImageProcessingController() {
    apiKeyController.addListener(_onApiKeyChanged);
  }

  void _onApiKeyChanged() {
    _state = _state.copyWith(apiKey: apiKeyController.text);
    notifyListeners();
  }

  /// Выбор изображения
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);

      if (image != null) {
        final bytes = await image.readAsBytes();
        _state = _state.copyWith(
          selectedImageBytes: bytes,
          processedImage: null,
          errorMessage: null,
        );
        notifyListeners();
      }
    } catch (e) {
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

    try {
      // Используем API ключ из контроллера
      _backgroundService.apiKey = apiKey;
      _backgroundService.apiProvider = _state.selectedProvider;

      final result = await _backgroundService.removeBackgroundFromBytes(
        _state.selectedImageBytes!,
      );

      if (result != null) {
        _state = _state.copyWith(processedImage: result, isProcessing: false);
      } else {
        _state = _state.copyWith(
          errorMessage: 'Не удалось обработать изображение',
          isProcessing: false,
        );
      }
    } catch (e) {
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
        _state = _state.copyWith(processedImage: result, isProcessing: false);
      } else {
        _state = _state.copyWith(
          errorMessage: 'Не удалось размыть фон',
          isProcessing: false,
        );
      }
    } catch (e) {
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
    notifyListeners();
  }

  /// Обновление радиуса размытия
  void updateBlurRadius(double radius) {
    _state = _state.copyWith(blurRadius: radius);
    notifyListeners();
  }

  String _formatErrorMessage(String errorStr) {
    if (errorStr.contains('Не удалось определить')) {
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
    apiKeyController.dispose();
    super.dispose();
  }
}
