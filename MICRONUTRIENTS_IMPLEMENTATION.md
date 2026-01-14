# Micronutrient Tracking Implementation

## Overview

Added comprehensive micronutrient tracking to MyMacroPal, similar to Cronometer's implementation, with Daily Value (DV%) percentages for vitamins, minerals, and other nutrients.

### Version History

#### v1.2 - Architectural Best Practices (Current)
**Major refactoring** following Swift and iOS best practices:
- **Measurement API Integration**: Type-safe unit handling using Foundation's `Measurement<UnitMass>`
- **HealthKit Integration**: Native Apple Health sync with automatic unit conversion
- **Enhanced Architecture**: CaseIterable enums, computed properties, protocol-oriented design
- **See**: `ARCHITECTURE_BEST_PRACTICES.md` for complete details

#### v1.1 - Body Recomposition Focus
Enhanced to include often-overlooked micronutrients essential for body recomposition:
- **Added Chromium**: Glucose metabolism and insulin sensitivity
- **Added Iodine**: Thyroid function and metabolic rate
- **Added Molybdenum**: Enzyme function and amino acid metabolism
- **Split Vitamin K**: Now tracks K1 (Phylloquinone) and K2 (Menaquinone) separately, as they have distinct metabolic roles

#### v1.0 - Initial Implementation
- 30+ micronutrients tracked
- USDA API integration
- Daily Value (DV%) tracking
- UI components with progress bars

## What Was Added

### 1. Micronutrient Model (`Micronutrients.swift`)

A complete micronutrient tracking system including:

#### Tracked Micronutrients

**Vitamins:**

- Vitamin A, C, D, E
- Vitamin K1 (Phylloquinone) and K2 (Menaquinone) - tracked separately
- B-Complex: Thiamin (B1), Riboflavin (B2), Niacin (B3), Pantothenic Acid (B5), B6, Biotin (B7), Folate (B9), B12
- Choline (essential for liver and fat metabolism)

**Minerals:**

- Macro minerals: Calcium, Magnesium, Phosphorus, Potassium, Sodium
- Trace minerals: Iron, Zinc, Copper, Manganese, Selenium
- **Body recomposition essentials:** Chromium (glucose metabolism), Iodine (thyroid function), Molybdenum (enzyme cofactor)

**Other Nutrients:**

- Essential fatty acids: Omega-3, Omega-6
- Limit nutrients: Saturated Fat, Trans Fat, Cholesterol, Sugar

#### Daily Value Standards

All micronutrients include FDA-approved Daily Value standards for adults:

- Goal nutrients (vitamins, minerals): Shows progress toward 100% DV
- Limit nutrients (sodium, saturated fat, sugar): Shows warning when exceeding limits

#### Body Recomposition Focus

The implementation includes often-overlooked micronutrients critical for body recomposition:

- **Chromium (35 mcg)**: Enhances insulin sensitivity and supports glucose metabolism, crucial for nutrient partitioning and muscle growth
- **Iodine (150 mcg)**: Essential for thyroid hormone production, which regulates metabolic rate and energy expenditure
- **Molybdenum (45 mcg)**: Required for enzyme function in amino acid metabolism and protein synthesis
- **Vitamin K2 (90 mcg)**: Works with Vitamin D for calcium metabolism, supports bone health and cardiovascular function. Tracked separately from K1 as they have distinct roles
- **Biotin (30 mcg)**: Supports protein synthesis, fat metabolism, and energy production
- **Choline (550 mg)**: Critical for liver function, fat metabolism, and preventing fat accumulation

### 2. Core Data Integration

Updated the data model to store micronutrients:

- Added `micronutrientsData` field to `FoodEntryEntity` (Binary/JSON storage)
- Extended entity classes with `micronutrients` computed property
- Automatic encoding/decoding of micronutrient data

### 3. USDA API Integration

Enhanced USDA food data extraction:

- `USDANutrientMapper`: Maps USDA nutrient names to our micronutrient enum
- Automatic unit conversion (g, mg, mcg, IU)
- Extraction of 34 micronutrients from USDA food database
- Per-serving scaling based on chosen portion size
- Distinguishes between Vitamin K1 and K2 for optimal tracking

### 4. Updated View Models

Enhanced existing view models:

- `HomeViewModel`: Tracks total daily micronutrients
- `FoodDetailViewModel`: Calculates micronutrients per serving
- Real-time DV% calculation

### 5. New UI Components (`MicronutrientView.swift`)

#### MicronutrientView
- Expandable category sections (Vitamins, Minerals, Other)
- Individual nutrient rows with:
  - Nutrient name and amount consumed
  - Unit of measurement (mg, mcg, g)
  - Progress bar with color coding
  - DV% percentage

#### MicronutrientSummaryView
- Compact display of key micronutrients
- Shows 6 highlighted nutrients
- Used in food detail screens

#### Color Coding
- **Goal nutrients** (vitamins, minerals):
  - Green: ≥100% (goal met)
  - Blue: ≥50% (good progress)
  - Orange: <50% (needs more)
  
- **Limit nutrients** (sodium, sugar, etc.):
  - Green: <80% (good)
  - Orange: 80-100% (caution)
  - Red: >100% (over limit)

### 6. Updated Views

#### FoodDetailView
- Shows key micronutrient summary for each food
- "View All Micronutrients" button to see complete list
- Micronutrients saved when adding food to log

#### HomeView
- New "Vitamins & Minerals" section
- Quick access to view all micronutrients for the day
- Real-time totals across all food entries

#### SettingsView
- "Micronutrient Daily Values" reference section
- View all FDA Daily Value standards
- Visual indicator for limit nutrients

## How It Works

### Data Flow

1. **USDA Food Selection**:
   ```
   User searches food → USDA API returns nutrients → 
   USDANutrientMapper extracts micronutrients → 
   Scaled to serving size → Displayed in UI
   ```

2. **Saving to Log**:
   ```
   User adds food → Micronutrients encoded to JSON → 
   Stored in Core Data → Totals calculated for day
   ```

3. **Daily Summary**:
   ```
   HomeView fetches all entries → Sums micronutrients → 
   Calculates DV% → Displays progress
   ```

### Automatic Calculations

- All micronutrient values from USDA are per 100g
- Values automatically scale based on chosen serving size
- Daily totals sum across all food entries
- DV% calculated using FDA standards

## Files Created

- `MyMacroPal/Micronutrients.swift` - Core micronutrient model and mappings
- `MyMacroPal/MicronutrientView.swift` - UI components for display

## Files Modified

1. **Core Data Model**: `MyMacroPal.xcdatamodel/contents`
   - Added `micronutrientsData` attribute

2. **Models.swift**
   - Extended `FoodEntryEntity` with micronutrient getter/setter
   - Extended `DailyLogEntity` to calculate total micronutrients

3. **ViewModels.swift**
   - Added micronutrient tracking to `HomeViewModel`
   - Added micronutrient calculation to `FoodDetailViewModel`

4. **FoodDetailView.swift**
   - Added micronutrient summary display
   - Link to view all micronutrients
   - Save micronutrients when adding to log

5. **HomeView.swift**
   - Added "Vitamins & Minerals" section
   - Link to view daily micronutrient totals

6. **SettingsView.swift**
   - Added Daily Values reference section
   - New `MicronutrientDailyValuesView` component

## Usage

### For Users

1. **View Micronutrients in Food Details**:
   - Search for food in USDA database
   - Open food details
   - See key micronutrients automatically displayed
   - Tap "View All Micronutrients" for complete list

2. **Track Daily Progress**:
   - From home screen, tap "View Micronutrients"
   - Expand any category (Vitamins, Minerals, Other)
   - See progress bars and DV% for each nutrient
   - Green = goal met, colors indicate progress

3. **Check Daily Value Standards**:
   - Go to Settings
   - Tap "View Daily Values Reference"
   - See all FDA-approved Daily Value standards

### For Developers

#### Access Micronutrient Data

```swift
// From FoodEntryEntity
let entry: FoodEntryEntity = ...
let micronutrients = entry.micronutrients // MicronutrientData

// Get specific nutrient
let vitaminC = micronutrients[.vitaminC] // Double (in mg)

// Get DV percentage
let percentage = micronutrients.percentage(for: .vitaminC) // Double

// Sum micronutrients from multiple entries
let total = entries.reduce(MicronutrientData()) { $0 + $1.micronutrients }
```

#### Extract from USDA Food

```swift
let usdaFood: USDAFood = ...
let micronutrients = usdaFood.extractMicronutrients() // per 100g

// Scale to serving size
let servingGrams = 150.0
let factor = servingGrams / 100.0
var scaled = MicronutrientData()
for nutrient in Micronutrient.allCases {
    scaled[nutrient] = micronutrients[nutrient] * factor
}
```

## Important Notes

### Micronutrient Availability

- **USDA Foods**: Full micronutrient data extracted from API
- **Built-in Foods**: No micronutrient data (only macros available)
- **Library Foods**: No micronutrient data (only macros available)
- **Manual Entry**: No micronutrient data (user enters macros only)

This is expected behavior - only USDA foods have comprehensive nutrient data.

### Data Migration

Existing food entries in the database will have empty micronutrient data. This is handled gracefully:

- Entries without data return empty `MicronutrientData()`
- No data migration needed
- New USDA foods will automatically include micronutrients

### Daily Values

Daily Values are based on FDA standards for adults and are **not customizable**. This is intentional:

- DV standards are scientifically established
- Consistent with nutrition labels
- Matches Cronometer's approach

Macro goals remain fully customizable in Settings.

## Future Enhancements

Possible future additions:

- Micronutrient data for built-in foods
- Export micronutrient reports
- Micronutrient trends over time
- Warnings for consistently low micronutrients
- Age/gender-specific DV recommendations

## Testing

To test the implementation:

1. **Search and Add USDA Food**:
   - Search for "broccoli" in USDA tab
   - Select a food item
   - Observe micronutrient summary displayed
   - Tap "View All Micronutrients"
   - Verify all categories and nutrients shown
   - Add to today's log

2. **View Daily Totals**:
   - Return to home screen
   - Tap "View Micronutrients" in Vitamins & Minerals section
   - Expand each category
   - Verify progress bars and percentages
   - Add multiple foods and verify totals update

3. **Check Settings**:
   - Go to Settings
   - Tap "View Daily Values Reference"
   - Verify all micronutrients listed with DV standards

## API Compatibility

Compatible with USDA FoodData Central API v1:

- Nutrient names from standard USDA database
- Handles variations in nutrient naming
- Robust unit conversion (G, MG, UG, IU)
- Graceful handling of missing nutrients

## Performance

- Micronutrient calculations are lightweight (simple dictionary operations)
- JSON encoding/decoding happens only on save/load
- No performance impact on existing functionality
- Efficient Core Data storage (binary JSON)

---

**Implementation Date**: January 2026  
**Version**: 1.2.0  
**Based on**: Cronometer's micronutrient tracking model  
**Standards**: FDA Daily Value recommendations (2020)  
**Architecture**: Swift best practices with Measurement API and HealthKit integration  
**Enhancements**: 
- v1.2: Measurement API, HealthKit mapping, architectural refactoring
- v1.1: Body recomposition micronutrients (Chromium, Iodine, Molybdenum, K1/K2 split)
- v1.0: Initial 30+ micronutrients with DV% tracking
