# Pulse

Pulse — минималистичный календарь и планировщик для iOS 18 с разделением работы и личной жизни.

## Локальная генерация проекта на macOS

```bash
brew install xcodegen
xcodegen generate
open Pulse.xcodeproj
```

В Xcode выберите команду разработки и симулятор iOS 18. При первом запуске приложение предложит доступ к календарю. Кнопка «Демо» в состоянии без доступа заполняет интерфейс демонстрационными событиями.

## Проверка из командной строки

```bash
xcodegen generate
xcodebuild test -project Pulse.xcodeproj -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 16'
```

GitHub Actions генерирует проект и запускает тесты на доступном симуляторе автоматически.

## Неподписанный IPA для Feather

Откройте вкладку Actions, выберите workflow «Неподписанный IPA для Feather» и нажмите
`Run workflow`. После успешной сборки скачайте артефакт `Pulse-unsigned`, распакуйте ZIP
и импортируйте `Pulse-unsigned.ipa` в Feather. Сертификаты в репозиторий загружать не нужно:
Feather подписывает IPA локально с помощью пары `.p12` и `.mobileprovision`.

