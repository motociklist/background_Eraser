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

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get settings => 'Settings';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutTitle => 'Sign Out';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String signOutError(String error) {
    return 'Sign out error: $error';
  }

  @override
  String get accountInfo => 'Account Information';

  @override
  String get email => 'Email';

  @override
  String get userId => 'User ID';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get registrationDate => 'Registration Date';

  @override
  String get welcome => 'Welcome!';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signInToAccount => 'Sign in to your account';

  @override
  String get registerToStart => 'Register to get started';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordMinLength => 'Minimum 6 characters';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get signIn => 'Sign In';

  @override
  String get register => 'Register';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get imageDownloaded => 'Image downloaded successfully';

  @override
  String get imageSavedToDownloads => 'Image saved to Downloads folder';

  @override
  String get imageSavedToImages =>
      'Image saved to Images/BackgroundEraser folder';

  @override
  String get imageSavedToInternal => 'Image saved to app internal storage';

  @override
  String get imageSavedToGallery => 'Image saved to gallery';

  @override
  String get imageSaved => 'Image saved';

  @override
  String saveError(String error) {
    return 'Save error: $error';
  }

  @override
  String get processingImage => 'Processing image...';

  @override
  String get imageSelection => 'Image Selection';

  @override
  String get originalImage => 'Original Image';

  @override
  String get processedImage => 'Processed Image';

  @override
  String get selectProvider => 'Select provider';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get noImageSelected => 'No image selected';

  @override
  String get storageAccessDenied => 'Failed to access storage';

  @override
  String get accessDenied => 'Access denied';
}
