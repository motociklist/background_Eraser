import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

/// Сервис для управления языком приложения
class LocaleService {
  static const String _localeKey = 'app_locale';
  static LocaleService? _instance;
  static LocaleService get instance => _instance ??= LocaleService._();

  LocaleService._();

  final FirestoreService _firestoreService = FirestoreService.instance;
  final AuthService _authService = AuthService.instance;

  /// Получить сохраненный язык
  /// Сначала пытается загрузить из Firestore (если пользователь авторизован),
  /// затем из SharedPreferences
  Future<Locale?> getSavedLocale() async {
    try {
      // Если пользователь авторизован, пытаемся загрузить из Firestore
      if (_authService.isAuthenticated) {
        try {
          final localeCode = await _firestoreService.loadLocale();
          if (localeCode != null && localeCode.isNotEmpty) {
            // Сохраняем также локально для быстрого доступа
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_localeKey, localeCode);
            return Locale(localeCode);
          }
        } catch (e) {
          // Если не удалось загрузить из Firestore, продолжаем с локальным хранилищем
        }
      }

      // Загружаем из локального хранилища
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      if (localeCode != null && localeCode.isNotEmpty) {
        return Locale(localeCode);
      }
    } catch (e) {
      // Игнорируем ошибки при чтении
    }
    return null;
  }

  /// Сохранить выбранный язык
  /// Сохраняет в Firestore (если пользователь авторизован) и в SharedPreferences
  Future<void> setLocale(Locale locale) async {
    try {
      final localeCode = locale.languageCode;

      // Сохраняем локально для быстрого доступа
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, localeCode);

      // Если пользователь авторизован, сохраняем в Firestore
      if (_authService.isAuthenticated) {
        try {
          await _firestoreService.saveLocale(localeCode);
        } catch (e) {
          // Если не удалось сохранить в Firestore, продолжаем работу
          // Язык уже сохранен локально
        }
      }
    } catch (e) {
      // Игнорируем ошибки при сохранении
    }
  }

  /// Получить список поддерживаемых языков
  List<Locale> getSupportedLocales() {
    return const [
      Locale('en', ''), // English
      Locale('ru', ''), // Russian
    ];
  }

  /// Получить название языка для отображения
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      default:
        return locale.languageCode;
    }
  }
}

