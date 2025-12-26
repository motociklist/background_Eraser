import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class BackgroundService {
  // Remove.bg API endpoint
  static const String removeBgApiUrl = 'https://api.remove.bg/v1.0/removebg';

  // Альтернативный API - PhotoRoom (если Remove.bg не работает)
  static const String photoRoomApiUrl = 'https://sdk.photoroom.com/v1/segment';

  // Clipdrop API (еще одна альтернатива)
  static const String clipdropApiUrl = 'https://clipdrop-api.co/remove-background/v1';

  // API ключ - пользователь должен указать свой
  String? apiKey;
  String apiProvider = 'removebg'; // 'removebg', 'photoroom', 'clipdrop'

  BackgroundService({this.apiKey, this.apiProvider = 'removebg'});


  /// Удаление фона с изображения (из байтов) - поддерживает веб
  Future<Uint8List?> removeBackgroundFromBytes(Uint8List imageBytes) async {
    try {
      switch (apiProvider) {
        case 'removebg':
          return await _removeBackgroundRemoveBgFromBytes(imageBytes);
        case 'photoroom':
          return await _removeBackgroundPhotoRoomFromBytes(imageBytes);
        case 'clipdrop':
          return await _removeBackgroundClipdropFromBytes(imageBytes);
        default:
          return await _removeBackgroundRemoveBgFromBytes(imageBytes);
      }
    } catch (e) {
      debugPrint('Error removing background: $e');
      return null;
    }
  }

  /// Remove.bg API (из байтов) - поддерживает веб
  Future<Uint8List?> _removeBackgroundRemoveBgFromBytes(Uint8List imageBytes) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key is required for Remove.bg');
    }

    var request = http.MultipartRequest('POST', Uri.parse(removeBgApiUrl));
    request.headers.addAll({'X-Api-Key': apiKey!});
    request.files.add(http.MultipartFile.fromBytes('image_file', imageBytes, filename: 'image.jpg'));
    request.fields['size'] = 'auto';

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBytes = await response.stream.toBytes();
      return responseBytes;
    } else {
      var errorBody = await response.stream.bytesToString();
      // Парсим JSON ошибки для более понятного сообщения
      try {
        final errorJson = errorBody;
        if (errorJson.contains('unknown_foreground')) {
          throw Exception('Не удалось определить объект на изображении. Попробуйте изображение с четким объектом на фоне.');
        } else if (errorJson.contains('rate_limit')) {
          throw Exception('Превышен лимит запросов. Попробуйте позже или обновите план.');
        } else if (errorJson.contains('invalid_api_key')) {
          throw Exception('Неверный API ключ. Проверьте правильность ключа.');
        } else {
          throw Exception('Ошибка API Remove.bg: ${response.statusCode}. Проверьте изображение и API ключ.');
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
  Future<Uint8List?> _removeBackgroundPhotoRoomFromBytes(Uint8List imageBytes) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key is required for PhotoRoom');
    }

    var request = http.MultipartRequest('POST', Uri.parse(photoRoomApiUrl));
    request.headers.addAll({'x-api-key': apiKey!});
    request.files.add(http.MultipartFile.fromBytes('image_file', imageBytes, filename: 'image.jpg'));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBytes = await response.stream.toBytes();
      return responseBytes;
    } else {
      var errorBody = await response.stream.bytesToString();
      throw Exception('PhotoRoom API error: ${response.statusCode} - $errorBody');
    }
  }

  /// Clipdrop API (из байтов) - поддерживает веб
  Future<Uint8List?> _removeBackgroundClipdropFromBytes(Uint8List imageBytes) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key is required for Clipdrop');
    }

    var request = http.MultipartRequest('POST', Uri.parse(clipdropApiUrl));
    request.headers.addAll({'x-api-key': apiKey!});
    request.files.add(http.MultipartFile.fromBytes('image_file', imageBytes, filename: 'image.jpg'));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBytes = await response.stream.toBytes();
      return responseBytes;
    } else {
      var errorBody = await response.stream.bytesToString();
      throw Exception('Clipdrop API error: ${response.statusCode} - $errorBody');
    }
  }

  /// Размытие фона (из байтов) - поддерживает веб
  /// Сначала удаляет фон через API, затем применяет размытие
  Future<Uint8List?> blurBackgroundFromBytes(Uint8List imageBytes, {double blurRadius = 10.0}) async {
    try {
      // Сначала получаем изображение без фона
      Uint8List? imageWithoutBg = await removeBackgroundFromBytes(imageBytes);
      if (imageWithoutBg == null) {
        // Если не удалось удалить фон, размываем все изображение
        return _blurFullImageFromBytes(imageBytes, blurRadius);
      }

      // Загружаем оригинальное изображение
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      // Загружаем изображение без фона
      final noBgImage = img.decodeImage(imageWithoutBg);
      if (noBgImage == null) return null;

      // Размываем оригинальное изображение
      final blurredImage = img.copyResize(originalImage, width: originalImage.width, height: originalImage.height);
      img.gaussianBlur(blurredImage, radius: blurRadius.toInt());

      // Накладываем объект без фона на размытое изображение
      // Используем композицию: сначала рисуем размытое изображение, затем объект без фона поверх
      final result = img.copyResize(blurredImage, width: blurredImage.width, height: blurredImage.height);

      // Композиция: накладываем изображение без фона поверх размытого
      img.compositeImage(result, noBgImage, dstX: 0, dstY: 0);

      return Uint8List.fromList(img.encodePng(result));
    } catch (e) {
      debugPrint('Error blurring background: $e');
      // Fallback: просто размываем все изображение
      return _blurFullImageFromBytes(imageBytes, blurRadius);
    }
  }

  /// Размытие всего изображения (из байтов)
  Uint8List? _blurFullImageFromBytes(Uint8List imageBytes, double blurRadius) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      img.gaussianBlur(image, radius: blurRadius.toInt());
      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      debugPrint('Error blurring full image: $e');
      return null;
    }
  }
}

