import 'package:flutter/material.dart';

/// Константы стилей приложения
class AppStyles {
  AppStyles._();

  // Радиусы скругления
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 20.0;

  // Отступы
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMedium = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(24.0);

  // Размеры иконок
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Высоты
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;

  // Градиенты
  static LinearGradient primaryGradient(ColorScheme colorScheme) {
    return LinearGradient(
      colors: [
        colorScheme.primary,
        colorScheme.primary.withValues(alpha: 0.8),
      ],
    );
  }

  static LinearGradient secondaryGradient(ColorScheme colorScheme) {
    return LinearGradient(
      colors: [
        colorScheme.secondary,
        colorScheme.secondary.withValues(alpha: 0.8),
      ],
    );
  }

  static LinearGradient purpleGradient() {
    return LinearGradient(
      colors: [Colors.purple.shade600, Colors.purple.shade400],
    );
  }

  // Тени
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> buttonShadow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

