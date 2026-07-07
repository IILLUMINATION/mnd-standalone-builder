# MND Standalone Builder

Собери свой квест Meander как standalone-приложение для любой платформы.

Построен на [mnd_player](https://github.com/IILLUMINATION/mnd-player),
[mnd_player_kit](https://github.com/IILLUMINATION/mnd-kit) и
[mnd_core](https://github.com/IILLUMINATION/mnd-core).

⚠️ **Лицензия: GNU AGPL v3.0** — ваше standalone-приложение тоже должно быть под AGPL.

## Как использовать

### Локальная сборка

```bash
# 1. Клонировать репо
git clone https://github.com/IILLUMINATION/mnd-standalone-builder.git
cd mnd-standalone-builder

# 2. Заменить quest.mnd на свой квест
cp /path/to/your-quest.mnd assets/quest.mnd
cp /path/to/your-quest.mnd web/quest.mnd   # для web

# 3. Собрать
flutter build apk --release    # Android
flutter build web --base-href /    # Web (менять base-href под свой домен)
flutter build linux --release  # Linux
flutter build windows --release # Windows
```

### CI/CD сборка (GitHub Actions)

1. Форкнуть репо (или "Use this template")
2. Заменить `assets/quest.mnd` + `web/quest.mnd`
3. Actions → "Build Standalone App" → Run workflow
4. Скачать артефакты

## Поддерживаемые платформы

| Платформа | Команда | Выходной файл |
|-----------|---------|--------------|
| Android APK | `flutter build apk --release` | `.apk` |
| Android AAB | `flutter build appbundle --release` | `.aab` (Google Play) |
| Web | `flutter build web --base-href /` | HTML/JS |
| Linux | `flutter build linux --release` | бинарный пакет |
| Windows | `flutter build windows --release` | `.exe` |

## Кастомизация

- **Иконка:** base64 PNG в секрете `ICON_PNG_B64` (минимум 1024x1024)
- **Подпись Android:** keystore в секрете `KEYSTORE_B64`
- **Название приложения:** меняется в CI/CD параметрах

## Структура проекта

```
assets/quest.mnd    ← твой квест (для мобилок/десктопа, вкомпилирован)
web/quest.mnd       ← твой квест (для web, отдельный файл)
lib/main.dart       ← точка входа (распаковка ZIP, запуск плеера)
```

## Web-особенности

- `.mnd` загружается отдельным HTTP-запросом (не вкомпилирован в JS)
- Аудио отключено под web (ограничение платформы)
- Сохранения отключены под web (нет файловой системы)
- Квест загружается в память через `InMemoryAssetStore`
