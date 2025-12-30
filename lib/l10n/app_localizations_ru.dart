// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Удаление фона';

  @override
  String get editor => 'Редактор';

  @override
  String get profile => 'Профиль';

  @override
  String get selectImage => 'Выбрать изображение';

  @override
  String get removeBackground => 'Удалить фон';

  @override
  String get blurBackground => 'Размыть фон';

  @override
  String get saveImage => 'Сохранить изображение';

  @override
  String get apiProvider => 'API Провайдер';

  @override
  String get blurRadius => 'Радиус размытия';

  @override
  String get processing => 'Обработка...';

  @override
  String get error => 'Ошибка';
}
