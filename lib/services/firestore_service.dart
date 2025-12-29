import 'package:cloud_firestore/cloud_firestore.dart';
import 'logger_service.dart';
import 'auth_service.dart';

/// Сервис для работы с Firebase Firestore
/// Хранит API ключи пользователей в облачной базе данных
class FirestoreService {
  static FirestoreService? _instance;
  static FirestoreService get instance {
    _instance ??= FirestoreService._();
    return _instance!;
  }

  FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService.instance;
  final LoggerService _logger = LoggerService();

  /// Коллекция для хранения настроек пользователей
  static const String _usersCollection = 'users';
  static const String _apiKeyField = 'apiKey';
  static const String _apiProviderField = 'apiProvider';
  static const String _blurRadiusField = 'blurRadius';
  static const String _updatedAtField = 'updatedAt';

  /// Получить ID текущего пользователя
  String? get _currentUserId => _authService.currentUser?.uid;

  /// Сохранение API ключа в Firestore
  Future<void> saveApiKey(String apiKey) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        _logger.logWarning(
          message: 'Cannot save API key: user not authenticated',
          context: null,
        );
        throw Exception('Пользователь не авторизован');
      }

      await _firestore.collection(_usersCollection).doc(userId).set({
        _apiKeyField: apiKey,
        _updatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.logInfo(
        message: 'API key saved to Firestore',
        data: {'user_id': userId, 'has_key': apiKey.isNotEmpty},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to save API key to Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Загрузка API ключа из Firestore
  Future<String?> loadApiKey() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        _logger.logWarning(
          message: 'Cannot load API key: user not authenticated',
          context: null,
        );
        return null;
      }

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        _logger.logInfo(message: 'User document not found in Firestore');
        return null;
      }

      final data = doc.data();
      final apiKey = data?[_apiKeyField] as String?;

      _logger.logInfo(
        message: 'API key loaded from Firestore',
        data: {
          'user_id': userId,
          'has_key': apiKey != null && apiKey.isNotEmpty,
        },
      );

      return apiKey;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to load API key from Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Сохранение провайдера в Firestore
  Future<void> saveApiProvider(String provider) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        _logger.logWarning(
          message: 'Cannot save provider: user not authenticated',
          context: null,
        );
        throw Exception('Пользователь не авторизован');
      }

      await _firestore.collection(_usersCollection).doc(userId).set({
        _apiProviderField: provider,
        _updatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.logInfo(
        message: 'API provider saved to Firestore',
        data: {'user_id': userId, 'provider': provider},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to save API provider to Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Загрузка провайдера из Firestore
  Future<String?> loadApiProvider() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return null;
      }

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      return data?[_apiProviderField] as String?;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to load API provider from Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Сохранение радиуса размытия в Firestore
  Future<void> saveBlurRadius(double radius) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      await _firestore.collection(_usersCollection).doc(userId).set({
        _blurRadiusField: radius,
        _updatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.logInfo(
        message: 'Blur radius saved to Firestore',
        data: {'user_id': userId, 'radius': radius},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to save blur radius to Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Загрузка радиуса размытия из Firestore
  Future<double?> loadBlurRadius() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return null;
      }

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      final radius = data?[_blurRadiusField];
      if (radius is num) {
        return radius.toDouble();
      }
      return null;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to load blur radius from Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Загрузка всех настроек пользователя из Firestore
  Future<Map<String, dynamic>?> loadUserSettings() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return null;
      }

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      _logger.logInfo(
        message: 'User settings loaded from Firestore',
        data: {'user_id': userId},
      );

      return {
        'apiKey': data?[_apiKeyField] as String?,
        'apiProvider': data?[_apiProviderField] as String?,
        'blurRadius': data?[_blurRadiusField] as double?,
      };
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to load user settings from Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Удаление всех данных пользователя из Firestore
  Future<void> deleteUserData() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return;
      }

      await _firestore.collection(_usersCollection).doc(userId).delete();

      _logger.logInfo(
        message: 'User data deleted from Firestore',
        data: {'user_id': userId},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to delete user data from Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

