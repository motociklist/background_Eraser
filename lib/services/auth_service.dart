import 'package:firebase_auth/firebase_auth.dart';
import 'analytics_service.dart';
import 'logger_service.dart';

/// Сервис для аутентификации пользователей
class AuthService {
  static AuthService? _instance;
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LoggerService _logger = LoggerService();
  final AnalyticsService _analytics = AnalyticsService.instance;

  /// Текущий пользователь
  User? get currentUser => _auth.currentUser;

  /// Поток изменений состояния аутентификации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Проверка, авторизован ли пользователь
  bool get isAuthenticated => currentUser != null;

  /// Email текущего пользователя
  String? get userEmail => currentUser?.email;

  /// Инициализация сервиса
  void init() {
    _logger.init();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _logger.logInfo(
          message: 'User signed in',
          data: {'email': user.email, 'uid': user.uid},
        );
        _analytics.setUserProperty('user_id', user.uid);
        _analytics.logEvent('user_signed_in', parameters: {
          'email': user.email ?? '',
          'uid': user.uid,
        });
      } else {
        _logger.logInfo(message: 'User signed out');
        _analytics.logEvent('user_signed_out');
      }
    });
  }

  /// Регистрация нового пользователя
  Future<UserCredential?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      _logger.logInfo(
        message: 'Attempting user registration',
        data: {'email': email},
      );

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Отправка email подтверждения (опционально)
      await userCredential.user?.sendEmailVerification();

      _logger.logInfo(
        message: 'User registered successfully',
        data: {
          'email': email,
          'uid': userCredential.user?.uid,
        },
      );

      // Аналитика: успешная регистрация
      await _analytics.logEvent('user_registered', parameters: {
        'email': email,
        'uid': userCredential.user?.uid ?? '',
        'method': 'email',
      });

      // Устанавливаем пользовательское свойство
      if (userCredential.user != null) {
        await _analytics.setUserProperty('user_id', userCredential.user!.uid);
        await _analytics.setUserProperty('user_email', email);
      }

      return userCredential;
    } on FirebaseAuthException catch (e, stackTrace) {
      _logger.logError(
        message: 'Registration failed',
        error: e,
        stackTrace: stackTrace,
      );

      // Аналитика: ошибка регистрации
      await _analytics.logError(
        errorName: 'registration_failed',
        errorMessage: e.code,
        additionalParams: {'email': email},
      );

      rethrow;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Unexpected registration error',
        error: e,
        stackTrace: stackTrace,
      );

      await _analytics.logError(
        errorName: 'registration_error',
        errorMessage: e.toString(),
        additionalParams: {'email': email},
      );

      rethrow;
    }
  }

  /// Вход существующего пользователя
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.logInfo(
        message: 'Attempting user sign in',
        data: {'email': email},
      );

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logger.logInfo(
        message: 'User signed in successfully',
        data: {
          'email': email,
          'uid': userCredential.user?.uid,
        },
      );

      // Аналитика: успешный вход
      await _analytics.logEvent('user_signed_in', parameters: {
        'email': email,
        'uid': userCredential.user?.uid ?? '',
        'method': 'email',
      });

      // Устанавливаем пользовательское свойство
      if (userCredential.user != null) {
        await _analytics.setUserProperty('user_id', userCredential.user!.uid);
        await _analytics.setUserProperty('user_email', email);
      }

      return userCredential;
    } on FirebaseAuthException catch (e, stackTrace) {
      _logger.logError(
        message: 'Sign in failed',
        error: e,
        stackTrace: stackTrace,
      );

      // Аналитика: ошибка входа
      await _analytics.logError(
        errorName: 'sign_in_failed',
        errorMessage: e.code,
        additionalParams: {'email': email},
      );

      rethrow;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Unexpected sign in error',
        error: e,
        stackTrace: stackTrace,
      );

      await _analytics.logError(
        errorName: 'sign_in_error',
        errorMessage: e.toString(),
        additionalParams: {'email': email},
      );

      rethrow;
    }
  }

  /// Выход пользователя
  Future<void> signOut() async {
    try {
      final email = currentUser?.email;
      await _auth.signOut();

      _logger.logInfo(
        message: 'User signed out',
        data: {'email': email},
      );

      // Аналитика: выход
      await _analytics.logEvent('user_signed_out', parameters: {
        'email': email ?? '',
      });
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Sign out failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Сброс пароля
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      _logger.logInfo(
        message: 'Password reset email sent',
        data: {'email': email},
      );

      // Аналитика: запрос сброса пароля
      await _analytics.logEvent('password_reset_requested', parameters: {
        'email': email,
      });
    } on FirebaseAuthException catch (e, stackTrace) {
      _logger.logError(
        message: 'Password reset failed',
        error: e,
        stackTrace: stackTrace,
      );

      await _analytics.logError(
        errorName: 'password_reset_failed',
        errorMessage: e.code,
        additionalParams: {'email': email},
      );

      rethrow;
    }
  }

  /// Получить понятное сообщение об ошибке
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Пароль слишком слабый';
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      default:
        return 'Ошибка: ${e.message ?? e.code}';
    }
  }
}

