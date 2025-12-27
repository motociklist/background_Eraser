import 'dart:async';
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

  // Параметры retry
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const Duration requestTimeout = Duration(seconds: 60);

  BackgroundService({this.apiKey, this.apiProvider = 'removebg'}) {
    _logger.init();
  }

  /// Проверяет, нужно ли повторять запрос при данной ошибке
  bool _shouldRetry(dynamic error, int? statusCode) {
    // Не повторяем при ошибках клиента (4xx), кроме некоторых случаев
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      // Повторяем только при 429 (Too Many Requests) и 408 (Request Timeout)
      if (statusCode == 429 || statusCode == 408) {
        return true;
      }
      // Не повторяем при других ошибках клиента
      return false;
    }

    // Повторяем при ошибках сервера (5xx)
    if (statusCode != null && statusCode >= 500) {
      return true;
    }

    // Повторяем при сетевых ошибках и таймаутах
    if (error is Exception || error is TimeoutException) {
      return true;
    }

    // Повторяем при других исключениях (сетевые проблемы)
    return true;
  }

  /// Выполняет запрос с retry логикой
  Future<http.StreamedResponse> _executeWithRetry(
    Future<http.StreamedResponse> Function() requestFunction,
    String provider,
  ) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      attempt++;
      final stopwatch = Stopwatch()..start();

      try {
        _logger.logInfo(
          message: 'API request attempt',
          data: {
            'provider': provider,
            'attempt': attempt,
            'max_retries': maxRetries,
          },
        );

        final response = await requestFunction().timeout(
          requestTimeout,
          onTimeout: () {
            throw TimeoutException(
              'API request timeout after ${requestTimeout.inSeconds} seconds',
              requestTimeout,
            );
          },
        );

        stopwatch.stop();

        // Если успешный ответ, возвращаем его
        if (response.statusCode == 200) {
          if (attempt > 1) {
            _logger.logInfo(
              message: 'API request succeeded after retry',
              data: {
                'provider': provider,
                'attempt': attempt,
                'duration_ms': stopwatch.elapsedMilliseconds,
              },
            );
          }
          return response;
        }

        // Проверяем, нужно ли повторять при данной ошибке
        if (!_shouldRetry(null, response.statusCode)) {
          // Не повторяем при ошибках клиента (4xx), возвращаем ответ как есть
          // Логирование ошибки будет выполнено в вызывающем методе
          return response;
        }

        // Если это последняя попытка, возвращаем ответ
        if (attempt >= maxRetries) {
          return response;
        }

        // Вычисляем задержку с экспоненциальным backoff
        final delay = Duration(
          milliseconds: initialRetryDelay.inMilliseconds * (1 << (attempt - 1)),
        );

        _logger.logWarning(
          message: 'API request failed, retrying',
          context: {
            'provider': provider,
            'attempt': attempt,
            'status_code': response.statusCode,
            'next_retry_in_ms': delay.inMilliseconds,
          },
        );

        await Future.delayed(delay);
        lastException = null;
      } catch (e) {
        stopwatch.stop();
        lastException = e is Exception ? e : Exception(e.toString());

        // Проверяем, нужно ли повторять при данной ошибке
        if (!_shouldRetry(e, null)) {
          // Не повторяем, пробрасываем исключение
          rethrow;
        }

        // Если это последняя попытка, пробрасываем исключение
        if (attempt >= maxRetries) {
          _logger.logError(
            message: 'API request failed after all retries',
            error: lastException,
            stackTrace: null,
          );
          rethrow;
        }

        // Вычисляем задержку с экспоненциальным backoff
        final delay = Duration(
          milliseconds: initialRetryDelay.inMilliseconds * (1 << (attempt - 1)),
        );

        _logger.logWarning(
          message: 'API request error, retrying',
          context: {
            'provider': provider,
            'attempt': attempt,
            'error': e.toString(),
            'next_retry_in_ms': delay.inMilliseconds,
          },
        );

        await Future.delayed(delay);
      }
    }

    // Если дошли сюда, все попытки исчерпаны
    if (lastException != null) {
      throw lastException;
    }
    throw Exception('API request failed after $maxRetries attempts');
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
      // Пробрасываем исключение дальше, чтобы контроллер мог показать понятное сообщение
      rethrow;
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

    try {
      // Создаем функцию запроса для retry
      Future<http.StreamedResponse> makeRequest() async {
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
        return request.send();
      }

      // Выполняем запрос с retry
      var response = await _executeWithRetry(makeRequest, 'Remove.bg');
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
          if (errorJson.contains('insufficient_credits') ||
              response.statusCode == 402) {
            throw Exception(
              'Недостаточно кредитов на вашем аккаунте. Попробуйте обновить план или попробуйте позже.',
            );
          } else if (errorJson.contains('unknown_foreground')) {
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
          final errorStr = e.toString();
          if (errorStr.contains('Недостаточно') ||
              errorStr.contains('Не удалось') ||
              errorStr.contains('Превышен') ||
              errorStr.contains('Неверный')) {
            rethrow;
          }
          throw Exception('Ошибка API Remove.bg: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      // Если это уже обработанное исключение с понятным сообщением, пробрасываем его дальше
      final errorStr = e.toString();
      if (errorStr.contains('Недостаточно') ||
          errorStr.contains('Не удалось') ||
          errorStr.contains('Превышен') ||
          errorStr.contains('Неверный')) {
        rethrow;
      }
      // Иначе логируем и пробрасываем
      _logger.logError(
        message: 'Remove.bg API request failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// PhotoRoom API (из байтов) - поддерживает веб
  Future<Uint8List?> _removeBackgroundPhotoRoomFromBytes(
    Uint8List imageBytes,
  ) async {
    final stopwatch = Stopwatch()..start();

    if (apiKey == null || apiKey!.isEmpty) {
      _logger.logError(
        message: 'PhotoRoom API key is missing',
        error: Exception('API key is required for PhotoRoom'),
        stackTrace: null,
      );
      throw Exception('API key is required for PhotoRoom');
    }

    _logger.logApiRequest(
      provider: 'PhotoRoom',
      endpoint: photoRoomApiUrl,
      headers: {'x-api-key': '***'},
      imageSize: imageBytes.length,
    );

    try {
      // Создаем функцию запроса для retry
      Future<http.StreamedResponse> makeRequest() async {
        var request = http.MultipartRequest('POST', Uri.parse(photoRoomApiUrl));
        request.headers.addAll({'x-api-key': apiKey!});
        request.files.add(
          http.MultipartFile.fromBytes(
            'image_file',
            imageBytes,
            filename: 'image.jpg',
          ),
        );
        return request.send();
      }

      // Выполняем запрос с retry
      var response = await _executeWithRetry(makeRequest, 'PhotoRoom');
      stopwatch.stop();

      if (response.statusCode == 200) {
        var responseBytes = await response.stream.toBytes();
        _logger.logApiSuccess(
          provider: 'PhotoRoom',
          statusCode: response.statusCode,
          responseSize: responseBytes.length,
          duration: stopwatch.elapsed,
        );
        return responseBytes;
      } else {
        var errorBody = await response.stream.bytesToString();
        _logger.logApiError(
          provider: 'PhotoRoom',
          statusCode: response.statusCode,
          error: 'API request failed',
          errorBody: errorBody,
          duration: stopwatch.elapsed,
        );
        throw Exception(
          'PhotoRoom API error: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError(
        message: 'PhotoRoom API request failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
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

    try {
      // Создаем функцию запроса для retry
      Future<http.StreamedResponse> makeRequest() async {
        var request = http.MultipartRequest('POST', Uri.parse(clipdropApiUrl));
        request.headers.addAll({'x-api-key': apiKey!});
        request.files.add(
          http.MultipartFile.fromBytes(
            'image_file',
            imageBytes,
            filename: 'image.jpg',
          ),
        );
        return request.send();
      }

      // Выполняем запрос с retry
      var response = await _executeWithRetry(makeRequest, 'Clipdrop');
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
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError(
        message: 'Clipdrop API request failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
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
      Uint8List? imageWithoutBg;
      try {
        imageWithoutBg = await removeBackgroundFromBytes(imageBytes);
      } catch (e) {
        // Если ошибка связана с API (недостаточно кредитов, неверный ключ и т.д.), пробрасываем дальше
        final errorStr = e.toString();
        if (errorStr.contains('Недостаточно') ||
            errorStr.contains('Неверный API') ||
            errorStr.contains('Превышен лимит') ||
            errorStr.contains('Не удалось определить')) {
          rethrow;
        }
        // Для других ошибок размываем все изображение как fallback
        _logger.logWarning(
          message: 'Background removal failed, blurring full image',
          context: {'blur_radius': blurRadius, 'error': errorStr},
        );
        return _blurFullImageFromBytes(imageBytes, blurRadius);
      }

      if (imageWithoutBg == null) {
        _logger.logWarning(
          message: 'Background removal returned null, blurring full image',
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
