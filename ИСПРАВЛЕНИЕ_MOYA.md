# Исправление ошибки "No such module 'Moya'"

## 🔍 Диагностика

✅ Moya установлена (версия 15.0.3)  
❌ Moya не добавлена к Target проекта  

## ✅ Решение

### Способ 1: Через General (РЕКОМЕНДУЕТСЯ)

#### Шаг 1: Откройте настройки проекта
1. В Xcode нажмите **⌘+1** (Project Navigator)
2. Кликните на **проект** (синяя иконка "Granny's Recipe Keeper" в самом верху)
3. В центральной панели выберите **Target "Granny's Recipe Keeper"** (под TARGETS)

#### Шаг 2: Перейдите на вкладку General
1. Должна быть активна вкладка **"General"** вверху
2. Прокрутите вниз до секции **"Frameworks, Libraries, and Embedded Content"**

#### Шаг 3: Добавьте Moya
1. Нажмите кнопку **`+`** (плюс) под списком фреймворков
2. В появившемся окне увидите список доступных библиотек
3. Найдите **"Moya"** (используйте поиск если нужно)
4. **ВАЖНО:** Выберите просто **"Moya"**, а НЕ:
   - ❌ Moya/ReactiveSwift
   - ❌ Moya/RxSwift
   - ✅ **Moya** (без суффиксов)
5. Нажмите **"Add"**

#### Шаг 4: Проверьте настройки
В списке "Frameworks, Libraries, and Embedded Content" должно появиться:
```
📦 Moya.framework        Do Not Embed
```

#### Шаг 5: Очистите и пересоберите
```
⇧⌘K (Shift + Command + K) - Clean Build Folder
⌘B (Command + B) - Build
```

---

### Способ 2: Через Build Phases

Если Способ 1 не сработал:

#### Шаг 1: Откройте Build Phases
1. Project → Target "Granny's Recipe Keeper"
2. Перейдите на вкладку **"Build Phases"**

#### Шаг 2: Link Binary With Libraries
1. Раскройте секцию **"Link Binary With Libraries"**
2. Нажмите кнопку **`+`** внизу списка
3. Найдите **"Moya"** в списке
4. Выберите **"Moya.framework"**
5. Нажмите **"Add"**

#### Шаг 3: Проверьте Frameworks
Убедитесь, что Moya появилась в списке с статусом "Required"

#### Шаг 4: Пересоберите
```
⇧⌘K → ⌘B
```

---

### Способ 3: Переустановка пакета (если ничего не помогло)

#### Шаг 1: Удалите Moya
1. Project → Package Dependencies (вкладка)
2. Найдите **"Moya"** в списке
3. Нажмите кнопку **`-`** (минус)
4. Подтвердите удаление

#### Шаг 2: Очистите кеши
Закройте Xcode и в терминале:
```bash
cd "/Users/dpogonia/Documents/Swift/Projects/Main/Grannys"
rm -rf ~/Library/Developer/Xcode/DerivedData/Granny\'s_Recipe_Keeper-*
rm -rf .build
```

#### Шаг 3: Добавьте Moya заново
1. Откройте проект в Xcode
2. Project → Package Dependencies
3. Нажмите **`+`** (плюс)
4. Введите URL: `https://github.com/Moya/Moya.git`
5. Version: **15.0.0** (или выше)
6. Нажмите **"Add Package"**
7. В следующем окне выберите **"Moya"** (без суффиксов)
8. Target: ✅ **Granny's Recipe Keeper**
9. Нажмите **"Add Package"**

#### Шаг 4: Проверьте Target Membership
1. Выберите файл `CountriesAPI.swift` в Project Navigator
2. Откройте File Inspector (⌘⌥1)
3. В секции "Target Membership" должна стоять галочка:
   - ✅ Granny's Recipe Keeper

#### Шаг 5: Пересоберите
```
⇧⌘K → ⌘B
```

---

## 🔍 Проверка правильности установки

### 1. Проверьте Package Dependencies:
```
Project → Package Dependencies (вкладка)
```
Должна быть строка:
```
📦 Moya - https://github.com/Moya/Moya.git - 15.0.3
```

### 2. Проверьте Frameworks:
```
Target → General → Frameworks, Libraries, and Embedded Content
```
Должна быть строка:
```
📦 Moya - Do Not Embed
```

### 3. Проверьте импорт:
В файле `CountriesAPI.swift` в начале:
```swift
import Foundation
import Moya  // ← Эта строка не должна быть красной!
```

### 4. Успешная сборка:
```
⌘B → Build Succeeded ✅
```

---

## 🎯 Частые ошибки

### ❌ "No such module 'Moya'"
**Причина:** Moya не добавлена к Target  
**Решение:** Способ 1 выше

### ❌ "Cannot find 'MoyaProvider' in scope"
**Причина:** Не тот пакет Moya (ReactiveSwift/RxSwift)  
**Решение:** Удалите и добавьте правильный пакет (просто "Moya")

### ❌ "Module 'Moya' has no member 'Provider'"
**Причина:** Старая версия Moya  
**Решение:** Обновите до 15.0.0+

### ❌ Xcode зависает при добавлении пакета
**Причина:** Проблемы с кешем  
**Решение:** Способ 3 (переустановка)

---

## 💡 Полезные команды

### Очистка всех кешей Xcode:
```bash
# Закройте Xcode перед выполнением!
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/org.swift.swiftpm/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
```

### Проверка зависимостей:
```bash
cd "/Users/dpogonia/Documents/Swift/Projects/Main/Grannys"
cat "Granny's Recipe Keeper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" | grep -A 5 "moya"
```

---

## 📱 После исправления

Если все сделано правильно:
- ✅ Build проходит без ошибок (⌘B)
- ✅ Импорт `import Moya` не красный
- ✅ `MoyaProvider` распознается в коде
- ✅ Autocomplete работает для Moya классов

---

## 🆘 Если ничего не помогло

Создайте issue с информацией:
1. Версия Xcode (Xcode → About Xcode)
2. Версия macOS
3. Скриншот секции "Frameworks, Libraries, and Embedded Content"
4. Скриншот вкладки "Package Dependencies"

Или напишите мне - помогу разобраться! 🚀
