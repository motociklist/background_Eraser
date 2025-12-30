import 'package:flutter/material.dart';

/// Провайдер для передачи callback изменения языка
class LocaleProvider extends InheritedWidget {
  final ValueChanged<Locale> onLocaleChanged;

  const LocaleProvider({
    super.key,
    required this.onLocaleChanged,
    required super.child,
  });

  static LocaleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleProvider>();
  }

  @override
  bool updateShouldNotify(LocaleProvider oldWidget) {
    return onLocaleChanged != oldWidget.onLocaleChanged;
  }
}

