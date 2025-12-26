import 'dart:typed_data';

/// Модель состояния приложения
class AppState {
  final Uint8List? selectedImageBytes;
  final Uint8List? processedImage;
  final bool isProcessing;
  final String? errorMessage;
  final String apiKey;
  final String selectedProvider;
  final double blurRadius;

  const AppState({
    this.selectedImageBytes,
    this.processedImage,
    this.isProcessing = false,
    this.errorMessage,
    this.apiKey = '',
    this.selectedProvider = 'removebg',
    this.blurRadius = 10.0,
  });

  AppState copyWith({
    Uint8List? selectedImageBytes,
    Uint8List? processedImage,
    bool? isProcessing,
    String? errorMessage,
    String? apiKey,
    String? selectedProvider,
    double? blurRadius,
  }) {
    return AppState(
      selectedImageBytes: selectedImageBytes ?? this.selectedImageBytes,
      processedImage: processedImage ?? this.processedImage,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      apiKey: apiKey ?? this.apiKey,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      blurRadius: blurRadius ?? this.blurRadius,
    );
  }
}

