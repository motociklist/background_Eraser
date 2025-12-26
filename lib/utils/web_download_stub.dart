import 'dart:typed_data';

/// Заглушка для не-веб платформ
void downloadFileWeb(Uint8List bytes, String filename) {
  // Не используется на не-веб платформах
  throw UnsupportedError('downloadFileWeb is only supported on web');
}

