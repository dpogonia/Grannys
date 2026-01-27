# Behavioral Design Patterns Summary

## Overview
This document provides a comprehensive summary of behavioral design patterns implemented in the Granny's Recipe Keeper project.

## Implemented Patterns

### 1. Strategy Pattern (Стратегия)

**Purpose:** Defines a family of algorithms, encapsulates each one, and makes them interchangeable.

**Location:** `BehavioralPatternsExamples.swift`

**Implementation:**
- `RecipeSortStrategy` protocol - defines the strategy interface
- 8 concrete strategies for sorting recipes:
  - `SortByNameStrategy` - alphabetically (A-Z)
  - `SortByNameDescendingStrategy` - alphabetically (Z-A)
  - `SortByDateNewestStrategy` - by date (newest first)
  - `SortByDateOldestStrategy` - by date (oldest first)
  - `SortByCookingTimeStrategy` - by cooking time
  - `SortByCaloriesStrategy` - by calories
  - `SortByDifficultyStrategy` - by difficulty
  - `SortByFavoritesStrategy` - favorites first
- `RecipeSorter` - context class
- `RecipeSortStrategyManager` - manages all available strategies

**Benefits:**
- Easy to add new sorting strategies
- Client code doesn't depend on concrete implementations
- Each strategy can be tested independently
- Strategy can be changed at runtime

---

### 2. Memento Pattern (Хранитель)

**Purpose:** Captures and externalizes an object's internal state for later restoration without violating encapsulation.

**Location:** `BehavioralPatternsExamples.swift`

**Implementation:**
- `RecipeFilterMemento` - snapshot of filter state
- `RecipeFilterState` - originator (object whose state is saved)
- `RecipeFilterCaretaker` - manages saving/restoring state

**Benefits:**
- Preserves user settings between sessions
- Doesn't violate encapsulation
- Enables undo/redo functionality
- Stores state history

---

### 3. Observer Pattern (Наблюдатель)

**Purpose:** Defines a one-to-many dependency between objects so that when one object changes state, all its dependents are notified.

**Location:** Implemented throughout the app via **Delegate pattern**

**Implementation:**
- `RecipeEditViewControllerDelegate` - notifies about recipe saves
- `FilterViewControllerDelegate` - notifies about filter changes
- `CategoriesViewControllerDelegate` - notifies about category selection
- `RecipeDetailViewControllerDelegate` - notifies about recipe updates/deletes
- `UnsplashImageSearchViewControllerDelegate` - notifies about image selection

**Files with Observer pattern:**
- `RecipeEditViewController.swift`
- `FilterViewController.swift`
- `RecipesViewController.swift`

**Benefits:**
- Loose coupling between objects
- Multiple observers can react to changes
- Dynamic subscription/unsubscription
- Broadcast communication support

---

### 4. Template Method Pattern (Шаблонный метод)

**Purpose:** Defines the skeleton of an algorithm, deferring some steps to subclasses.

**Location:** `BehavioralPatternsExamples.swift`

**Implementation:**
- `APIDataProcessor` - abstract base class with template method
- `TheMealDBDataProcessor` - concrete implementation for TheMealDB API
- Template method steps:
  1. `validateBeforeLoad()` - validation before loading
  2. `fetchDataFromAPI()` - fetch data from API (must be overridden)
  3. `processRawData()` - process raw data
  4. `validateProcessedData()` - validate processed data
  5. `convertToRecipes()` - convert to Recipe model (must be overridden)
  6. `finalizeProcessing()` - finalization (caching, logging)
  7. `handleError()` - error handling

**Benefits:**
- Avoids code duplication
- Defines common algorithm structure
- Subclasses can override only necessary steps
- Inversion of control

---

### 5. Command Pattern (Команда)

**Purpose:** Encapsulates a request as an object, allowing for parameterization, queuing, logging, and undo support.

**Location:**
- `ImageLoadOperation.swift` - image loading commands
- `BehavioralPatternsExamples.swift` - recipe operation commands

**Implementation:**

**Image Loading Commands:**
- `ImageLoadOperation` - encapsulates image loading as Operation
- Can be queued in OperationQueue
- Supports cancellation

**Recipe Operation Commands:**
- `RecipeCommand` protocol - command interface
- `AddToFavoritesCommand` - add recipe to favorites
- `RemoveFromFavoritesCommand` - remove from favorites
- `ArchiveRecipeCommand` - archive recipe
- `RecipeCommandInvoker` - executes commands and stores history for undo

**Benefits:**
- Encapsulates requests as objects
- Supports undo/redo operations
- Commands can be queued
- Separates execution code from invocation code

---

## Files Structure

### New Files
- `BehavioralPatternsExamples.swift` - implementation and examples of all behavioral patterns

### Modified Files (comments added)
- `RecipeEditViewController.swift` - Observer pattern comments
- `RecipesViewController.swift` - Observer implementation comments
- `FilterViewController.swift` - Observer pattern comments
- `ImageLoadOperation.swift` - Command pattern comments

---

## Testing Patterns

### Running Examples
Add to `SceneDelegate.swift`:

```swift
#if DEBUG
    BehavioralPatternsExamples().runAllExamples()
#endif
```

Or run specific examples:

```swift
let examples = BehavioralPatternsExamples()

// Strategy
examples.strategyExample1_SortByName()
examples.strategyExample2_ChangingStrategy()

// Memento
examples.mementoExample1_SaveAndRestore()
examples.mementoExample2_MultipleStates()

// Template Method
examples.templateMethodExample()

// Command
examples.commandExample()
```

---

## Pattern Relationships

```
Strategy + Memento
├── Strategy sorts recipes
└── Memento saves filter state (including sort strategy)

Observer + Command
├── Observer notifies about changes
└── Command encapsulates operations (can be undone)

Template Method + Strategy
├── Template Method defines algorithm structure
└── Strategy provides different sorting algorithms
```

---

## Summary

✅ **5 Behavioral Patterns Implemented:**
1. Strategy - 8 sorting strategies
2. Memento - filter state persistence
3. Observer - delegate-based notifications
4. Template Method - API data processing
5. Command - operations with undo support

✅ **Code Quality:**
- Comprehensive documentation
- Working examples for each pattern
- Clean, testable code
- Follows SOLID principles

✅ **Practical Application:**
- Real-world use cases
- Integrated with existing codebase
- Production-ready implementations
