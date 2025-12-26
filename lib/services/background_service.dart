import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'logger_service.dart';

class BackgroundService {
  // Remove.bg API endpoint
  static const String removeBgApiUrl = 'https://api.remove.bg/v1.0/removebg';

  // Альтернативный API - PhotoRoom (если Remove.bg не работает)
  static const String photoRoomApiUrl = 'https://sdk.photoroom.com/v1/segment';

  // Clipdrop API (еще одна альтернатива)
  static const String clipdropApiUrl =
      'https://clipdrop-api.co/remove-background/v1';

  // API ключ - пользователь должен указать свой
  String? apiKey;
  String apiProvider = 'removebg'; // 'removebg', 'photoroom', 'clipdrop'
  final LoggerService _logger = LoggerService();

  BackgroundService({this.apiKey, this.apiProvider = 'removebg'}) {
    _logger.init();
  }

  /// Удаление фона с изображения (из байтов) - поддерживает веб
  Future<Uint8List?> removeBackgroundFromBytes(Uint8List imageBytes) async {
    final stopwatch = Stopwatch()..start();

    _logger.logImageProcessing(
      operation: 'Remove Background',
      imageSize: imageBytes.length,
      parameters: {'provider': apiProvider},
    );

    try {
      Uint8List? result;
      switch (apiProvider) {
        case 'removebg':
          result = await _removeBackgroundRemoveBgFromBytes(imageBytes);
          break;
        case 'photoroom':
          result = await _removeBackgroundPhotoRoomFromBytes(imageBytes);
          break;
        case 'clipdrop':
          result = await _removeBackgroundClipdropFromBytes(imageBytes);
          break;
        default:
          result = await _removeBackgroundRemoveBgFromBytes(imageBytes);
      }

      stopwatch.stop();

      if (result != null) {
        _logger.logImageProcessing(
          operation: 'Remove Background - Success',
          imageSize: result.length,
          parameters: {
            'provider': apiProvider,
            'duration_ms': stopwatch.elapsedMilliseconds,
          },
        );
      } else {
        _logger.logWarning(
          message: 'Remove Background returned null',
          context: {
            'provider': apiProvider,
            'duration_ms': stopwatch.elapsedMilliseconds,
          },
        );
      }

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logApiError(
        provider: apiProvider,
        statusCode: 0,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
      _logger.logError(
        message: 'Error removing background',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Remove.bg API (из байтов) - поддерживает веб
  Future<Uint8List?> _removeBackgroundRemoveBgFromBytes(
    Uint8List imageBytes,
  ) async {
    final stopwatch = Stopwatch()..start();

    if (apiKey == null || apiKey!.isEmpty) {
      _logger.logError(
        message: 'Remove.bg API key is missing',
        error: Exception('API key is required for Remove.bg'),
        stackTrace: null,
      );
      throw Exception('API key is required for Remove.bg');
    }

    _logger.logApiRequest(
      provider: 'Remove.bg',
      endpoint: removeBgApiUrl,
      headers: {'X-Api-Key': '***'},
      imageSize: imageBytes.length,
    );

    var request = http.MultipartRequest('POST', Uri.parse(removeBgApiUrl));
    request.headers.addAll({'X-Api-Key': apiKey!});
    request.files.add(
      http.MultipartFile.fromBytes(
        'image_file',
        imageBytes,
        filename: 'image.jpg',
      ),
    );
    request.fields['size'] = 'auto';

    var response = await request.send();
    stopwatch.stop();

    if (response.statusCode == 200) {
      var responseBytes = await response.stream.toBytes();
      _logger.logApiSuccess(
        provider: 'Remove.bg',
        statusCode: response.statusCode,
        responseSize: responseBytes.length,
        duration: stopwatch.elapsed,
      );
      return responseBytes;
    } else {
      var errorBody = await response.stream.bytesToString();
      _logger.logApiError(
        provider: 'Remove.bg',
        statusCode: response.statusCode,
        error: 'API request failed',
        errorBody: errorBody,
        duration: stopwatch.elapsed,
      );

      // Парсим JSON ошибки для более понятного сообщения
      try {
        final errorJson = errorBody;
        if (errorJson.contains('unknown_foreground')) {
          throw Exception(
            'Не удалось определить объект на изображении. Попробуйте изображение с четким объектом на фоне.',
          );
        } else if (errorJson.contains('rate_limit')) {
          throw Exception(
            'Превышен лимит запросов. Попробуйте позже или обновите план.',
          );
        } else if (errorJson.contains('invalid_api_key')) {
          throw Exception('Неверный API ключ. Проверьте правильность ключа.');
        } else {
          throw Exception(
            'Ошибка API Remove.bg: ${response.statusCode}. Проверьте изображение и API ключ.',
          );
        }
      } catch (e) {
        if (e.toString().contains('Не удалось') ||
            e.toString().contains('Превышен') ||
            e.toString().contains('Неверный')) {
          rethrow;
        }
        throw Exception('Ошибка API Remove.bg: ${response.statusCode}');
      }
    }
  }

  /// PhotoRoom API (из байтов) - поддерживает веб
  Future<Uint8List?> _removeBackgroundPhotoRoomFromBytes(
    Uint8List imageBytes,
  ) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key is required for PhotoRoom');
    }

    var request = http.MultipartRequest('POST', Uri.parse(photoRoomApiUrl));
    request.headers.addAll({'x-api-key': apiKey!});
    request.files.add(
      http.MultipartFile.fromBytes(
        'image_file',
        imageBytes,
        filename: 'image.jpg',
      ),
    );

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBytes = await response.stream.toBytes();
      return responseBytes;
    } else {
      var errorBody = await response.stream.bytesToString();
      throw Exception(
        'PhotoRoom API error: ${response.statusCode} - $errorBody',
      );
    }
  }

  /// Clipdrop API (из байтов) - поддерживает веб
  Future<Uint8List?> _removeBackgroundClipdropFromBytes(
    Uint8List imageBytes,
  ) async {
    final stopwatch = Stopwatch()..start();

    if (apiKey == null || apiKey!.isEmpty) {
      _logger.logError(
        message: 'Clipdrop API key is missing',
        error: Exception('API key is required for Clipdrop'),
        stackTrace: null,
      );
      throw Exception('API key is required for Clipdrop');
    }

    _logger.logApiRequest(
      provider: 'Clipdrop',
      endpoint: clipdropApiUrl,
      headers: {'x-api-key': '***'},
      imageSize: imageBytes.length,
    );

    var request = http.MultipartRequest('POST', Uri.parse(clipdropApiUrl));
    request.headers.addAll({'x-api-key': apiKey!});
    request.files.add(
      http.MultipartFile.fromBytes(
        'image_file',
        imageBytes,
        filename: 'image.jpg',
      ),
    );

    var response = await request.send();
    stopwatch.stop();

    if (response.statusCode == 200) {
      var responseBytes = await response.stream.toBytes();
      _logger.logApiSuccess(
        provider: 'Clipdrop',
        statusCode: response.statusCode,
        responseSize: responseBytes.length,
        duration: stopwatch.elapsed,
      );
      return responseBytes;
    } else {
      var errorBody = await response.stream.bytesToString();
      _logger.logApiError(
        provider: 'Clipdrop',
        statusCode: response.statusCode,
        error: 'API request failed',
        errorBody: errorBody,
        duration: stopwatch.elapsed,
      );
      throw Exception(
        'Clipdrop API error: ${response.statusCode} - $errorBody',
      );
    }
  }

  /// Размытие фона (из байтов) - поддерживает веб
  /// Сначала удаляет фон через API, затем применяет размытие
  Future<Uint8List?> blurBackgroundFromBytes(
    Uint8List imageBytes, {
    double blurRadius = 10.0,
  }) async {
    final stopwatch = Stopwatch()..start();

    _logger.logImageProcessing(
      operation: 'Blur Background',
      imageSize: imageBytes.length,
      parameters: {'blur_radius': blurRadius, 'provider': apiProvider},
    );

    try {
      // Сначала получаем изображение без фона
      Uint8List? imageWithoutBg = await removeBackgroundFromBytes(imageBytes);
      if (imageWithoutBg == null) {
        _logger.logWarning(
          message: 'Background removal failed, blurring full image',
          context: {'blur_radius': blurRadius},
        );
        // Если не удалось удалить фон, размываем все изображение
        return _blurFullImageFromBytes(imageBytes, blurRadius);
      }

      // Загружаем оригинальное изображение
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      // Загружаем изображение без фона
      final noBgImage = img.decodeImage(imageWithoutBg);
      if (noBgImage == null) return null;

      // Убеждаемся, что размеры совпадают
      final width = originalImage.width;
      final height = originalImage.height;

      // Изменяем размер изображения без фона под оригинал, если нужно
      final resizedNoBg = noBgImage.width != width || noBgImage.height != height
          ? img.copyResize(noBgImage, width: width, height: height)
          : noBgImage;

      // Размываем оригинальное изображение
      final blurredImage = img.copyResize(
        originalImage,
        width: width,
        height: height,
      );
      img.gaussianBlur(blurredImage, radius: blurRadius.toInt());

      // Создаем результат на основе размытого изображения
      final result = img.copyResize(blurredImage, width: width, height: height);

      // Используем compositeImage БЕЗ blend mode для правильной обработки альфа-канала
      // По умолчанию compositeImage правильно обрабатывает прозрачность:
      // - Прозрачные пиксели (фон) остаются из размытого изображения
      // - Непрозрачные пиксели (объект) заменяются из изображения без фона
      img.compositeImage(result, resizedNoBg, dstX: 0, dstY: 0);

      stopwatch.stop();
      final resultBytes = Uint8List.fromList(img.encodePng(result));

      _logger.logImageProcessing(
        operation: 'Blur Background - Success',
        imageSize: resultBytes.length,
        parameters: {
          'blur_radius': blurRadius,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );

      return resultBytes;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError(
        message: 'Error blurring background',
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback: просто размываем все изображение
      return _blurFullImageFromBytes(imageBytes, blurRadius);
    }
  }

  /// Размытие всего изображения (из байтов)
  Uint8List? _blurFullImageFromBytes(Uint8List imageBytes, double blurRadius) {
    try {
      _logger.logImageProcessing(
        operation: 'Blur Full Image',
        imageSize: imageBytes.length,
        parameters: {'blur_radius': blurRadius},
      );

      final image = img.decodeImage(imageBytes);
      if (image == null) {
        _logger.logWarning(
          message: 'Failed to decode image for blurring',
          context: null,
        );
        return null;
      }

      img.gaussianBlur(image, radius: blurRadius.toInt());
      final result = Uint8List.fromList(img.encodePng(image));

      _logger.logImageProcessing(
        operation: 'Blur Full Image - Success',
        imageSize: result.length,
        parameters: {'blur_radius': blurRadius},
      );

      return result;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error blurring full image',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
