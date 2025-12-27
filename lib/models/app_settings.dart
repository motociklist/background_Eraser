/// Модель настроек приложения для хранения в Hive
class AppSettings {
  final String? apiKey;
  final String apiProvider;
  final double blurRadius;

  AppSettings({
    this.apiKey,
    this.apiProvider = 'removebg',
    this.blurRadius = 10.0,
  });

  /// Создание из Map (для загрузки из Hive)
  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      apiKey: map['apiKey'] as String?,
      apiProvider: map['apiProvider'] as String? ?? 'removebg',
      blurRadius: (map['blurRadius'] as num?)?.toDouble() ?? 10.0,
    );
  }

  /// Преобразование в Map (для сохранения в Hive)
  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'apiProvider': apiProvider,
      'blurRadius': blurRadius,
    };
  }

  /// Копирование с обновлением полей
  AppSettings copyWith({
    String? apiKey,
    String? apiProvider,
    double? blurRadius,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      apiProvider: apiProvider ?? this.apiProvider,
      blurRadius: blurRadius ?? this.blurRadius,
    );
  }
}
