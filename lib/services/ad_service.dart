import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_service.dart';
import 'logger_service.dart';
import 'ad_helpers.dart';

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
  final AdHelpers _helpers = AdHelpers();

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
  int _interstitialShowInterval = 2;

  // Ad Unit IDs
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

  /// Проверка доступности рекламы для платформы
  bool _isAdAvailable() => !kIsWeb && _isInitialized;

  /// Загрузка и показ баннерной рекламы
  Future<BannerAd?> loadBannerAd({AdSize? adSize, AdRequest? request}) async {
    if (!_isAdAvailable() || _bannerAdUnitId == null) {
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
      _bannerAd?.dispose();

      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId!,
        size: adSize ?? AdSize.banner,
        request: request ?? const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _helpers.logAdLoaded('banner', _bannerAdUnitId);
          },
          onAdFailedToLoad: (ad, error) {
            _helpers.logAdLoadFailed('banner', _bannerAdUnitId, error);
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
    if (!_isAdAvailable() || _interstitialAdUnitId == null) {
      return;
    }

    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId!,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _helpers.logAdLoaded('interstitial', _interstitialAdUnitId);

            ad.fullScreenContentCallback = _helpers
                .createFullScreenCallback<InterstitialAd>(
                  adType: 'interstitial',
                  adUnitId: _interstitialAdUnitId,
                  onDismissed: () {
                    _interstitialAd = null;
                    loadInterstitialAd(); // Загружаем следующий
                  },
                );
          },
          onAdFailedToLoad: (error) {
            _helpers.logAdLoadFailed(
              'interstitial',
              _interstitialAdUnitId,
              error,
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
    if (!_isAdAvailable() || _rewardedAdUnitId == null) {
      return;
    }

    _onRewardedAdCompleted = onRewarded;

    if (_rewardedAdLoadCompleter != null) {
      return _rewardedAdLoadCompleter!.future;
    }

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
            _helpers.logAdLoaded('rewarded', _rewardedAdUnitId);

            ad.fullScreenContentCallback = _helpers
                .createFullScreenCallback<RewardedAd>(
                  adType: 'rewarded',
                  adUnitId: _rewardedAdUnitId,
                  onDismissed: () {
                    _rewardedAd = null;
                  },
                );

            _completeCompleter(_rewardedAdLoadCompleter);
            _rewardedAdLoadCompleter = null;
          },
          onAdFailedToLoad: (error) {
            _helpers.logAdLoadFailed('rewarded', _rewardedAdUnitId, error);
            _rewardedAd = null;
            _completeCompleter(_rewardedAdLoadCompleter);
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
      _completeCompleter(_rewardedAdLoadCompleter);
      _rewardedAdLoadCompleter = null;
    }
  }

  /// Показ rewarded рекламы
  Future<void> showRewardedAd({Function()? onRewarded}) async {
    if (kIsWeb) {
      return;
    }

    if (onRewarded != null) {
      _onRewardedAdCompleted = onRewarded;
    }

    if (_rewardedAd == null) {
      await loadRewardedAd(onRewarded: _onRewardedAdCompleted);
      await _waitForAd(
        () => _rewardedAd != null,
        'Rewarded ad not loaded after waiting',
      );
      if (_rewardedAd == null) {
        return;
      }
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          _helpers.logAdRewarded('rewarded', _rewardedAdUnitId, reward);
          _onRewardedAdCompleted?.call();
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
    if (!_isAdAvailable() || _rewardedInterstitialAdUnitId == null) {
      return;
    }

    _onRewardedInterstitialAdCompleted = onRewarded;

    if (_rewardedInterstitialAdLoadCompleter != null) {
      return _rewardedInterstitialAdLoadCompleter!.future;
    }

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
            _helpers.logAdLoaded(
              'rewarded_interstitial',
              _rewardedInterstitialAdUnitId,
            );

            ad.fullScreenContentCallback = _helpers
                .createFullScreenCallback<RewardedInterstitialAd>(
                  adType: 'rewarded_interstitial',
                  adUnitId: _rewardedInterstitialAdUnitId,
                  onDismissed: () {
                    _rewardedInterstitialAd = null;
                  },
                );

            _completeCompleter(_rewardedInterstitialAdLoadCompleter);
            _rewardedInterstitialAdLoadCompleter = null;
          },
          onAdFailedToLoad: (error) {
            _helpers.logAdLoadFailed(
              'rewarded_interstitial',
              _rewardedInterstitialAdUnitId,
              error,
            );
            _rewardedInterstitialAd = null;
            _completeCompleter(_rewardedInterstitialAdLoadCompleter);
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
      _completeCompleter(_rewardedInterstitialAdLoadCompleter);
      _rewardedInterstitialAdLoadCompleter = null;
    }
  }

  /// Показ Rewarded Interstitial рекламы
  Future<void> showRewardedInterstitialAd({Function()? onRewarded}) async {
    if (kIsWeb) {
      return;
    }

    if (onRewarded != null) {
      _onRewardedInterstitialAdCompleted = onRewarded;
    }

    if (_rewardedInterstitialAd == null) {
      await loadRewardedInterstitialAd(
        onRewarded: _onRewardedInterstitialAdCompleted,
      );
      await _waitForAd(
        () => _rewardedInterstitialAd != null,
        'Rewarded Interstitial ad not loaded after waiting',
      );
      if (_rewardedInterstitialAd == null) {
        return;
      }
    }

    try {
      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          _helpers.logAdRewarded(
            'rewarded_interstitial',
            _rewardedInterstitialAdUnitId,
            reward,
          );
          _onRewardedInterstitialAdCompleted?.call();
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
    if (!_isAdAvailable() || _nativeAdUnitId == null) {
      return null;
    }

    try {
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
            _helpers.logAdLoaded('native', _nativeAdUnitId);
            controller.setNativeAd(_nativeAd);
          },
          onAdFailedToLoad: (ad, error) {
            _helpers.logAdLoadFailed('native', _nativeAdUnitId, error);
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
    if (!_isAdAvailable() || _appOpenAdUnitId == null) {
      return;
    }

    if (_isAppOpenAdLoading || _appOpenAd != null) {
      return;
    }

    _isAppOpenAdLoading = true;
    try {
      await AppOpenAd.load(
        adUnitId: _appOpenAdUnitId!,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isAppOpenAdLoading = false;
            _helpers.logAdLoaded('app_open', _appOpenAdUnitId);

            ad.fullScreenContentCallback = _helpers
                .createFullScreenCallback<AppOpenAd>(
                  adType: 'app_open',
                  adUnitId: _appOpenAdUnitId,
                  onDismissed: () {
                    _appOpenAd = null;
                    loadAppOpenAd(); // Загружаем следующую
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
            _helpers.logAdLoadFailed('app_open', _appOpenAdUnitId, error);
            _appOpenAd = null;
          },
        ),
      );
    } catch (e, stackTrace) {
      _isAppOpenAdLoading = false;
      _logger.logError(
        message: 'Error loading app open ad',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Показ App Open рекламы
  Future<bool> showAppOpenAd() async {
    if (kIsWeb || !_isInitialized) {
      return false;
    }

    if (_appOpenAd == null) {
      await loadAppOpenAd();
      int attempts = 0;
      while (_appOpenAd == null && _isAppOpenAdLoading && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (_appOpenAd == null) {
        return false;
      }
    }

    try {
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

  /// Вспомогательный метод для ожидания загрузки рекламы
  Future<void> _waitForAd(bool Function() check, String timeoutMessage) async {
    int attempts = 0;
    while (!check() && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
    if (!check()) {
      _logger.logWarning(message: timeoutMessage);
    }
  }

  /// Вспомогательный метод для завершения Completer
  void _completeCompleter(Completer<void>? completer) {
    if (completer != null && !completer.isCompleted) {
      completer.complete();
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
