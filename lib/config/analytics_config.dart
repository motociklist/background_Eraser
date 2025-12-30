/// Конфигурация для аналитики и рекламы
///
/// ВАЖНО: Замените значения на реальные ключи перед релизом!
/// Для тестирования можно использовать test ad unit IDs от AdMob
class AnalyticsConfig {
  // AppMetrica API Key
  // Получить можно на https://appmetrica.yandex.ru/
  static const String appMetricaApiKey = 'YOUR_APPMETRICA_API_KEY';

  // AppsFlyer
  // Получить можно на https://www.appsflyer.com/
  static const String appsFlyerDevKey = 'GAgckFyN4yETigBtP4qtRG';
  static const String appsFlyerAppId = '6749377146'; // iOS App ID

  // Firebase Analytics
  // Настраивается через google-services.json (Android) и GoogleService-Info.plist (iOS)
  static const bool enableFirebase = true;

  // AdMob Ad Unit IDs (тестовые ключи)
  // App ID: ca-app-pub-3940256099942544~1458002511

  // Android Ad Unit IDs (тестовые)
  static const String androidBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static const String androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
  static const String androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';
  static const String androidRewardedInterstitialAdUnitId = 'ca-app-pub-3940256099942544/6978759866';
  static const String androidNativeAdUnitId = 'ca-app-pub-3940256099942544/3986624511';
  static const String androidAppOpenAdUnitId = 'ca-app-pub-3940256099942544/5662855259';

  // iOS Ad Unit IDs (тестовые)
  static const String iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
  static const String iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';
  static const String iosRewardedInterstitialAdUnitId = 'ca-app-pub-3940256099942544/6978759866';
  static const String iosNativeAdUnitId = 'ca-app-pub-3940256099942544/3986624511';
  static const String iosAppOpenAdUnitId = 'ca-app-pub-3940256099942544/5662855259';

  // ironSource App Key (опционально)
  // Получить можно на https://www.ironsrc.com/
  static const String ironSourceAppKey = 'YOUR_IRONSOURCE_APP_KEY';

  // Интервал показа interstitial рекламы (каждые N обработок)
  static const int interstitialShowInterval = 2;
}

