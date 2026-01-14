# Architecture Best Practices - Micronutrient Tracking

## Overview

This document details the architectural improvements made to the micronutrient tracking system following Swift and iOS best practices.

## Version 1.2.0 - Architectural Refactoring

### Summary of Improvements

1. ✅ **Measurement API Integration** - Type-safe unit handling
2. ✅ **HealthKit Mapping** - Apple Health synchronization support
3. ✅ **Enhanced Codable Support** - Robust JSON serialization
4. ✅ **Enum-Based Architecture** - CaseIterable for iteration
5. ✅ **Namespacing** - Clean, organized code structure

---

## 1. Measurement API Integration

### Problem (Before)
```swift
// Raw doubles with manual unit conversion - error-prone!
var vitaminCValue: Double = 90.0  // Is this mg? mcg? g?
let converted = vitaminCValue * 1000  // Manual conversion

// Unit mismatch bugs
func addNutrient(value: Double, unit: String) {
    if unit == "mg" {
        // ...
    } else if unit == "mcg" {
        // ... manual conversion
    }
}
```

### Solution (After)
```swift
// Type-safe with Swift's Measurement API
let vitaminC = Measurement(value: 90, unit: UnitMass.milligrams)
let inMicrograms = vitaminC.converted(to: .micrograms)  // Automatic!

// Custom unit for micrograms
extension UnitMass {
    static let micrograms = UnitMass(
        symbol: "mcg", 
        converter: UnitConverterLinear(coefficient: 0.000001)
    )
}
```

### Benefits
- **No unit mismatch bugs**: Type system prevents mixing units
- **Automatic conversions**: Foundation handles the math
- **Future-proof**: Easy to add new units (IU, etc.)
- **Testable**: Built-in equality and comparison

### Implementation Details

#### Nutrient Properties
```swift
enum Micronutrient {
    // Each nutrient knows its native unit
    var measurementUnit: Dimension {
        switch self {
        case .vitaminA, .vitaminD, .biotin:
            return UnitMass.micrograms
        case .vitaminC, .calcium:
            return UnitMass.milligrams
        case .saturatedFat:
            return UnitMass.grams
        }
    }
    
    // Daily values as Measurement objects
    var dailyValueMeasurement: Measurement<UnitMass> {
        switch self {
        case .vitaminC:
            return Measurement(value: 90, unit: .milligrams)
        // ...
        }
    }
}
```

#### MicronutrientData Subscripts
```swift
struct MicronutrientData {
    // Legacy: Raw double access
    subscript(nutrient: Micronutrient) -> Double { ... }
    
    // New: Type-safe measurement access
    subscript(measurement nutrient: Micronutrient) -> Measurement<UnitMass> {
        get {
            let value = values[nutrient.rawValue] ?? 0
            return Measurement(value: value, unit: nutrient.measurementUnit as! UnitMass)
        }
        set {
            let converted = newValue.converted(to: nutrient.measurementUnit as! UnitMass)
            values[nutrient.rawValue] = converted.value
        }
    }
}
```

#### Usage Examples
```swift
// Setting values with automatic conversion
var data = MicronutrientData()
data[measurement: .vitaminC] = Measurement(value: 0.09, unit: .grams)
// Automatically stored as 90 mg

// Getting values
let vitaminC = data[measurement: .vitaminC]  // Measurement<UnitMass>
let inGrams = vitaminC.converted(to: .grams)  // 0.09 g

// Percentage calculation (type-safe)
func percentage(for nutrient: Micronutrient) -> Double {
    let current = self[measurement: nutrient]
    let daily = nutrient.dailyValueMeasurement
    let currentInDVUnit = current.converted(to: daily.unit)
    return (currentInDVUnit.value / daily.value) * 100
}
```

---

## 2. HealthKit Integration

### Problem (Before)
```swift
// No way to sync with Apple Health
// Manual mapping required
// No type safety
```

### Solution (After)
```swift
enum Micronutrient {
    // Each nutrient maps to HealthKit identifier
    @available(iOS 8.0, *)
    var healthKitIdentifier: HKQuantityTypeIdentifier? {
        switch self {
        case .vitaminC: return .dietaryVitaminC
        case .calcium: return .dietaryCalcium
        case .chromium: return .dietaryChromium
        // ... all minerals and vitamins
        case .omega3: return nil  // No HK mapping
        }
    }
    
    // Create HealthKit quantity from measurement
    func createHealthKitQuantity(from measurement: Measurement<UnitMass>) -> HKQuantity? {
        guard let identifier = healthKitIdentifier else { return nil }
        
        let hkUnit: HKUnit
        if measurementUnit == UnitMass.micrograms {
            hkUnit = .gramUnit(with: .micro)
        } else if measurementUnit == UnitMass.milligrams {
            hkUnit = .gramUnit(with: .milli)
        } else {
            hkUnit = .gram()
        }
        
        let value = measurement.converted(to: measurementUnit as! UnitMass).value
        return HKQuantity(unit: hkUnit, doubleValue: value)
    }
}
```

### Benefits
- **Apple Health sync**: One-line integration
- **Automatic unit conversion**: HKUnit handled automatically
- **Future-proof**: Easy to add new HealthKit types
- **Privacy-aware**: Optional mapping (some nutrients not in HK)

### Implementation

#### Single Nutrient to HealthKit
```swift
// Convert a single nutrient
let vitaminC = data[measurement: .vitaminC]
if let quantity = Micronutrient.vitaminC.createHealthKitQuantity(from: vitaminC) {
    // Save to HealthKit
}
```

#### Batch Export to HealthKit
```swift
struct MicronutrientData {
    @available(iOS 8.0, *)
    func createHealthKitSamples(
        startDate: Date, 
        endDate: Date
    ) -> [(HKQuantityType, HKQuantitySample)] {
        var samples: [(HKQuantityType, HKQuantitySample)] = []
        
        for nutrient in Micronutrient.allCases {
            guard let identifier = nutrient.healthKitIdentifier,
                  let quantityType = HKQuantityType.quantityType(forIdentifier: identifier),
                  self[nutrient] > 0 else { continue }
            
            let measurement = self[measurement: nutrient]
            if let quantity = nutrient.createHealthKitQuantity(from: measurement) {
                let sample = HKQuantitySample(
                    type: quantityType,
                    quantity: quantity,
                    start: startDate,
                    end: endDate
                )
                samples.append((quantityType, sample))
            }
        }
        
        return samples
    }
}
```

#### Usage in App
```swift
// After user logs food
let samples = foodEntry.micronutrients.createHealthKitSamples(
    startDate: mealTime,
    endDate: mealTime
)

// Save to HealthKit
let healthStore = HKHealthStore()
for (_, sample) in samples {
    healthStore.save(sample) { success, error in
        // Handle result
    }
}
```

### HealthKit Mapping Table

| Micronutrient | HKQuantityTypeIdentifier | Unit |
|---------------|-------------------------|------|
| Vitamin A | `.dietaryVitaminA` | mcg |
| Vitamin C | `.dietaryVitaminC` | mg |
| Vitamin D | `.dietaryVitaminD` | mcg |
| Vitamin E | `.dietaryVitaminE` | mg |
| Vitamin K1/K2 | `.dietaryVitaminK` | mcg |
| Thiamin | `.dietaryThiamin` | mg |
| Riboflavin | `.dietaryRiboflavin` | mg |
| Niacin | `.dietaryNiacin` | mg |
| B6 | `.dietaryVitaminB6` | mg |
| B12 | `.dietaryVitaminB12` | mcg |
| Folate | `.dietaryFolate` | mcg |
| Biotin | `.dietaryBiotin` | mcg |
| Pantothenic Acid | `.dietaryPantothenicAcid` | mg |
| Calcium | `.dietaryCalcium` | mg |
| Chromium | `.dietaryChromium` | mcg |
| Copper | `.dietaryCopper` | mg |
| Iodine | `.dietaryIodine` | mcg |
| Iron | `.dietaryIron` | mg |
| Magnesium | `.dietaryMagnesium` | mg |
| Manganese | `.dietaryManganese` | mg |
| Molybdenum | `.dietaryMolybdenum` | mcg |
| Phosphorus | `.dietaryPhosphorus` | mg |
| Potassium | `.dietaryPotassium` | mg |
| Selenium | `.dietarySelenium` | mcg |
| Sodium | `.dietarySodium` | mg |
| Zinc | `.dietaryZinc` | mg |
| Cholesterol | `.dietaryCholesterol` | mg |
| Sugar | `.dietarySugar` | g |
| Choline | `nil` | - |
| Omega-3 | `nil` | - |
| Omega-6 | `nil` | - |
| Saturated Fat | `nil` | - |
| Trans Fat | `nil` | - |

---

## 3. Enhanced Codable Support

### Problem (Before)
```swift
// Implicit Codable synthesis - fragile
enum Micronutrient: String, Codable {
    case vitaminC = "Vitamin C"
}

// No control over encoding
// Hard to version
```

### Solution (After)
```swift
// Explicit String raw values for stability
enum Micronutrient: String, CaseIterable, Identifiable, Codable {
    case vitaminC = "Vitamin C"  // Readable in JSON
    case vitaminD = "Vitamin D"
    
    var id: String { rawValue }  // Identifiable for SwiftUI
}

// Codable-aware data structure
struct MicronutrientData: Codable, Equatable {
    private(set) var values: [String: Double] = [:]
    
    // JSON format:
    // {
    //   "Vitamin C": 90.0,
    //   "Calcium": 1300.0
    // }
}
```

### Benefits
- **Human-readable JSON**: Keys are nutrient names
- **Version-safe**: Adding nutrients doesn't break old data
- **Database-friendly**: Direct SQLite/Core Data storage
- **Debuggable**: Can inspect JSON directly

### Core Data Integration
```swift
extension FoodEntryEntity {
    var micronutrients: MicronutrientData {
        get {
            guard let data = micronutrientsData else { 
                return MicronutrientData() 
            }
            let decoder = JSONDecoder()
            return (try? decoder.decode(MicronutrientData.self, from: data)) 
                ?? MicronutrientData()
        }
        set {
            let encoder = JSONEncoder()
            micronutrientsData = try? encoder.encode(newValue)
        }
    }
}
```

### Example JSON
```json
{
  "values": {
    "Vitamin C": 90.0,
    "Calcium": 1300.0,
    "Iron": 18.0,
    "Chromium": 35.0,
    "Vitamin K2 (Menaquinone)": 90.0
  }
}
```

---

## 4. Enum-Based Architecture (CaseIterable)

### Problem (Before)
```swift
// Hard-coded nutrient lists
let vitamins = ["Vitamin A", "Vitamin C", ...]  // Easy to forget one

// Manual UI building
func buildNutrientList() {
    // ... lots of manual work
}
```

### Solution (After)
```swift
// Automatic iteration with CaseIterable
enum Micronutrient: String, CaseIterable {
    case vitaminA = "Vitamin A"
    // ...
}

// Automatic UI building
ForEach(Micronutrient.allCases) { nutrient in
    NutrientRow(nutrient: nutrient)
}

// Filter by category
let vitamins = Micronutrient.allCases.filter { $0.category == .vitamins }
```

### Benefits
- **No manual maintenance**: Adding nutrient auto-updates UI
- **Type-safe**: Compiler catches missing cases
- **Easy filtering**: Category-based grouping
- **SwiftUI-ready**: Identifiable + CaseIterable = perfect

### Usage Examples

#### Building UI
```swift
// Automatic list of all nutrients
List {
    ForEach(MicronutrientCategory.allCases) { category in
        Section(header: Text(category.rawValue)) {
            ForEach(Micronutrient.allCases.filter { $0.category == category }) { nutrient in
                MicronutrientRow(
                    nutrient: nutrient,
                    value: data[nutrient],
                    percentage: data.percentage(for: nutrient)
                )
            }
        }
    }
}
```

#### Finding Non-Zero Nutrients
```swift
// Get all nutrients with values
func nonZeroNutrients() -> [Micronutrient] {
    Micronutrient.allCases.filter { self[$0] > 0 }
}
```

#### Body Recomposition Filter
```swift
// Key nutrients for athletes
let bodyRecompNutrients: [Micronutrient] = [
    .chromium, .iodine, .molybdenum, .vitaminK2,
    .vitaminD, .magnesium, .zinc, .biotin, .choline
]

// Display only these
ForEach(bodyRecompNutrients) { nutrient in
    DetailRow(nutrient: nutrient, role: nutrient.metabolicRole)
}
```

---

## 5. Namespacing & Organization

### Problem (Before)
```swift
// Global functions - namespace pollution
func convertMgToMcg(_ value: Double) -> Double { ... }
func mapUSDANutrient(_ name: String) -> String? { ... }
```

### Solution (After)
```swift
// Enum-based namespacing
struct USDANutrientMapper {
    static func mapNutrient(_ usdaNutrient: USDANutrient) 
        -> (Micronutrient, Measurement<UnitMass>)?
    
    private static func identifyNutrient(from name: String) -> Micronutrient?
}

// Extension-based organization
extension USDAFood {
    func extractMicronutrients() -> MicronutrientData
}
```

### Benefits
- **Clear API surface**: Only public what's needed
- **Logical grouping**: Related functions together
- **Discoverability**: Easy to find with autocomplete
- **Maintainability**: Changes isolated to one place

---

## 6. Additional Best Practices

### Computed Properties for Metadata
```swift
enum Micronutrient {
    /// Metabolic role for body recomposition
    var metabolicRole: String {
        switch self {
        case .chromium:
            return "Glucose metabolism, insulin sensitivity, nutrient partitioning"
        case .iodine:
            return "Thyroid function, metabolic rate regulation"
        // ...
        }
    }
}
```

### Operators for Data Manipulation
```swift
struct MicronutrientData {
    // Additive operator
    static func + (lhs: MicronutrientData, rhs: MicronutrientData) -> MicronutrientData
    
    // Compound assignment
    static func += (lhs: inout MicronutrientData, rhs: MicronutrientData)
}

// Usage
let total = breakfast + lunch + dinner
dailyTotal += snack
```

### Legacy Compatibility
```swift
enum Micronutrient {
    // New: Type-safe measurement
    var dailyValueMeasurement: Measurement<UnitMass>
    
    // Old: Backward-compatible double
    var dailyValue: Double {
        dailyValueMeasurement.converted(to: measurementUnit as! UnitMass).value
    }
}
```

---

## Migration Guide

### For Existing Code

#### Before
```swift
let value = data[.vitaminC]  // Double
let percentage = (value / 90.0) * 100  // Manual calculation
```

#### After
```swift
// Option 1: Continue using doubles (backward compatible)
let value = data[.vitaminC]  // Still works!
let percentage = data.percentage(for: .vitaminC)  // Better

// Option 2: Use Measurement API (recommended)
let measurement = data[measurement: .vitaminC]  // Type-safe
let inGrams = measurement.converted(to: .grams)
```

### For New Code

```swift
// Always use Measurement API
var data = MicronutrientData()

// Set values
data[measurement: .vitaminC] = Measurement(value: 90, unit: .milligrams)
data[measurement: .calcium] = Measurement(value: 1.3, unit: .grams)

// Get values
let vitaminC = data[measurement: .vitaminC]
print("Vitamin C: \(vitaminC)")  // "90.0 mg"

// Calculate percentage
let percentage = data.percentage(for: .vitaminC)  // 100%

// Export to HealthKit
if HKHealthStore.isHealthDataAvailable() {
    let samples = data.createHealthKitSamples(
        startDate: mealTime,
        endDate: mealTime
    )
    // Save samples...
}
```

---

## Performance Considerations

### Measurement API Performance
- **Negligible overhead**: Foundation's Measurement is highly optimized
- **Cache conversions**: If converting frequently, cache results
- **Bulk operations**: Use operators (+, +=) for efficiency

### HealthKit Integration
- **Batch writes**: Use `HKHealthStore.save(_:withCompletion:)` for multiple samples
- **Background processing**: Export to HK on background queue
- **Permission handling**: Check authorization before creating samples

### Codable Performance
- **Lazy decoding**: Only decode when accessed
- **Binary storage**: Core Data Binary type is efficient
- **Minimal overhead**: JSON encoding/decoding is fast

---

## Testing Best Practices

### Unit Tests with Measurement
```swift
func testVitaminCConversion() {
    var data = MicronutrientData()
    data[measurement: .vitaminC] = Measurement(value: 0.09, unit: .grams)
    
    XCTAssertEqual(data[.vitaminC], 90.0, accuracy: 0.01)
    
    let measurement = data[measurement: .vitaminC]
    XCTAssertEqual(measurement.unit, UnitMass.milligrams)
    XCTAssertEqual(measurement.value, 90.0, accuracy: 0.01)
}
```

### Mock HealthKit
```swift
// Test without real HealthKit
func testHealthKitSampleCreation() {
    var data = MicronutrientData()
    data[measurement: .vitaminC] = Measurement(value: 90, unit: .milligrams)
    
    let samples = data.createHealthKitSamples(
        startDate: Date(),
        endDate: Date()
    )
    
    XCTAssertEqual(samples.count, 1)
    XCTAssertEqual(samples.first?.0.identifier, HKQuantityTypeIdentifier.dietaryVitaminC.rawValue)
}
```

---

## Summary

### Key Improvements
1. **Type Safety**: Measurement API prevents unit mismatch bugs
2. **HealthKit Ready**: One-line sync with Apple Health
3. **Maintainable**: CaseIterable makes adding nutrients trivial
4. **Future-Proof**: Easy to extend with new units, nutrients, or integrations
5. **Best Practices**: Follows Swift API Design Guidelines

### Code Quality Metrics
- ✅ Type-safe unit handling
- ✅ Protocol-oriented design
- ✅ SwiftUI-ready (Identifiable + CaseIterable)
- ✅ HealthKit integration
- ✅ Testable architecture
- ✅ Codable for persistence
- ✅ Backward compatible

---

**Version**: 1.2.0  
**Date**: January 2026  
**Architecture**: iOS Best Practices  
**Breaking Changes**: None (backward compatible)

