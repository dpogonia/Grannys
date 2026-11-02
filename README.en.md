[Русский](README.md) | **English**

# Granny's: Recipe Keeper

A personal recipe book for iPhone. Recipes stay on the device: write your own, save one from the [TheMealDB](https://www.themealdb.com) catalog, mark favorites, archive them, and export them to a file.

On the first launch, if the collection is empty, the app adds a few sample recipes (API keys and the Firebase config are not included).

## Features

**Your recipes**

- name, ingredients, and instructions
- cooking time, servings, difficulty, and calories
- categories and tags
- a photo from the camera, the photo library, or [Unsplash](https://unsplash.com) search

**Collection**

- search your own recipes
- filter by tags, difficulty, and ingredients
- favorites and archive
- swipe a row to archive or delete it

**TheMealDB catalog**

- search by name
- categories and cuisines
- a random recipe
- save a found recipe into your collection

**Also**

- translate a recipe with the system Translation framework (iOS 17.4 and later)
- Russian and English interface, switched inside the app
- export and import recipes as JSON and CSV

## Stack

| | |
| --- | --- |
| UI | UIKit |
| Storage | Core Data |
| Navigation | coordinators |
| TheMealDB catalog | VIPER |
| Networking | Alamofire, Moya |
| Analytics | Firebase Analytics, Crashlytics |
| Style | SwiftLint |

Dependencies come from Swift Package Manager.

## Requirements

- Xcode 26
- iPhone on iOS 18.6 or later
- your own Unsplash key, only for photo search
- your own Firebase project — the config file is required for the app to launch

The TheMealDB catalog works without a key.

## Run

```bash
git clone https://github.com/dpogonia/granny-recipe-keeper.git
cd granny-recipe-keeper
```

### 1. Unsplash key

In the repository root, create `Secrets.xcconfig`:

```
UNSPLASH_ACCESS_KEY = your_key
```

The key is free: [unsplash.com/developers](https://unsplash.com/developers). The build substitutes the value into `Info.plist`. The file is already listed in `.gitignore`.

While the file still contains the placeholder `YOUR_UNSPLASH_ACCESS_KEY`, image search does not send that text to the API. The other screens do not depend on the key.

### 2. Firebase

Download `GoogleService-Info.plist` from the [Firebase console](https://console.firebase.google.com) and put it in the project root, next to `Granny's Recipe Keeper.xcodeproj`.

That file is in `.gitignore` too. The app calls `FirebaseApp.configure()` at launch, so it will not start without your own plist. Enable Analytics and Crashlytics in the Firebase project.

The target bundle identifier is `dpogonia.Granny-s--Recipe-Keeper`. Create an iOS app with that bundle ID, or change the identifier in the target settings to yours.

### 3. Build

Open `Granny's Recipe Keeper.xcodeproj`, wait for the packages to download, pick an iPhone simulator, and run the **Granny's Recipe Keeper** scheme.

## Structure

```
Granny's Recipe Keeper/
├── Coordinators/           navigation
├── Models/                 recipes, Core Data, translation, tags
├── Views/                  collection, editing, filters, categories
├── Network Model & Views/  TheMealDB and Unsplash
└── Presentation/           models and protocols for the recipe list
```

## Author

[Dmitrii Pogonia](https://github.com/dpogonia)
