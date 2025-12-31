import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_service.dart';
import 'logger_service.dart';

/// Вспомогательные классы и функции для работы с рекламой
class AdHelpers {
  final LoggerService _logger = LoggerService();
  final AnalyticsService _analytics = AnalyticsService.instance;

  /// Создает FullScreenContentCallback с общей логикой
  FullScreenContentCallback<T> createFullScreenCallback<T>({
    required String adType,
    required String? adUnitId,
    required VoidCallback onDismissed,
    VoidCallback? onShown,
  }) {
    return FullScreenContentCallback<T>(
      onAdShowedFullScreenContent: (ad) {
        _analytics.logEvent(
          'ad_shown',
          parameters: {
            'ad_type': adType,
            'ad_unit_id': adUnitId,
          },
        );
        onShown?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        (ad as dynamic)?.dispose();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _logger.logError(
          message: '$adType ad failed to show',
          error: error,
          stackTrace: null,
        );
        _analytics.logEvent(
          'ad_failed',
          parameters: {
            'ad_type': adType,
            'ad_unit_id': adUnitId,
            'error_code': error.code.toString(),
            'error_message': error.message,
          },
        );
        (ad as dynamic)?.dispose();
        onDismissed();
      },
      onAdClicked: (ad) {
        _analytics.logEvent(
          'ad_clicked',
          parameters: {
            'ad_type': adType,
            'ad_unit_id': adUnitId,
          },
        );
      },
    );
  }

  /// Логирует успешную загрузку рекламы
  void logAdLoaded(String adType, String? adUnitId) {
    _logger.logInfo(
      message: '$adType ad loaded',
      data: {'ad_unit_id': adUnitId},
    );
    _analytics.logEvent(
      'ad_loaded',
      parameters: {
        'ad_type': adType,
        'ad_unit_id': adUnitId,
      },
    );
  }

  /// Логирует ошибку загрузки рекламы
  void logAdLoadFailed(String adType, String? adUnitId, LoadAdError error) {
    _logger.logError(
      message: '$adType ad failed to load',
      error: error,
      stackTrace: null,
    );
    _analytics.logEvent(
      'ad_failed',
      parameters: {
        'ad_type': adType,
        'ad_unit_id': adUnitId,
        'error_code': error.code.toString(),
        'error_message': error.message,
      },
    );
  }

  /// Логирует награду за просмотр рекламы
  void logAdRewarded(String adType, String? adUnitId, dynamic reward) {
    _analytics.logEvent(
      'ad_rewarded',
      parameters: {
        'ad_type': adType,
        'ad_unit_id': adUnitId,
        'reward_type': reward.type,
        'reward_amount': reward.amount.toString(),
      },
    );
  }
}

