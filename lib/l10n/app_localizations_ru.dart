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

  @override
  String get language => 'Язык';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get settings => 'Настройки';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutTitle => 'Выход из аккаунта';

  @override
  String get signOutConfirmation => 'Вы уверены, что хотите выйти из аккаунта?';

  @override
  String get cancel => 'Отмена';

  @override
  String signOutError(String error) {
    return 'Ошибка при выходе: $error';
  }

  @override
  String get accountInfo => 'Информация об аккаунте';

  @override
  String get email => 'Email';

  @override
  String get userId => 'ID пользователя';

  @override
  String get notSpecified => 'Не указан';

  @override
  String get registrationDate => 'Дата регистрации';

  @override
  String get welcome => 'Добро пожаловать!';

  @override
  String get createAccount => 'Создайте аккаунт';

  @override
  String get signInToAccount => 'Войдите в свой аккаунт';

  @override
  String get registerToStart => 'Зарегистрируйтесь для начала работы';

  @override
  String get enterEmail => 'Введите email';

  @override
  String get enterValidEmail => 'Введите корректный email';

  @override
  String get password => 'Пароль';

  @override
  String get passwordMinLength => 'Минимум 6 символов';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get passwordTooShort => 'Пароль должен быть не менее 6 символов';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get repeatPassword => 'Повторите пароль';

  @override
  String get confirmPasswordRequired => 'Подтвердите пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get signIn => 'Войти';

  @override
  String get register => 'Зарегистрироваться';

  @override
  String get noAccount => 'Нет аккаунта? ';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? ';

  @override
  String errorOccurred(String error) {
    return 'Произошла ошибка: $error';
  }

  @override
  String get imageDownloaded => 'Изображение скачано успешно';

  @override
  String get imageSavedToDownloads =>
      'Изображение сохранено в папку \"Загрузки\"';

  @override
  String get imageSavedToImages =>
      'Изображение сохранено в папку \"Изображения/BackgroundEraser\"';

  @override
  String get imageSavedToInternal =>
      'Изображение сохранено во внутреннее хранилище приложения';

  @override
  String get imageSavedToGallery => 'Изображение сохранено в галерею';

  @override
  String get imageSaved => 'Изображение сохранено';

  @override
  String saveError(String error) {
    return 'Ошибка сохранения: $error';
  }

  @override
  String get processingImage => 'Обработка изображения...';

  @override
  String get imageSelection => 'Выбор изображения';

  @override
  String get originalImage => 'Оригинальное изображение';

  @override
  String get processedImage => 'Обработанное изображение';

  @override
  String get selectProvider => 'Выберите провайдера';

  @override
  String get gallery => 'Галерея';

  @override
  String get camera => 'Камера';

  @override
  String get noImageSelected => 'Изображение не выбрано';

  @override
  String get storageAccessDenied => 'Не удалось получить доступ к хранилищу';

  @override
  String get accessDenied => 'Не удалось получить доступ';
}
