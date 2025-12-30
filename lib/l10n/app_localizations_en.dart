// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Background Eraser';

  @override
  String get editor => 'Editor';

  @override
  String get profile => 'Profile';

  @override
  String get selectImage => 'Select Image';

  @override
  String get removeBackground => 'Remove Background';

  @override
  String get blurBackground => 'Blur Background';

  @override
  String get saveImage => 'Save Image';

  @override
  String get apiProvider => 'API Provider';

  @override
  String get blurRadius => 'Blur Radius';

  @override
  String get processing => 'Processing...';

  @override
  String get error => 'Error';
}
