import 'package:flutter/foundation.dart' show kIsWeb;
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

  // Счетчики для показа interstitial
  int _interstitialCounter = 0;
  int _interstitialShowInterval = 2; // Показывать каждые 2 обработки

  // Ad Unit IDs (будут настроены через init)
  String? _bannerAdUnitId;
  String? _interstitialAdUnitId;
  String? _rewardedAdUnitId;

  // Callbacks
  Function()? _onRewardedAdCompleted;

  /// Инициализация рекламного сервиса
  Future<void> init({
    String? bannerAdUnitId,
    String? interstitialAdUnitId,
    String? rewardedAdUnitId,
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
      _interstitialShowInterval = interstitialShowInterval;

      // Инициализация AdMob только для мобильных платформ
      await MobileAds.instance.initialize();

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
        },
      );

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
          },
        ),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        message: 'Error loading rewarded ad',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Показ rewarded рекламы
  Future<void> showRewardedAd() async {
    if (kIsWeb) {
      return;
    }

    if (_rewardedAd == null) {
      await loadRewardedAd();
      return;
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

  /// Очистка ресурсов
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
  }
}
