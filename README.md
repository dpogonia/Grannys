# Granny's: Recipe Keeper

Личная книга рецептов для iPhone. Рецепты хранятся на устройстве: их можно записать самому, взять из каталога [TheMealDB](https://www.themealdb.com), отметить избранными, убрать в архив и выгрузить в файл.

При первом запуске, если коллекция пустая, приложение добавляет несколько примеров (API keys и Firebase config не включены).

## Возможности

**Свои рецепты**

- название, ингредиенты и инструкция
- время приготовления, число порций, сложность и калории
- категории и теги
- фото с камеры, из галереи или поиск по [Unsplash](https://unsplash.com)

**Коллекция**

- поиск по своим рецептам
- фильтр по тегам, сложности и ингредиентам
- избранное и архив
- свайп по строке: в архив или удаление

**Каталог TheMealDB**

- поиск по названию
- категории и кухни стран
- случайный рецепт
- сохранение найденного рецепта в свою коллекцию

**Дополнительно**

- перевод рецепта через системный Translation (с iOS 17.4)
- интерфейс на русском и английском, язык переключается в приложении
- экспорт и импорт рецептов в JSON и CSV

## Стек

| | |
| --- | --- |
| UI | UIKit |
| Хранение | Core Data |
| Навигация | координаторы |
| Каталог TheMealDB | VIPER |
| Сеть | Alamofire, Moya |
| Аналитика | Firebase Analytics, Crashlytics |
| Стиль кода | SwiftLint |

Зависимости подключаются через Swift Package Manager.

## Требования

- Xcode 26
- iPhone с iOS 18.6 или новее
- свой ключ Unsplash — только для поиска фотографий
- свой проект Firebase — файл конфигурации нужен, чтобы приложение запустилось

Каталог TheMealDB открывается без ключа.

## Запуск

```bash
git clone https://github.com/dpogonia/granny-recipe-keeper.git
cd granny-recipe-keeper
```

### 1. Ключ Unsplash

В корне репозитория создайте файл `Secrets.xcconfig`:

```
UNSPLASH_ACCESS_KEY = ваш_ключ
```

Ключ бесплатный: [unsplash.com/developers](https://unsplash.com/developers). При сборке значение подставляется в `Info.plist`. Файл уже указан в `.gitignore`.

Пока в файле стоит заглушка `YOUR_UNSPLASH_ACCESS_KEY`, поиск картинок не ходит в API с этим текстом. Остальные экраны от ключа не зависят.

### 2. Firebase

Скачайте `GoogleService-Info.plist` из [консоли Firebase](https://console.firebase.google.com) и положите его в корень проекта, рядом с `Granny's Recipe Keeper.xcodeproj`.

Файл тоже в `.gitignore`. При старте вызывается `FirebaseApp.configure()`, поэтому без своего plist приложение не запустится. В проекте Firebase включите Analytics и Crashlytics.

Идентификатор приложения в таргете: `dpogonia.Granny-s--Recipe-Keeper`. Создайте iOS-приложение с этим Bundle ID или поменяйте идентификатор в настройках таргета под свой.

### 3. Сборка

Откройте `Granny's Recipe Keeper.xcodeproj`, дождитесь загрузки пакетов, выберите симулятор iPhone и запустите схему **Granny's Recipe Keeper**.

## Структура

```
Granny's Recipe Keeper/
├── Coordinators/           навигация
├── Models/                 рецепты, Core Data, перевод, теги
├── Views/                  коллекция, редактирование, фильтры, категории
├── Network Model & Views/  TheMealDB и Unsplash
└── Presentation/           модели и протоколы списка рецептов
```

## Автор

[Dmitrii Pogonia](https://github.com/dpogonia)
