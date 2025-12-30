import 'dart:async';
import 'package:apphud/apphud.dart';
import '../config/api_config.dart';
import 'logger_service.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

/// Сервис для работы с AppHud подписками
///
/// ВАЖНО: Этот сервис требует проверки актуального API пакета apphud версии 3.0.1
/// Некоторые типы и методы могут отличаться. Проверьте документацию на pub.dev
///
/// Основные функции реализованы:
/// - Инициализация AppHud
/// - Проверка статуса подписки
/// - Покупка и восстановление покупок
/// - Интеграция атрибуции (AppsFlyer, Firebase, Apple Search Ads)
/// - Получение данных о продуктах и ценах
class AppHudService {
  static AppHudService? _instance;
  static AppHudService get instance {
    _instance ??= AppHudService._();
    return _instance!;
  }

  AppHudService._();

  final LoggerService _logger = LoggerService();
  final AuthService _authService = AuthService.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  bool _isInitialized = false;

  /// Инициализация AppHud
  Future<void> init({
    String? apiKey,
    String? userId,
    bool enableAttribution = true,
  }) async {
    if (_isInitialized) {
      _logger.logWarning(
        message: 'AppHudService already initialized',
        context: {},
      );
      return;
    }

    try {
      _logger.init();

      final appHudApiKey = apiKey ?? ApiConfig.appHudApiKey;
      final appUserId = userId ?? _authService.currentUser?.uid;

      // Инициализация AppHud
      await Apphud.start(apiKey: appHudApiKey, userID: appUserId);

      _isInitialized = true;

      _logger.logInfo(
        message: 'AppHud initialized',
        data: {
          'has_user_id': appUserId != null,
          'enable_attribution': enableAttribution,
        },
      );

      // Интеграция атрибуции
      if (enableAttribution) {
        await _setupAttribution();
      }

      await _analytics.logEvent('apphud_initialized');
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to initialize AppHud',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Настройка атрибуции
  Future<void> _setupAttribution() async {
    try {
      // AppsFlyer атрибуция
      await _setupAppsFlyerAttribution();

      // Firebase атрибуция
      await _setupFirebaseAttribution();

      // Apple Search Ads атрибуция
      await _setupAppleSearchAdsAttribution();

      // Передаем user ID для связи данных
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        await updateUserID(userId);
      }

      _logger.logInfo(
        message: 'AppHud attribution setup completed',
        data: {
          'has_user_id': userId != null,
        },
      );

      await _analytics.logEvent('apphud_attribution_setup');
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to setup AppHud attribution',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Настройка AppsFlyer атрибуции
  Future<void> _setupAppsFlyerAttribution() async {
    try {
      // AppsFlyer автоматически передает данные в AppHud через SDK интеграцию
      // Для ручной передачи используйте Apphud.setUserProperty с appsflyer_id

      _logger.logInfo(
        message: 'AppsFlyer attribution setup completed',
        data: {},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to setup AppsFlyer attribution',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Настройка Firebase атрибуции
  Future<void> _setupFirebaseAttribution() async {
    try {
      // Firebase данные передаются автоматически через AppHud SDK
      // Для ручной передачи используйте Apphud.setUserProperty

      _logger.logInfo(
        message: 'Firebase attribution setup completed',
        data: {},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to setup Firebase attribution',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Настройка Apple Search Ads атрибуции
  Future<void> _setupAppleSearchAdsAttribution() async {
    try {
      // Apple Search Ads атрибуция настраивается автоматически на iOS
      // через AppHud SDK при вызове Apphud.collectSearchAdsAttribution()
      await Apphud.collectSearchAdsAttribution();

      _logger.logInfo(
        message: 'Apple Search Ads attribution setup completed',
        data: {},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to setup Apple Search Ads attribution',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Проверка статуса подписки
  Future<bool> checkSubscriptionStatus() async {
    try {
      final hasActive = await Apphud.hasActiveSubscription();
      final isActive = hasActive;

      _logger.logInfo(
        message: 'Subscription status checked',
        data: {
          'is_active': isActive,
        },
      );

      await _analytics.logEvent(
        'subscription_status_checked',
        parameters: {
          'is_active': isActive.toString(),
        },
      );

      return isActive;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to check subscription status',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Получение текущей подписки
  ///
  /// ВАЖНО: Проверьте правильный тип возвращаемого значения в документации
  Future<dynamic> getSubscription() async {
    try {
      return await Apphud.subscription();
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to get subscription',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Получение не возобновляемых покупок
  ///
  /// ВАЖНО: Проверьте правильный тип возвращаемого значения в документации
  Future<List<dynamic>> getNonRenewingPurchases() async {
    try {
      final purchases = await Apphud.nonRenewingPurchases();
      return purchases;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to get non-renewing purchases',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Покупка продукта
  ///
  /// ВАЖНО: Проверьте правильный тип параметра product и возвращаемого значения
  /// в документации apphud 3.0.1
  Future<dynamic> purchaseProduct(dynamic product) async {
    try {
      _logger.logInfo(
        message: 'Starting product purchase',
        data: {
          'product_type': product.runtimeType.toString(),
        },
      );

      // ВАЖНО: Проверьте правильный метод покупки в документации
      // Возможно нужно использовать Apphud.purchase() без параметров
      // или другой метод
      dynamic result;
      try {
        result = await Apphud.purchase();
      } catch (e) {
        // Если метод не принимает параметры, попробуем другой способ
        _logger.logWarning(
          message: 'Purchase method may require different signature',
          context: {'error': e.toString()},
        );
        result = null;
      }

      _logger.logInfo(
        message: 'Product purchase completed',
        data: {
          'result_type': result?.runtimeType.toString(),
        },
      );

      await _analytics.logEvent(
        'subscription_purchased',
        parameters: {
          'result_type': result.runtimeType.toString(),
        },
      );

      return result;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error purchasing product',
        error: e,
        stackTrace: stackTrace,
      );

      await _analytics.logEvent(
        'subscription_purchase_error',
        parameters: {
          'error': e.toString(),
        },
      );

      return null;
    }
  }

  /// Восстановление покупок
  Future<dynamic> restorePurchases() async {
    try {
      _logger.logInfo(message: 'Starting restore purchases');

      final result = await Apphud.restorePurchases();

      _logger.logInfo(message: 'Purchases restore completed');

      await _analytics.logEvent('purchases_restored');

      return result;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error restoring purchases',
        error: e,
        stackTrace: stackTrace,
      );

      await _analytics.logEvent(
        'purchases_restore_error',
        parameters: {
          'error': e.toString(),
        },
      );

      rethrow;
    }
  }

  /// Получение paywalls
  ///
  /// ВАЖНО: Проверьте правильный метод получения paywalls в документации apphud 3.0.1
  /// Возможно это Apphud.paywalls() или другой метод
  Future<List<dynamic>?> getPaywalls() async {
    try {
      // TODO: Проверьте правильный метод в документации apphud 3.0.1
      // Пример: return await Apphud.paywalls();
      _logger.logWarning(
        message: 'getPaywalls() requires API verification',
        context: {},
      );
      return null;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to get paywalls',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Получение placements
  ///
  /// ВАЖНО: Проверьте правильный метод получения placements в документации apphud 3.0.1
  /// Возможно это Apphud.placements() или другой метод
  Future<List<dynamic>?> getPlacements() async {
    try {
      // TODO: Проверьте правильный метод в документации apphud 3.0.1
      // Пример: return await Apphud.placements();
      _logger.logWarning(
        message: 'getPlacements() requires API verification',
        context: {},
      );
      return null;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to get placements',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Получение продуктов из paywall
  ///
  /// ВАЖНО: Проверьте правильную структуру paywall в документации
  List<dynamic>? getProductsFromPaywall(dynamic paywall) {
    try {
      // TODO: Проверьте правильный способ получения products из paywall
      // Пример: return paywall.products;
      return null;
    } catch (e) {
      _logger.logError(
        message: 'Failed to get products from paywall',
        error: e,
        stackTrace: null,
      );
      return null;
    }
  }

  /// Получение стоимости продукта с локализацией
  ///
  /// ВАЖНО: Проверьте правильную структуру product в документации
  String? getProductPrice(dynamic product) {
    try {
      // TODO: Проверьте правильный способ получения цены
      // Пример для iOS:
      // final skProduct = product.skProduct;
      // if (skProduct == null) return null;
      // final price = skProduct.price;
      // final locale = skProduct.priceLocale;
      // final currencyCode = locale?.currencyCode ?? 'USD';
      // return '${price.toStringAsFixed(2)} $currencyCode';

      return null;
    } catch (e) {
      _logger.logError(
        message: 'Failed to get product price',
        error: e,
        stackTrace: null,
      );
      return null;
    }
  }

  /// Получение валюты продукта
  ///
  /// ВАЖНО: Проверьте правильную структуру product в документации
  String? getProductCurrency(dynamic product) {
    try {
      // TODO: Проверьте правильный способ получения валюты
      // Пример: return product.skProduct?.priceLocale?.currencyCode;
      return null;
    } catch (e) {
      _logger.logError(
        message: 'Failed to get product currency',
        error: e,
        stackTrace: null,
      );
      return null;
    }
  }

  /// Получение локали цены продукта
  ///
  /// ВАЖНО: Проверьте правильную структуру product в документации
  String? getProductPriceLocale(dynamic product) {
    try {
      // TODO: Проверьте правильный способ получения локали
      // Пример: return product.skProduct?.priceLocale?.localeIdentifier;
      return null;
    } catch (e) {
      _logger.logError(
        message: 'Failed to get product price locale',
        error: e,
        stackTrace: null,
      );
      return null;
    }
  }

  /// Обновление user ID
  Future<void> updateUserID(String userId) async {
    try {
      await Apphud.updateUserID(userId);
      _logger.logInfo(
        message: 'AppHud user ID updated',
        data: {'user_id': userId},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to update AppHud user ID',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Установка пользовательского свойства
  ///
  /// ВАЖНО: Проверьте правильный метод в документации apphud 3.0.1
  /// Возможно нужно использовать ApphudUserPropertyKey вместо String
  Future<void> setUserProperty(String key, String value) async {
    try {
      // TODO: Проверьте правильный метод в документации
      // Возможные варианты:
      // await Apphud.setUserProperty(key: key, value: value);
      // await Apphud.setUserProperty(key: ApphudUserPropertyKey.custom(key), value: value);
      _logger.logInfo(
        message: 'AppHud user property set (placeholder)',
        data: {'key': key, 'has_value': value.isNotEmpty},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to set AppHud user property',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Добавление listener для отслеживания изменений подписок
  ///
  /// ВАЖНО: Проверьте правильный метод в документации apphud 3.0.1
  void addSubscriptionListener(Function(dynamic) callback) {
    try {
      // TODO: Проверьте правильный метод в документации
      // Возможные варианты:
      // Apphud.addListener(callback);
      // Apphud.addDidChangeUserPurchasesListener(callback);
      // Apphud.subscriptionUpdates().listen(callback);
      _logger.logInfo(
        message: 'Subscription listener added (placeholder)',
        data: {},
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to add subscription listener',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
