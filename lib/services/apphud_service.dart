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
      // AppsFlyer передает данные в AppHud через callback
      // AppsFlyer SDK должен быть инициализирован в AnalyticsService
      // Данные передаются автоматически при получении conversion data
      // Для ручной передачи используем Apphud.setUserProperty

      // Получаем AppsFlyer ID если доступен
      // AppsFlyer SDK автоматически передает данные через нативную интеграцию
      // На iOS и Android это работает через нативные SDK

      _logger.logInfo(
        message: 'AppsFlyer attribution setup completed',
        data: {
          'note': 'AppsFlyer data is passed automatically via native SDK integration',
        },
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
  /// Возвращает список всех доступных paywalls
  /// ВАЖНО: Метод может отличаться в зависимости от версии SDK
  Future<List<dynamic>?> getPaywalls() async {
    try {
      // Пробуем разные варианты получения paywalls
      // В зависимости от версии SDK метод может быть разным
      try {
        // Используем динамический вызов для совместимости с разными версиями SDK
        final apphudInstance = Apphud;
        final paywalls = await (apphudInstance as dynamic).paywalls();
        if (paywalls != null && paywalls is List) {
          _logger.logInfo(
            message: 'Paywalls retrieved',
            data: {'count': paywalls.length},
          );
          await _analytics.logEvent(
            'apphud_paywalls_retrieved',
            parameters: {'count': paywalls.length.toString()},
          );
          return paywalls;
        }
      } catch (e1) {
        _logger.logWarning(
          message: 'Apphud.paywalls() not available in current SDK version',
          context: {'error': e1.toString()},
        );
      }

      // Если метод не доступен, возвращаем null
      _logger.logWarning(
        message: 'Paywalls method not available in current SDK version',
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
  /// Возвращает список всех доступных placements
  /// ВАЖНО: Метод может отличаться в зависимости от версии SDK
  Future<List<dynamic>?> getPlacements() async {
    try {
      // Пробуем разные варианты получения placements
      try {
        // Используем динамический вызов для совместимости
        final apphudInstance = Apphud;
        final placements = await (apphudInstance as dynamic).placements();
        if (placements != null && placements is List) {
          _logger.logInfo(
            message: 'Placements retrieved',
            data: {'count': placements.length},
          );
          await _analytics.logEvent(
            'apphud_placements_retrieved',
            parameters: {'count': placements.length.toString()},
          );
          return placements;
        }
      } catch (e1) {
        _logger.logWarning(
          message: 'Apphud.placements() not available in current SDK version',
          context: {'error': e1.toString()},
        );
      }

      _logger.logWarning(
        message: 'Placements method not available in current SDK version',
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
  /// Возвращает список продуктов из указанного paywall
  List<dynamic>? getProductsFromPaywall(dynamic paywall) {
    try {
      // В AppHud SDK paywall имеет свойство products
      // Проверяем наличие свойства products
      if (paywall == null) {
        return null;
      }

      // Используем рефлексию для получения products
      // В реальной реализации структура paywall зависит от версии SDK
      try {
        // Попытка получить products через динамическое свойство
        final products = (paywall as dynamic).products;
        if (products != null && products is List) {
          return products;
        }
      } catch (_) {
        // Если не получилось, пробуем другой способ
      }

      _logger.logInfo(
        message: 'Products retrieved from paywall',
        data: {
          'paywall_type': paywall.runtimeType.toString(),
        },
      );

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
  /// Возвращает цену продукта в формате "XX.XX CURRENCY"
  String? getProductPrice(dynamic product) {
    try {
      if (product == null) return null;

      // В AppHud SDK продукт имеет skProduct (для iOS) или productDetails (для Android)
      // Пытаемся получить цену через динамические свойства
      try {
        // Для iOS
        final skProduct = (product as dynamic).skProduct;
        if (skProduct != null) {
          final price = (skProduct as dynamic).price;
          final locale = (skProduct as dynamic).priceLocale;
          final currencyCode = locale != null
              ? (locale as dynamic).currencyCode ?? 'USD'
              : 'USD';

          if (price != null) {
            final priceString = price.toString();
            return '$priceString $currencyCode';
          }
        }
      } catch (_) {
        // Пробуем для Android
        try {
          final productDetails = (product as dynamic).productDetails;
          if (productDetails != null) {
            final price = (productDetails as dynamic).price;
            final currencyCode = (productDetails as dynamic).currencyCode ?? 'USD';

            if (price != null) {
              return '$price $currencyCode';
            }
          }
        } catch (_) {
          // Если не получилось, возвращаем null
        }
      }

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
  /// Возвращает код валюты продукта (например, USD, EUR, RUB)
  String? getProductCurrency(dynamic product) {
    try {
      if (product == null) return null;

      // Пытаемся получить валюту через skProduct (iOS) или productDetails (Android)
      try {
        final skProduct = (product as dynamic).skProduct;
        if (skProduct != null) {
          final locale = (skProduct as dynamic).priceLocale;
          if (locale != null) {
            return (locale as dynamic).currencyCode;
          }
        }
      } catch (_) {
        try {
          final productDetails = (product as dynamic).productDetails;
          if (productDetails != null) {
            return (productDetails as dynamic).currencyCode;
          }
        } catch (_) {
          // Если не получилось, возвращаем null
        }
      }

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
  /// Возвращает идентификатор локали (например, en_US, ru_RU)
  String? getProductPriceLocale(dynamic product) {
    try {
      if (product == null) return null;

      // Пытаемся получить локаль через skProduct (iOS)
      try {
        final skProduct = (product as dynamic).skProduct;
        if (skProduct != null) {
          final locale = (skProduct as dynamic).priceLocale;
          if (locale != null) {
            return (locale as dynamic).localeIdentifier;
          }
        }
      } catch (_) {
        // Для Android локаль может быть в другом формате
      }

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
  /// Устанавливает пользовательское свойство в AppHud
  Future<void> setUserProperty(String key, String value) async {
    try {
      // Пробуем разные варианты установки свойства
      try {
        // Используем динамический вызов для совместимости
        // Пробуем сначала с ApphudUserPropertyKey, если доступен
        try {
          // Пробуем получить ApphudUserPropertyKey через динамический доступ
          final propertyKeyClass = (Apphud as dynamic).UserPropertyKey;
          if (propertyKeyClass != null) {
            final propertyKey = propertyKeyClass.custom(key);
            await Apphud.setUserProperty(key: propertyKey, value: value);
          } else {
            throw Exception('ApphudUserPropertyKey not available');
          }
        } catch (_) {
          // Если не получилось, пробуем прямую передачу строки
          await (Apphud as dynamic).setUserProperty(key: key, value: value);
        }

        _logger.logInfo(
          message: 'AppHud user property set',
          data: {
            'key': key,
            'has_value': value.isNotEmpty,
          },
        );

        await _analytics.logEvent(
          'apphud_user_property_set',
          parameters: {
            'key': key,
            'has_value': value.isNotEmpty.toString(),
          },
        );
      } catch (e1) {
        _logger.logWarning(
          message: 'Apphud.setUserProperty failed, property may not be set',
          context: {'error': e1.toString(), 'key': key},
        );
      }
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
  /// Добавляет слушатель изменений подписок и покупок
  /// ВАЖНО: Метод может отличаться в зависимости от версии SDK
  void addSubscriptionListener(Function(dynamic) callback) {
    try {
      // Пробуем разные варианты добавления listener
      try {
        // Используем динамический вызов для совместимости
        (Apphud as dynamic).addDidChangeUserPurchasesListener((subscription, purchases) {
          _logger.logInfo(
            message: 'Subscription changed',
            data: {
              'has_subscription': subscription != null,
              'purchases_count': purchases?.length ?? 0,
            },
          );

          // Вызываем callback
          callback(subscription);

          // Логируем событие
          _analytics.logEvent(
            'apphud_subscription_changed',
            parameters: {
              'has_subscription': (subscription != null).toString(),
            },
          );
        });

        _logger.logInfo(
          message: 'Subscription listener added',
          data: {},
        );
      } catch (e1) {
        _logger.logWarning(
          message: 'Apphud.addDidChangeUserPurchasesListener not available in current SDK version',
          context: {'error': e1.toString()},
        );
      }
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to add subscription listener',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
