import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:ironsource_mediation/ironsource_mediation.dart'; // Опционально
import 'analytics_service.dart';
import 'logger_service.dart';

/// Типы рекламы
enum AdType { banner, interstitial, rewarded, native }

/// Сервис для управления рекламой
class AdService {
  static AdService? _instance;
  static AdService get instance {
    _instance ??= AdService._();
    return _instance!;
  }

  AdService._();

  final LoggerService _logger = LoggerService();
  final AnalyticsService _analytics = AnalyticsService.instance;

  bool _isInitialized = false;

  // AdMob
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  NativeAd? _nativeAd;
  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdLoading = false;

  // Completers для ожидания загрузки рекламы
  Completer<void>? _rewardedAdLoadCompleter;
  Completer<void>? _rewardedInterstitialAdLoadCompleter;

  // Счетчики для показа interstitial
  int _interstitialCounter = 0;
  int _interstitialShowInterval = 2; // Показывать каждые 2 обработки

  // Ad Unit IDs (будут настроены через init)
  String? _bannerAdUnitId;
  String? _interstitialAdUnitId;
  String? _rewardedAdUnitId;
  String? _rewardedInterstitialAdUnitId;
  String? _nativeAdUnitId;
  String? _appOpenAdUnitId;

  // Callbacks
  Function()? _onRewardedAdCompleted;
  Function()? _onRewardedInterstitialAdCompleted;

  /// Инициализация рекламного сервиса
  Future<void> init({
    String? bannerAdUnitId,
    String? interstitialAdUnitId,
    String? rewardedAdUnitId,
    String? rewardedInterstitialAdUnitId,
    String? nativeAdUnitId,
    String? appOpenAdUnitId,
    int interstitialShowInterval = 2,
  }) async {
    if (_isInitialized) {
      _logger.logWarning(message: 'AdService already initialized', context: {});
      return;
    }

    try {
      _logger.init();

      // Google Mobile Ads не поддерживает веб-платформу
      if (kIsWeb) {
        _logger.logInfo(
          message: 'AdService skipped for web platform (not supported)',
        );
        _isInitialized = true;
        return;
      }

      _bannerAdUnitId = bannerAdUnitId;
      _interstitialAdUnitId = interstitialAdUnitId;
      _rewardedAdUnitId = rewardedAdUnitId;
      _rewardedInterstitialAdUnitId = rewardedInterstitialAdUnitId;
      _nativeAdUnitId = nativeAdUnitId;
      _appOpenAdUnitId = appOpenAdUnitId;
      _interstitialShowInterval = interstitialShowInterval;

      // Инициализация AdMob только для мобильных платформ
      _logger.logInfo(
        message: 'Initializing MobileAds SDK...',
        data: {
          'has_app_open_id': appOpenAdUnitId != null,
          'app_open_id': appOpenAdUnitId,
        },
      );

      final initializationStatus = await MobileAds.instance.initialize();

      _logger.logInfo(
        message: 'MobileAds SDK initialized',
        data: {
          'adapter_count': initializationStatus.adapterStatuses.length,
          'app_open_id': appOpenAdUnitId,
        },
      );

      // Инициализация ironSource (опционально)
      // Раскомментируйте при необходимости интеграции ironSource
      // if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      //   try {
      //     await IronSource.init(
      //       appKey: '', // Будет настроено позже
      //       adUnits: [
      //         ISAdUnit.REWARDED_VIDEO,
      //         ISAdUnit.INTERSTITIAL,
      //       ],
      //     );
      //   } catch (e) {
      //     _logger.logWarning(
      //       message: 'Failed to initialize ironSource (optional)',
      //       context: {'error': e.toString()},
      //     );
      //   }
      // }

      _isInitialized = true;

      _logger.logInfo(
        message: 'AdService initialized successfully',
        data: {
          'has_banner_id': bannerAdUnitId != null,
          'has_interstitial_id': interstitialAdUnitId != null,
          'has_rewarded_id': rewardedAdUnitId != null,
          'has_rewarded_interstitial_id': rewardedInterstitialAdUnitId != null,
          'has_native_id': nativeAdUnitId != null,
          'has_app_open_id': appOpenAdUnitId != null,
        },
      );

      // Загружаем App Open рекламу при инициализации
      // Небольшая задержка, чтобы MobileAds успел полностью инициализироваться
      Future.delayed(const Duration(milliseconds: 500), () {
        if (appOpenAdUnitId != null) {
          _logger.logInfo(
            message: 'Loading App Open ad during initialization',
            data: {'ad_unit_id': appOpenAdUnitId},
          );
          loadAppOpenAd();
        } else {
          _logger.logWarning(
            message: 'App Open ad unit ID is null, skipping load',
          );
        }
      });

      await _analytics.logEvent('ad_service_initialized');
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Failed to initialize AdService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Загрузка и показ баннерной рекламы
  Future<BannerAd?> loadBannerAd({AdSize? adSize, AdRequest? request}) async {
    if (kIsWeb || !_isInitialized || _bannerAdUnitId == null) {
      if (kIsWeb) {
        _logger.logInfo(message: 'Banner ad skipped for web platform');
      } else {
        _logger.logWarning(
          message: 'AdService not initialized or banner ad unit ID not set',
          context: {},
        );
      }
      return null;
    }

    try {
      // Удаляем предыдущий баннер, если есть
      _bannerAd?.dispose();

      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId!,
        size: adSize ?? AdSize.banner,
        request: request ?? const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _logger.logInfo(
              message: 'Banner ad loaded',
              data: {'ad_unit_id': _bannerAdUnitId},
            );
            _analytics.logEvent(
              'ad_loaded',
              parameters: {'ad_type': 'banner', 'ad_unit_id': _bannerAdUnitId},
            );
          },
          onAdFailedToLoad: (ad, error) {
            _logger.logError(
              message: 'Banner ad failed to load',
              error: error,
              stackTrace: null,
            );
            _analytics.logEvent(
              'ad_failed',
              parameters: {
                'ad_type': 'banner',
                'ad_unit_id': _bannerAdUnitId,
                'error_code': error.code.toString(),
                'error_message': error.message,
              },
            );
            ad.dispose();
          },
          onAdOpened: (ad) {
            _analytics.logEvent(
              'ad_clicked',
              parameters: {'ad_type': 'banner', 'ad_unit_id': _bannerAdUnitId},
            );
          },
          onAdImpression: (ad) {
            _analytics.logEvent(
              'ad_shown',
              parameters: {'ad_type': 'banner', 'ad_unit_id': _bannerAdUnitId},
            );
          },
        ),
      );

      await _bannerAd!.load();
      return _bannerAd;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error loading banner ad',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Загрузка interstitial рекламы
  Future<void> loadInterstitialAd() async {
    if (kIsWeb || !_isInitialized || _interstitialAdUnitId == null) {
      return;
    }

    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId!,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _logger.logInfo(
              message: 'Interstitial ad loaded',
              data: {'ad_unit_id': _interstitialAdUnitId},
            );
            _analytics.logEvent(
              'ad_loaded',
              parameters: {
                'ad_type': 'interstitial',
                'ad_unit_id': _interstitialAdUnitId,
              },
            );

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                _analytics.logEvent(
                  'ad_shown',
                  parameters: {
                    'ad_type': 'interstitial',
                    'ad_unit_id': _interstitialAdUnitId,
                  },
                );
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
                // Загружаем следующий interstitial
                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _logger.logError(
                  message: 'Interstitial ad failed to show',
                  error: error,
                  stackTrace: null,
                );
                _analytics.logEvent(
                  'ad_failed',
                  parameters: {
                    'ad_type': 'interstitial',
                    'ad_unit_id': _interstitialAdUnitId,
                    'error_code': error.code.toString(),
                    'error_message': error.message,
                  },
                );
                ad.dispose();
                _interstitialAd = null;
                loadInterstitialAd();
              },
              onAdClicked: (ad) {
                _analytics.logEvent(
                  'ad_clicked',
                  parameters: {
                    'ad_type': 'interstitial',
                    'ad_unit_id': _interstitialAdUnitId,
                  },
                );
              },
            );
          },
          onAdFailedToLoad: (error) {
            _logger.logError(
              message: 'Interstitial ad failed to load',
              error: error,
              stackTrace: null,
            );
            _analytics.logEvent(
              'ad_failed',
              parameters: {
                'ad_type': 'interstitial',
                'ad_unit_id': _interstitialAdUnitId,
                'error_code': error.code.toString(),
                'error_message': error.message,
              },
            );
            _interstitialAd = null;
          },
        ),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error loading interstitial ad',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Показ interstitial рекламы (если нужно)
  Future<void> showInterstitialAdIfNeeded() async {
    if (_interstitialAd == null) {
      return;
    }

    _interstitialCounter++;
    if (_interstitialCounter >= _interstitialShowInterval) {
      _interstitialCounter = 0;
      await showInterstitialAd();
    }
  }

  /// Показ interstitial рекламы
  Future<void> showInterstitialAd() async {
    if (kIsWeb) {
      return;
    }

    if (_interstitialAd == null) {
      await loadInterstitialAd();
      return;
    }

    try {
      await _interstitialAd!.show();
    } catch (e) {
      _logger.logError(
        message: 'Error showing interstitial ad',
        error: e,
        stackTrace: null,
      );
    }
  }

  /// Загрузка rewarded рекламы
  Future<void> loadRewardedAd({Function()? onRewarded}) async {
    if (kIsWeb || !_isInitialized || _rewardedAdUnitId == null) {
      return;
    }

    _onRewardedAdCompleted = onRewarded;

    // Если реклама уже загружается, ждем завершения
    if (_rewardedAdLoadCompleter != null) {
      return _rewardedAdLoadCompleter!.future;
    }

    // Если реклама уже загружена, не загружаем снова
    if (_rewardedAd != null) {
      return;
    }

    _rewardedAdLoadCompleter = Completer<void>();

    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId!,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _logger.logInfo(
              message: 'Rewarded ad loaded',
              data: {'ad_unit_id': _rewardedAdUnitId},
            );
            _analytics.logEvent(
              'ad_loaded',
              parameters: {
                'ad_type': 'rewarded',
                'ad_unit_id': _rewardedAdUnitId,
              },
            );

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                _analytics.logEvent(
                  'ad_shown',
                  parameters: {
                    'ad_type': 'rewarded',
                    'ad_unit_id': _rewardedAdUnitId,
                  },
                );
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _rewardedAd = null;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _logger.logError(
                  message: 'Rewarded ad failed to show',
                  error: error,
                  stackTrace: null,
                );
                _analytics.logEvent(
                  'ad_failed',
                  parameters: {
                    'ad_type': 'rewarded',
                    'ad_unit_id': _rewardedAdUnitId,
                    'error_code': error.code.toString(),
                    'error_message': error.message,
                  },
                );
                ad.dispose();
                _rewardedAd = null;
              },
              onAdClicked: (ad) {
                _analytics.logEvent(
                  'ad_clicked',
                  parameters: {
                    'ad_type': 'rewarded',
                    'ad_unit_id': _rewardedAdUnitId,
                  },
                );
              },
            );
            // Завершаем Completer при успешной загрузке
            if (!_rewardedAdLoadCompleter!.isCompleted) {
              _rewardedAdLoadCompleter!.complete();
            }
            _rewardedAdLoadCompleter = null;
          },
          onAdFailedToLoad: (error) {
            _logger.logError(
              message: 'Rewarded ad failed to load',
              error: error,
              stackTrace: null,
            );
            _analytics.logEvent(
              'ad_failed',
              parameters: {
                'ad_type': 'rewarded',
                'ad_unit_id': _rewardedAdUnitId,
                'error_code': error.code.toString(),
                'error_message': error.message,
              },
            );
            _rewardedAd = null;
            // Завершаем Completer даже при ошибке
            if (_rewardedAdLoadCompleter != null &&
                !_rewardedAdLoadCompleter!.isCompleted) {
              _rewardedAdLoadCompleter!.complete();
            }
            _rewardedAdLoadCompleter = null;
          },
        ),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error loading rewarded ad',
        error: e,
        stackTrace: stackTrace,
      );
      // Завершаем Completer при исключении
      if (_rewardedAdLoadCompleter != null &&
          !_rewardedAdLoadCompleter!.isCompleted) {
        _rewardedAdLoadCompleter!.complete();
      }
      _rewardedAdLoadCompleter = null;
    }
  }

  /// Показ rewarded рекламы
  Future<void> showRewardedAd({Function()? onRewarded}) async {
    if (kIsWeb) {
      return;
    }

    // Сохраняем callback, если передан
    if (onRewarded != null) {
      _onRewardedAdCompleted = onRewarded;
    }

    // Если реклама не загружена, загружаем и ждем
    if (_rewardedAd == null) {
      await loadRewardedAd(onRewarded: _onRewardedAdCompleted);

      // Ждем загрузки с таймаутом (до 10 секунд)
      int attempts = 0;
      while (_rewardedAd == null && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      // Если реклама все еще не загружена, выходим
      if (_rewardedAd == null) {
        _logger.logWarning(message: 'Rewarded ad not loaded after waiting');
        return;
      }
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          _analytics.logEvent(
            'ad_rewarded',
            parameters: {
              'ad_type': 'rewarded',
              'ad_unit_id': _rewardedAdUnitId,
              'reward_type': reward.type,
              'reward_amount': reward.amount.toString(),
            },
          );

          if (_onRewardedAdCompleted != null) {
            _onRewardedAdCompleted!();
          }
        },
      );
    } catch (e) {
      _logger.logError(
        message: 'Error showing rewarded ad',
        error: e,
        stackTrace: null,
      );
    }
  }

  /// Загрузка Rewarded Interstitial рекламы
  Future<void> loadRewardedInterstitialAd({Function()? onRewarded}) async {
    if (kIsWeb || !_isInitialized || _rewardedInterstitialAdUnitId == null) {
      return;
    }

    _onRewardedInterstitialAdCompleted = onRewarded;

    // Если реклама уже загружается, ждем завершения
    if (_rewardedInterstitialAdLoadCompleter != null) {
      return _rewardedInterstitialAdLoadCompleter!.future;
    }

    // Если реклама уже загружена, не загружаем снова
    if (_rewardedInterstitialAd != null) {
      return;
    }

    _rewardedInterstitialAdLoadCompleter = Completer<void>();

    try {
      await RewardedInterstitialAd.load(
        adUnitId: _rewardedInterstitialAdUnitId!,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedInterstitialAd = ad;
            _logger.logInfo(
              message: 'Rewarded Interstitial ad loaded',
              data: {'ad_unit_id': _rewardedInterstitialAdUnitId},
            );
            _analytics.logEvent(
              'ad_loaded',
              parameters: {
                'ad_type': 'rewarded_interstitial',
                'ad_unit_id': _rewardedInterstitialAdUnitId,
              },
            );

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                _analytics.logEvent(
                  'ad_shown',
                  parameters: {
                    'ad_type': 'rewarded_interstitial',
                    'ad_unit_id': _rewardedInterstitialAdUnitId,
                  },
                );
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _rewardedInterstitialAd = null;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _logger.logError(
                  message: 'Rewarded Interstitial ad failed to show',
                  error: error,
                  stackTrace: null,
                );
                _analytics.logEvent(
                  'ad_failed',
                  parameters: {
                    'ad_type': 'rewarded_interstitial',
                    'ad_unit_id': _rewardedInterstitialAdUnitId,
                    'error_code': error.code.toString(),
                    'error_message': error.message,
                  },
                );
                ad.dispose();
                _rewardedInterstitialAd = null;
              },
              onAdClicked: (ad) {
                _analytics.logEvent(
                  'ad_clicked',
                  parameters: {
                    'ad_type': 'rewarded_interstitial',
                    'ad_unit_id': _rewardedInterstitialAdUnitId,
                  },
                );
              },
            );
            // Завершаем Completer при успешной загрузке
            if (!_rewardedInterstitialAdLoadCompleter!.isCompleted) {
              _rewardedInterstitialAdLoadCompleter!.complete();
            }
            _rewardedInterstitialAdLoadCompleter = null;
          },
          onAdFailedToLoad: (error) {
            _logger.logError(
              message: 'Rewarded Interstitial ad failed to load',
              error: error,
              stackTrace: null,
            );
            _analytics.logEvent(
              'ad_failed',
              parameters: {
                'ad_type': 'rewarded_interstitial',
                'ad_unit_id': _rewardedInterstitialAdUnitId,
                'error_code': error.code.toString(),
                'error_message': error.message,
              },
            );
            _rewardedInterstitialAd = null;
            // Завершаем Completer даже при ошибке
            if (_rewardedInterstitialAdLoadCompleter != null &&
                !_rewardedInterstitialAdLoadCompleter!.isCompleted) {
              _rewardedInterstitialAdLoadCompleter!.complete();
            }
            _rewardedInterstitialAdLoadCompleter = null;
          },
        ),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error loading rewarded interstitial ad',
        error: e,
        stackTrace: stackTrace,
      );
      // Завершаем Completer при исключении
      if (_rewardedInterstitialAdLoadCompleter != null &&
          !_rewardedInterstitialAdLoadCompleter!.isCompleted) {
        _rewardedInterstitialAdLoadCompleter!.complete();
      }
      _rewardedInterstitialAdLoadCompleter = null;
    }
  }

  /// Показ Rewarded Interstitial рекламы
  Future<void> showRewardedInterstitialAd({Function()? onRewarded}) async {
    if (kIsWeb) {
      return;
    }

    // Сохраняем callback, если передан
    if (onRewarded != null) {
      _onRewardedInterstitialAdCompleted = onRewarded;
    }

    // Если реклама не загружена, загружаем и ждем
    if (_rewardedInterstitialAd == null) {
      await loadRewardedInterstitialAd(
        onRewarded: _onRewardedInterstitialAdCompleted,
      );

      // Ждем загрузки с таймаутом (до 10 секунд)
      int attempts = 0;
      while (_rewardedInterstitialAd == null && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      // Если реклама все еще не загружена, выходим
      if (_rewardedInterstitialAd == null) {
        _logger.logWarning(
          message: 'Rewarded Interstitial ad not loaded after waiting',
        );
        return;
      }
    }

    try {
      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          _analytics.logEvent(
            'ad_rewarded',
            parameters: {
              'ad_type': 'rewarded_interstitial',
              'ad_unit_id': _rewardedInterstitialAdUnitId,
              'reward_type': reward.type,
              'reward_amount': reward.amount.toString(),
            },
          );

          if (_onRewardedInterstitialAdCompleted != null) {
            _onRewardedInterstitialAdCompleted!();
          }
        },
      );
    } catch (e) {
      _logger.logError(
        message: 'Error showing rewarded interstitial ad',
        error: e,
        stackTrace: null,
      );
    }
  }

  /// Загрузка Native Advanced рекламы
  Future<NativeAd?> loadNativeAd({
    required NativeAdController controller,
    AdRequest? request,
  }) async {
    if (kIsWeb || !_isInitialized || _nativeAdUnitId == null) {
      return null;
    }

    try {
      // Удаляем предыдущую нативную рекламу, если есть
      _nativeAd?.dispose();

      _nativeAd = NativeAd(
        adUnitId: _nativeAdUnitId!,
        request: request ?? const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: Colors.white,
          cornerRadius: 10.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.blue,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.grey,
            style: NativeTemplateFontStyle.normal,
            size: 14.0,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.grey,
            style: NativeTemplateFontStyle.normal,
            size: 12.0,
          ),
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            _nativeAd = ad as NativeAd;
            _logger.logInfo(
              message: 'Native ad loaded',
              data: {'ad_unit_id': _nativeAdUnitId},
            );
            _analytics.logEvent(
              'ad_loaded',
              parameters: {'ad_type': 'native', 'ad_unit_id': _nativeAdUnitId},
            );
            controller.setNativeAd(_nativeAd);
          },
          onAdFailedToLoad: (ad, error) {
            _logger.logError(
              message: 'Native ad failed to load',
              error: error,
              stackTrace: null,
            );
            _analytics.logEvent(
              'ad_failed',
              parameters: {
                'ad_type': 'native',
                'ad_unit_id': _nativeAdUnitId,
                'error_code': error.code.toString(),
                'error_message': error.message,
              },
            );
            ad.dispose();
            _nativeAd = null;
            controller.setNativeAd(null);
          },
          onAdClicked: (ad) {
            _analytics.logEvent(
              'ad_clicked',
              parameters: {'ad_type': 'native', 'ad_unit_id': _nativeAdUnitId},
            );
          },
          onAdImpression: (ad) {
            _analytics.logEvent(
              'ad_shown',
              parameters: {'ad_type': 'native', 'ad_unit_id': _nativeAdUnitId},
            );
          },
        ),
      );

      await _nativeAd!.load();
      return _nativeAd;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error loading native ad',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Получить текущую Native рекламу
  NativeAd? get nativeAd => _nativeAd;

  /// Загрузка App Open рекламы
  Future<void> loadAppOpenAd() async {
    _logger.init();
    _logger.logInfo(
      message: 'loadAppOpenAd called',
      data: {
        'web': kIsWeb,
        'initialized': _isInitialized,
        'ad_unit_id': _appOpenAdUnitId,
        'already_loading': _isAppOpenAdLoading,
        'already_loaded': _appOpenAd != null,
      },
    );

    if (kIsWeb || !_isInitialized || _appOpenAdUnitId == null) {
      _logger.logWarning(
        message:
            'Cannot load App Open ad: web=$kIsWeb, initialized=$_isInitialized, id=$_appOpenAdUnitId',
      );
      return;
    }

    // Если уже загружается или уже загружена, не загружаем повторно
    if (_isAppOpenAdLoading || _appOpenAd != null) {
      _logger.logInfo(message: 'App Open ad already loading or loaded');
      return;
    }

    _isAppOpenAdLoading = true;
    try {
      _logger.logInfo(
        message: 'Attempting to load App Open ad',
        data: {'ad_unit_id': _appOpenAdUnitId, 'platform': 'android'},
      );

      await AppOpenAd.load(
        adUnitId: _appOpenAdUnitId!,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isAppOpenAdLoading = false;
            _logger.logInfo(
              message: 'App Open ad loaded successfully',
              data: {'ad_unit_id': _appOpenAdUnitId},
            );
            _analytics.logEvent(
              'ad_loaded',
              parameters: {
                'ad_type': 'app_open',
                'ad_unit_id': _appOpenAdUnitId,
              },
            );

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                _analytics.logEvent(
                  'ad_shown',
                  parameters: {
                    'ad_type': 'app_open',
                    'ad_unit_id': _appOpenAdUnitId,
                  },
                );
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _appOpenAd = null;
                // Загружаем следующую App Open рекламу
                loadAppOpenAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _logger.logError(
                  message: 'App Open ad failed to show',
                  error: error,
                  stackTrace: null,
                );
                _analytics.logEvent(
                  'ad_failed',
                  parameters: {
                    'ad_type': 'app_open',
                    'ad_unit_id': _appOpenAdUnitId,
                    'error_code': error.code.toString(),
                    'error_message': error.message,
                  },
                );
                ad.dispose();
                _appOpenAd = null;
                loadAppOpenAd();
              },
              onAdClicked: (ad) {
                _analytics.logEvent(
                  'ad_clicked',
                  parameters: {
                    'ad_type': 'app_open',
                    'ad_unit_id': _appOpenAdUnitId,
                  },
                );
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isAppOpenAdLoading = false;
            _logger.logError(
              message:
                  'App Open ad failed to load: ${error.message} (code: ${error.code})',
              error: error,
              stackTrace: null,
            );
            _logger.logInfo(
              message: 'App Open ad unit ID: $_appOpenAdUnitId',
              data: {
                'error_code': error.code.toString(),
                'error_message': error.message,
                'note': error.code == 3
                    ? 'Ошибка code 3 означает, что Ad Unit ID не соответствует формату App Open. '
                          'Создайте реальный App Open ad unit в AdMob консоли (https://apps.admob.com/) '
                          'и замените тестовый ID на реальный.'
                    : 'Проверьте настройки AdMob и Ad Unit ID',
              },
            );
            _analytics.logEvent(
              'ad_failed',
              parameters: {
                'ad_type': 'app_open',
                'ad_unit_id': _appOpenAdUnitId,
                'error_code': error.code.toString(),
                'error_message': error.message,
              },
            );
            _appOpenAd = null;
          },
        ),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error loading app open ad',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Показ App Open рекламы
  /// Возвращает true, если реклама была успешно показана, false в противном случае
  Future<bool> showAppOpenAd() async {
    if (kIsWeb) {
      _logger.logInfo(message: 'App Open ad skipped for web platform');
      return false;
    }

    if (!_isInitialized) {
      _logger.logWarning(
        message: 'Cannot show App Open ad: AdService not initialized',
      );
      return false;
    }

    // Если реклама не загружена, пытаемся загрузить и подождать
    if (_appOpenAd == null) {
      _logger.logInfo(message: 'App Open ad not loaded, loading now...');
      await loadAppOpenAd();

      // Ждем загрузки (максимум 5 секунд)
      int attempts = 0;
      while (_appOpenAd == null && _isAppOpenAdLoading && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (_appOpenAd == null) {
        _logger.logWarning(message: 'App Open ad failed to load in time');
        _logger.logInfo(
          message: 'App Open ad loading details',
          data: {
            'ad_unit_id': _appOpenAdUnitId,
            'was_loading': _isAppOpenAdLoading,
            'attempts': attempts,
          },
        );
        return false;
      }
    }

    try {
      _logger.logInfo(message: 'Showing App Open ad');
      await _appOpenAd!.show();
      return true;
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error showing app open ad',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Очистка ресурсов
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _nativeAd?.dispose();
    _appOpenAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _rewardedInterstitialAd = null;
    _nativeAd = null;
    _appOpenAd = null;
  }
}

/// Контроллер для Native рекламы
class NativeAdController extends ChangeNotifier {
  NativeAd? _nativeAd;

  NativeAd? get nativeAd => _nativeAd;

  void setNativeAd(NativeAd? ad) {
    _nativeAd = ad;
    notifyListeners();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }
}
