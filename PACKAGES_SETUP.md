# 📦 Установка дополнительных пакетов

## ⚠️ Важно

Некоторые пакеты для аналитики требуют ручной установки, так как они могут быть недоступны в pub.dev или требуют специальной настройки.

## 📋 Инструкция по установке

### 1. AppMetrica

AppMetrica для Flutter может быть установлена через нативный SDK. Проверьте официальную документацию:
- [AppMetrica Android](https://appmetrica.yandex.ru/docs/mobile-sdk-dg/android/quick-start.html)
- [AppMetrica iOS](https://appmetrica.yandex.ru/docs/mobile-sdk-dg/ios/quick-start.html)

Альтернативно, вы можете использовать прямой вызов нативного кода через platform channels.

### 2. AppsFlyer

Установите пакет AppsFlyer:
```bash
flutter pub add appsflyer_sdk
```

Или добавьте вручную в `pubspec.yaml`:
```yaml
dependencies:
  appsflyer_sdk: ^6.14.0
```

Затем выполните:
```bash
flutter pub get
```

### 3. ironSource (опционально)

Если вы хотите использовать ironSource, установите пакет:
```bash
flutter pub add ironsource_mediation
```

Или добавьте вручную в `pubspec.yaml`:
```yaml
dependencies:
  ironsource_mediation: ^8.4.0
```

Затем выполните:
```bash
flutter pub get
```

## 🔧 Активация пакетов в коде

После установки пакетов:

1. **AppMetrica**: Раскомментируйте код в `lib/services/analytics_service.dart`:
   - Строка 1: `import 'package:appmetrica_flutter/appmetrica_flutter.dart';`
   - Метод `_initAppMetrica`
   - Метод `logEvent` (часть AppMetrica)
   - Метод `setUserProperty` (часть AppMetrica)

2. **AppsFlyer**: Раскомментируйте код в `lib/services/analytics_service.dart`:
   - Строка 2: `import 'package:appsflyer_sdk/appsflyer_sdk.dart';`
   - Строка 25: `AppsflyerSdk? _appsflyerSdk;`
   - Метод `_initAppsFlyer`
   - Метод `logEvent` (часть AppsFlyer)

3. **ironSource**: Раскомментируйте код в `lib/services/ad_service.dart`:
   - Строка 4: `import 'package:ironsource_mediation/ironsource_mediation.dart';`
   - Код инициализации ironSource в методе `init`

## ✅ Текущее состояние

Сейчас приложение работает с:
- ✅ Firebase Analytics (установлен и работает)
- ✅ Google Mobile Ads / AdMob (установлен и работает)
- ⚠️ AppMetrica (требует ручной установки)
- ⚠️ AppsFlyer (требует установки пакета)
- ⚠️ ironSource (опционально, требует установки пакета)

## 📝 Примечание

Firebase Analytics и AdMob уже установлены и работают. Остальные пакеты можно добавить позже по необходимости.

