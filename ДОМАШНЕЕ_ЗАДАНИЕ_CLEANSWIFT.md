# Домашнее задание CleanSwift (VIP Architecture)

## Задание
Переписать контроллеры на изученные архитектуры. Взять реализацию проектного модуля и переписать **TheMealDBViewController** на **CleanSwift**.

## Что такое CleanSwift (VIP)?

CleanSwift (также известный как VIP - View, Interactor, Presenter) - это архитектурный паттерн для iOS приложений, основанный на принципах Clean Architecture Роберта Мартина (Uncle Bob).

### Ключевые отличия от VIPER:
- **Однонаправленный поток данных** (unidirectional data flow)
- Отсутствие круговых зависимостей
- Более простая структура по сравнению с VIPER
- Четкое разделение ответственности

## Цикл CleanSwift (VIP Cycle)

```
ViewController → Interactor → Worker → Interactor → Presenter → ViewController
     ↑                                                                 ↓
     └─────────────────────────── Router ──────────────────────────────┘
```

### Компоненты архитектуры:

1. **ViewController** - отвечает только за UI
   - Получает действия пользователя
   - Отправляет Request в Interactor
   - Получает ViewModel от Presenter и обновляет UI

2. **Interactor** - содержит бизнес-логику
   - Получает Request от ViewController
   - Обрабатывает запрос через Worker
   - Отправляет Response в Presenter
   - Хранит состояние через DataStore

3. **Worker** - выполняет работу (сетевые запросы, работа с БД)
   - Инкапсулирует взаимодействие с сервисами
   - Возвращает результаты в Interactor

4. **Presenter** - форматирует данные для отображения
   - Получает Response от Interactor
   - Преобразует в ViewModel
   - Отправляет ViewModel в ViewController

5. **Router** - управляет навигацией
   - Переходы между экранами
   - Передача данных через DataStore

6. **Models** - данные для каждого use case
   - Request - данные от ViewController
   - Response - данные от Interactor
   - ViewModel - данные для отображения

## Реализация в проекте

### Созданные файлы:

#### 1. TheMealDBModels.swift
Содержит все модели для VIP цикла, организованные по Use Cases:
- `LoadCategories` - загрузка категорий
- `LoadCountries` - загрузка стран
- `LoadIngredients` - загрузка ингредиентов
- `LoadRecipes` - загрузка рецептов с различными фильтрами
- `SelectCategory` - выбор категории
- `ApplyFilters` - применение фильтров
- `SearchRecipes` - поиск рецептов
- `LoadRandomRecipe` - загрузка случайного рецепта
- `ShowRecipeDetail` - показ деталей рецепта

Каждый Use Case содержит три типа моделей:
```swift
enum LoadCategories {
    struct Request { /* параметры запроса */ }
    struct Response { /* данные от Interactor */ }
    struct ViewModel { /* данные для UI */ }
}
```

#### 2. TheMealDBWorker.swift
Инкапсулирует работу с сервисами:
- `TheMealDBService` - API TheMealDB
- `TheMealDBCache` - кэширование данных
- Обработка комбинированных запросов (объединение категорий)
- Фильтрация данных

Пример:
```swift
class TheMealDBWorker: TheMealDBWorkerProtocol {
    func fetchCategories(completion: @escaping (Result<[TheMealDBCategory], NetworkError>) -> Void)
    func fetchRandomRecipes(count: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void)
    // ... другие методы
}
```

#### 3. TheMealDBInteractor.swift
Содержит всю бизнес-логику:
- Обработка различных типов фильтров
- Управление состоянием (DataStore)
- Координация работы с Worker
- Пагинация данных

Протоколы:
```swift
protocol TheMealDBBusinessLogic {
    func loadCategories(request: LoadCategories.Request)
    func loadRecipes(request: LoadRecipes.Request)
    // ... другие методы
}

protocol TheMealDBDataStore {
    var recipes: [TheMealDBRecipe] { get set }
    var categories: [TheMealDBCategory] { get set }
    // ... другие свойства
}
```

#### 4. TheMealDBPresenter.swift
Форматирует данные для отображения:
- Преобразует Response в ViewModel
- Форматирует заголовки экрана
- Обрабатывает ошибки для UI

Протоколы:
```swift
protocol TheMealDBPresentationLogic {
    func presentCategories(response: LoadCategories.Response)
    func presentRecipes(response: LoadRecipes.Response, append: Bool, ...)
    // ... другие методы
}

protocol TheMealDBDisplayLogic: AnyObject {
    func displayCategories(viewModel: LoadCategories.ViewModel)
    func displayRecipes(viewModel: LoadRecipes.ViewModel)
    // ... другие методы
}
```

#### 5. TheMealDBRouter.swift
Управляет навигацией:
- Переход к деталям рецепта
- Открытие фильтров
- Открытие поиска
- Возврат назад

Протоколы:
```swift
protocol TheMealDBRoutingLogic {
    func routeToRecipeDetail(recipe: TheMealDBRecipe)
    func routeToFilters(...)
    func routeToSearch()
    func routeBack()
}

protocol TheMealDBDataPassing {
    var dataStore: TheMealDBDataStore? { get }
}
```

#### 6. TheMealDBViewController.swift (переписан)
Упрощен до работы только с UI:
- Настройка и отображение UI элементов
- Обработка действий пользователя
- Реализация DisplayLogic для обновления UI

Ключевые изменения:
- Удалена вся бизнес-логика
- Все данные получаются через DisplayLogic
- Навигация через Router
- Связь с Interactor через Request/ViewModel

## Преимущества реализации

### 1. Разделение ответственности
- **ViewController**: только UI
- **Interactor**: только бизнес-логика
- **Worker**: только работа с данными
- **Presenter**: только форматирование
- **Router**: только навигация

### 2. Тестируемость
Каждый компонент легко тестировать изолированно:
```swift
// Пример теста Interactor
let interactor = TheMealDBInteractor()
let mockPresenter = MockPresenter()
interactor.presenter = mockPresenter

let request = LoadCategories.Request()
interactor.loadCategories(request: request)

XCTAssertTrue(mockPresenter.presentCategoriesWasCalled)
```

### 3. Однонаправленный поток данных
```
User Action → Request → Business Logic → Response → Formatting → ViewModel → UI Update
```

### 4. Отсутствие круговых зависимостей
- ViewController → Interactor (не наоборот)
- Interactor → Presenter (не наоборот)
- Presenter → ViewController (через weak reference)

### 5. Масштабируемость
Легко добавлять новые Use Cases:
1. Добавить Models в TheMealDBModels.swift
2. Добавить метод в Worker (если нужно)
3. Добавить бизнес-логику в Interactor
4. Добавить форматирование в Presenter
5. Добавить обработку в ViewController

## Примеры использования

### Загрузка категорий
```swift
// 1. User action в ViewController
override func viewDidLoad() {
    let request = LoadCategories.Request()
    interactor?.loadCategories(request: request)
}

// 2. Business Logic в Interactor
func loadCategories(request: LoadCategories.Request) {
    worker.fetchCategories { result in
        let response = LoadCategories.Response(categories: categories, error: nil)
        presenter?.presentCategories(response: response)
    }
}

// 3. Formatting в Presenter
func presentCategories(response: LoadCategories.Response) {
    let viewModel = LoadCategories.ViewModel(categories: displayedCategories)
    viewController?.displayCategories(viewModel: viewModel)
}

// 4. Display в ViewController
func displayCategories(viewModel: LoadCategories.ViewModel) {
    displayedCategories = viewModel.categories
    categoriesCollectionView.reloadData()
}
```

### Применение фильтров
```swift
// 1. User действие
func didApplyMealDBFilters(selectedArea: AreaWithFlag?, ...) {
    let request = ApplyFilters.Request(selectedArea: selectedArea, ...)
    interactor?.applyFilters(request: request)
}

// 2. Interactor определяет тип фильтра и загружает данные
func applyFilters(request: ApplyFilters.Request) {
    let loadRequest = LoadRecipes.Request(filterType: .area(area), ...)
    loadRecipes(request: loadRequest)
}

// 3. Presenter форматирует результаты
func presentRecipes(response: LoadRecipes.Response, ...) {
    let title = formatTitle(selectedArea: selectedArea, ...)
    let viewModel = LoadRecipes.ViewModel(recipes: displayedRecipes, title: title, ...)
    viewController?.displayRecipes(viewModel: viewModel)
}

// 4. ViewController обновляет UI
func displayRecipes(viewModel: LoadRecipes.ViewModel) {
    displayedRecipes = viewModel.recipes
    updateTitle(viewModel.title)
    tableView.reloadData()
}
```

## Компетенции

✅ **Проектирование архитектуры приложения**
- Работа с архитектурой CleanSwift (VIP)
- Разделение ответственности между компонентами
- Управление потоком данных

✅ **Реализация экрана на CleanSwift**
- ViewController: только UI, без бизнес-логики
- Interactor: вся бизнес-логика
- Worker: работа с сервисами
- Presenter: форматирование данных
- Router: навигация
- Models: типизированные данные для каждого Use Case

## Результаты

### До рефакторинга (MVC):
- TheMealDBViewController: ~1291 строка
- Вся бизнес-логика в контроллере
- Сложно тестировать
- Сложно расширять

### После рефакторинга (CleanSwift):
- TheMealDBViewController: ~300 строк (только UI)
- TheMealDBInteractor: ~500 строк (бизнес-логика)
- TheMealDBWorker: ~300 строк (работа с данными)
- TheMealDBPresenter: ~150 строк (форматирование)
- TheMealDBRouter: ~100 строк (навигация)
- TheMealDBModels: ~200 строк (типы данных)

### Итого:
- Код разделен на логические компоненты
- Каждый компонент легко тестировать
- Легко добавлять новые фичи
- Четкая структура и поток данных
- Соответствует принципам SOLID

## Заключение

Реализация TheMealDBViewController на архитектуре CleanSwift (VIP) успешно завершена. 

**Основные достижения:**
1. ✅ Полное разделение ответственности между компонентами
2. ✅ Однонаправленный поток данных без круговых зависимостей
3. ✅ Все Use Cases организованы по паттерну Request/Response/ViewModel
4. ✅ Бизнес-логика изолирована в Interactor
5. ✅ Работа с сервисами инкапсулирована в Worker
6. ✅ Форматирование данных вынесено в Presenter
7. ✅ Навигация управляется Router
8. ✅ ViewController содержит только UI код
9. ✅ Код легко тестируется и расширяется
10. ✅ Сохранена вся функциональность оригинального контроллера

**Архитектура готова к:**
- Unit тестированию каждого компонента
- Добавлению новых фич
- Масштабированию приложения
- Командной разработке
