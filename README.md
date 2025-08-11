# MyMacroPal

A simple, subscription-free iOS app for tracking food macros with USDA FoodData Central integration.

## Features

- **Track 5 key macros**: Calories, Protein, Fat, Carbs, and Fiber
- **USDA Food Database**: Search and add foods from the official USDA FoodData Central API
- **Manual Entry**: Add custom foods with direct macro input
- **Daily Progress**: Visual progress bars showing daily totals vs goals
- **History**: View past days and detailed food logs
- **Customizable Goals**: Set and adjust daily macro targets
- **Local Storage**: All data stored locally using Core Data (no cloud sync required)

## Screenshots

### Home Screen

- Today's date and macro progress
- Visual progress bars for each macro
- Quick access to add food, history, and settings

### Add Food

- **USDA Search Tab**: Search the USDA database with debounced search
- **Manual Entry Tab**: Direct input of food name and macros

### Food Details (USDA)

- Serving size selection with quick portion options
- Real-time macro calculation based on serving size
- Source attribution to USDA

### History

- List of past days with macro summaries
- Detailed view of each day's food items
- Visual indicators for USDA vs manual entries

### Settings

- Adjustable daily macro goals
- App information and version details

## Setup Instructions

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- USDA FoodData Central API key (free)

### 1. Get USDA API Key

1. Visit [USDA FoodData Central](https://fdc.nal.usda.gov/api-key-signup.html)
2. Sign up for a free API key
3. Copy your API key

### 2. Configure the App

Use Info.plist to store your USDA API key (recommended):

1. In Xcode, select the app target → Info → Custom iOS Target Properties.
2. Add a new String key named `USDA_API_KEY` and set its value to your API key.
3. Build and run. The app will read the key from `Info.plist` (or from the `USDA_API_KEY` environment variable when running previews/tests).

If the key is missing, the app will show a readable error under the search bar and no results will be returned.

### 3. Build and Run

1. Open the project in Xcode
2. Select your target device or simulator
3. Build and run the app (⌘+R)

## Project Structure

```markdown
MyMacroPal/
├── MyMacroPalApp.swift          # App entry point
├── PersistenceController.swift  # Core Data setup
├── USDAService.swift           # USDA API integration
├── Models.swift                # Data models and entities
├── ViewModels.swift            # MVVM view models
├── HomeView.swift              # Main dashboard
├── AddFoodView.swift           # Food addition interface
├── FoodDetailView.swift        # USDA food details
├── HistoryView.swift           # Past days view
├── SettingsView.swift          # Goals and settings
└── MyMacroPalModel.xcdatamodeld/ # Core Data model
```

## Core Data Schema

### FoodEntryEntity

- `id`: UUID
- `name`: String (food name)
- `calories`, `protein`, `fat`, `carbs`, `fiber`: Double
- `quantityGrams`: Double (serving size)
- `source`: String ("usda" or "manual")
- `fdcId`: Int64 (USDA food ID)
- `date`: Date
- `dailyLog`: Relationship to DailyLogEntity

### DailyLogEntity

- `id`: UUID
- `date`: Date
- `goalCalories`, `goalProtein`, `goalFat`, `goalCarbs`, `goalFiber`: Double
- `entries`: Relationship to FoodEntryEntity (to-many)

## USDA API Integration

The app uses the USDA FoodData Central API v1:

- **Search Endpoint**: `/foods/search` - Find foods by name
- **Detail Endpoint**: `/food/{fdcId}` - Get detailed nutrition info
- **Rate Limits**: 3,600 requests per hour (free tier)

### API Response Mapping

- `description` → Food name
- `dataType` → Source label (e.g., "USDA SR Legacy")
- `foodNutrients` → Macro values (per 100g)
- `foodPortions` → Serving size options

## Default Macro Goals

- **Calories**: 2,000 kcal
- **Protein**: 150g
- **Fat**: 70g
- **Carbs**: 250g
- **Fiber**: 30g

These can be customized in the Settings screen.

## Technical Details

- **Framework**: SwiftUI + Core Data
- **Architecture**: MVVM with Combine
- **Networking**: Async/await with URLSession
- **Data Persistence**: Core Data with local storage
- **Search**: Debounced (300ms) USDA API calls; API key provided via `X-Api-Key` header
- **UI**: Native iOS design with custom progress bars

## Future Enhancements

- Barcode scanning for packaged foods
- Meal planning and recipes
- Export data functionality
- Widget support
- Apple Health integration
- Cloud sync (optional)

## Privacy

- All data stored locally on device
- No personal data sent to external services
- USDA API calls only for food search/details
- No analytics or tracking

## License

This project is open source. Feel free to modify and distribute.

## Support

For issues or questions:

1. Check the USDA API documentation
2. Verify your API key is correctly configured
3. Ensure you're running iOS 17.0+
