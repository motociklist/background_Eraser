# 📋 Инструкция по настройке аналитики и рекламы

## 🔧 Настройка перед использованием

### 1. Получение ключей и ID

#### AppMetrica
1. Зарегистрируйтесь на [AppMetrica](https://appmetrica.yandex.ru/)
2. Создайте новое приложение
3. Скопируйте API ключ
4. Вставьте в `lib/config/analytics_config.dart`:
   ```dart
   static const String appMetricaApiKey = 'ВАШ_КЛЮЧ';
   ```

#### AppsFlyer
1. Зарегистрируйтесь на [AppsFlyer](https://www.appsflyer.com/)
2. Создайте новое приложение
3. Скопируйте Dev Key и App ID (iOS)
4. Вставьте в `lib/config/analytics_config.dart`:
   ```dart
   static const String appsFlyerDevKey = 'ВАШ_DEV_KEY';
   static const String appsFlyerAppId = 'ВАШ_APP_ID';
   ```

#### Firebase Analytics
1. Создайте проект в [Firebase Console](https://console.firebase.google.com/)
2. Добавьте Android приложение:
   - Скачайте `google-services.json`
   - Поместите в `android/app/google-services.json`
3. Добавьте iOS приложение:
   - Скачайте `GoogleService-Info.plist`
   - Поместите в `ios/Runner/GoogleService-Info.plist`
4. Добавьте плагин в `android/build.gradle.kts`:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```
5. Примените плагин в `android/app/build.gradle.kts`:
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```

#### AdMob
1. Зарегистрируйтесь на [AdMob](https://apps.admob.com/)
2. Создайте приложение для Android и iOS
3. Создайте Ad Units:
   - Banner Ad Unit
   - Interstitial Ad Unit
   - Rewarded Ad Unit
4. Скопируйте Ad Unit IDs
5. Вставьте в `lib/config/analytics_config.dart`:
   ```dart
   // Android
   static const String androidBannerAdUnitId = 'ВАШ_BANNER_ID';
   static const String androidInterstitialAdUnitId = 'ВАШ_INTERSTITIAL_ID';
   static const String androidRewardedAdUnitId = 'ВАШ_REWARDED_ID';

   // iOS
   static const String iosBannerAdUnitId = 'ВАШ_BANNER_ID';
   static const String iosInterstitialAdUnitId = 'ВАШ_INTERSTITIAL_ID';
   static const String iosRewardedAdUnitId = 'ВАШ_REWARDED_ID';
   ```
6. Обновите AdMob App ID в `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-XXXXXXXX~XXXXXXXX"/>
   ```
7. Обновите AdMob App ID в `ios/Runner/Info.plist`:
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-XXXXXXXX~XXXXXXXX</string>
   ```

#### ironSource (опционально)
1. Зарегистрируйтесь на [ironSource](https://www.ironsrc.com/)
2. Создайте новое приложение
3. Скопируйте App Key
4. Вставьте в `lib/config/analytics_config.dart`:
   ```dart
   static const String ironSourceAppKey = 'ВАШ_APP_KEY';
   ```

### 2. Установка зависимостей

```bash
flutter pub get
```

### 3. Настройка Android

#### Обновите `android/build.gradle.kts`:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

#### Обновите `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

### 4. Настройка iOS

1. Установите CocoaPods зависимости:
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. Убедитесь, что `GoogleService-Info.plist` добавлен в проект Xcode

### 5. Тестирование

#### Test Ad Unit IDs (для разработки)
AdMob предоставляет тестовые Ad Unit IDs, которые уже настроены в конфиге:
- Android Banner: `ca-app-pub-3940256099942544/6300978111`
- Android Interstitial: `ca-app-pub-3940256099942544/1033173712`
- Android Rewarded: `ca-app-pub-3940256099942544/5224354917`
- iOS Banner: `ca-app-pub-3940256099942544/2934735716`
- iOS Interstitial: `ca-app-pub-3940256099942544/4411468910`
- iOS Rewarded: `ca-app-pub-3940256099942544/1712485313`

⚠️ **Важно**: Перед релизом замените test IDs на реальные!

### 6. Проверка работы

1. Запустите приложение:
   ```bash
   flutter run
   ```

2. Проверьте логи:
   - Аналитика должна инициализироваться без ошибок
   - Реклама должна загружаться (в тестовом режиме)

3. Проверьте события в дашбордах:
   - AppMetrica: https://appmetrica.yandex.ru/
   - AppsFlyer: https://hq1.appsflyer.com/
   - Firebase: https://console.firebase.google.com/

## 📊 Отслеживаемые события

Все события автоматически отправляются во все настроенные системы аналитики:

- `app_launched` - Запуск приложения
- `screen_view` - Просмотр экрана
- `image_picked` - Выбор изображения
- `background_removal_started` - Начало удаления фона
- `background_removal_completed` - Успешное удаление фона
- `background_removal_failed` - Ошибка удаления фона
- `background_blur_started` - Начало размытия фона
- `background_blur_completed` - Успешное размытие фона
- `background_blur_failed` - Ошибка размытия фона
- `image_saved` - Изображение сохранено
- `image_save_failed` - Ошибка сохранения
- `provider_changed` - Изменен провайдер
- `blur_radius_changed` - Изменен радиус размытия
- `ad_loaded` - Реклама загружена
- `ad_shown` - Реклама показана
- `ad_clicked` - Клик по рекламе
- `ad_failed` - Ошибка загрузки рекламы
- `ad_rewarded` - Награда получена

## ⚠️ Важные замечания

1. **Приватность**: API ключи пользователей НЕ отправляются в аналитику
2. **GDPR/CCPA**: Убедитесь, что у вас есть согласие пользователей на обработку данных
3. **Тестирование**: Используйте test ad unit IDs во время разработки
4. **Релиз**: Замените все test IDs на реальные перед публикацией в магазины

## 🔗 Полезные ссылки

- [AppMetrica Documentation](https://appmetrica.yandex.ru/docs/mobile-sdk-dg/concepts/about.html)
- [AppsFlyer Documentation](https://dev.appsflyer.com/hc/docs/integrate-sdk-reference-appsflyerflutterplugin)
- [Firebase Analytics Documentation](https://firebase.google.com/docs/analytics)
- [AdMob Documentation](https://developers.google.com/admob/flutter)
- [ironSource Documentation](https://developers.ironsrc.com/ironsource-mobile/flutter/)

