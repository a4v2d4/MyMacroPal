import Foundation
import HealthKit

// MARK: - Nutrient Units
extension UnitMass {
    /// Micrograms (mcg or μg)
    static let micrograms = UnitMass(symbol: "mcg", converter: UnitConverterLinear(coefficient: 0.000001))
}

// MARK: - Micronutrient Definition
enum Micronutrient: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    
    // MARK: - Vitamins
    case vitaminA = "Vitamin A"
    case vitaminC = "Vitamin C"
    case vitaminD = "Vitamin D"
    case vitaminE = "Vitamin E"
    case vitaminK1 = "Vitamin K1 (Phylloquinone)"
    case vitaminK2 = "Vitamin K2 (Menaquinone)"
    case thiamin = "Thiamin (B1)"
    case riboflavin = "Riboflavin (B2)"
    case niacin = "Niacin (B3)"
    case pantothenicAcid = "Pantothenic Acid (B5)"
    case vitaminB6 = "Vitamin B6"
    case biotin = "Biotin (B7)"
    case folate = "Folate (B9)"
    case vitaminB12 = "Vitamin B12"
    case choline = "Choline"
    
    // MARK: - Minerals
    case calcium = "Calcium"
    case chromium = "Chromium"
    case copper = "Copper"
    case iodine = "Iodine"
    case iron = "Iron"
    case magnesium = "Magnesium"
    case manganese = "Manganese"
    case molybdenum = "Molybdenum"
    case phosphorus = "Phosphorus"
    case potassium = "Potassium"
    case selenium = "Selenium"
    case sodium = "Sodium"
    case zinc = "Zinc"
    
    // MARK: - Other Nutrients
    case omega3 = "Omega-3"
    case omega6 = "Omega-6"
    case saturatedFat = "Saturated Fat"
    case transFat = "Trans Fat"
    case cholesterol = "Cholesterol"
    case sugar = "Sugar"
    
    // MARK: - Properties
    
    var category: MicronutrientCategory {
        switch self {
        case .vitaminA, .vitaminC, .vitaminD, .vitaminE, .vitaminK1, .vitaminK2,
             .thiamin, .riboflavin, .niacin, .pantothenicAcid, .vitaminB6, .biotin,
             .folate, .vitaminB12, .choline:
            return .vitamins
            
        case .calcium, .chromium, .copper, .iodine, .iron, .magnesium, .manganese,
             .molybdenum, .phosphorus, .potassium, .selenium, .sodium, .zinc:
            return .minerals
            
        case .omega3, .omega6, .saturatedFat, .transFat, .cholesterol, .sugar:
            return .other
        }
    }
    
    /// The unit type for this nutrient using Swift's Measurement framework
    var measurementUnit: Dimension {
        switch self {
        // Micrograms (mcg)
        case .vitaminA, .vitaminD, .vitaminK1, .vitaminK2, .biotin, .folate, .vitaminB12,
             .chromium, .iodine, .molybdenum, .selenium:
            return UnitMass.micrograms
            
        // Milligrams (mg)
        case .vitaminC, .vitaminE, .thiamin, .riboflavin, .niacin, .pantothenicAcid,
             .vitaminB6, .choline, .calcium, .copper, .iron, .magnesium, .manganese,
             .phosphorus, .potassium, .sodium, .zinc, .omega3, .omega6, .cholesterol:
            return UnitMass.milligrams
            
        // Grams (g)
        case .saturatedFat, .transFat, .sugar:
            return UnitMass.grams
        }
    }
    
    /// Daily Value (DV) based on FDA standards for adults
    var dailyValueMeasurement: Measurement<UnitMass> {
        switch self {
        // Vitamins - Micrograms
        case .vitaminA:
            return Measurement(value: 900, unit: .micrograms)
        case .vitaminD:
            return Measurement(value: 20, unit: .micrograms)
        case .vitaminK1:
            return Measurement(value: 120, unit: .micrograms)
        case .vitaminK2:
            return Measurement(value: 90, unit: .micrograms)
        case .biotin:
            return Measurement(value: 30, unit: .micrograms)
        case .folate:
            return Measurement(value: 400, unit: .micrograms)
        case .vitaminB12:
            return Measurement(value: 2.4, unit: .micrograms)
            
        // Vitamins - Milligrams
        case .vitaminC:
            return Measurement(value: 90, unit: .milligrams)
        case .vitaminE:
            return Measurement(value: 15, unit: .milligrams)
        case .thiamin:
            return Measurement(value: 1.2, unit: .milligrams)
        case .riboflavin:
            return Measurement(value: 1.3, unit: .milligrams)
        case .niacin:
            return Measurement(value: 16, unit: .milligrams)
        case .pantothenicAcid:
            return Measurement(value: 5, unit: .milligrams)
        case .vitaminB6:
            return Measurement(value: 1.7, unit: .milligrams)
        case .choline:
            return Measurement(value: 550, unit: .milligrams)
            
        // Minerals - Micrograms
        case .chromium:
            return Measurement(value: 35, unit: .micrograms)
        case .iodine:
            return Measurement(value: 150, unit: .micrograms)
        case .molybdenum:
            return Measurement(value: 45, unit: .micrograms)
        case .selenium:
            return Measurement(value: 55, unit: .micrograms)
            
        // Minerals - Milligrams
        case .calcium:
            return Measurement(value: 1300, unit: .milligrams)
        case .copper:
            return Measurement(value: 0.9, unit: .milligrams)
        case .iron:
            return Measurement(value: 18, unit: .milligrams)
        case .magnesium:
            return Measurement(value: 420, unit: .milligrams)
        case .manganese:
            return Measurement(value: 2.3, unit: .milligrams)
        case .phosphorus:
            return Measurement(value: 1250, unit: .milligrams)
        case .potassium:
            return Measurement(value: 4700, unit: .milligrams)
        case .sodium:
            return Measurement(value: 2300, unit: .milligrams)
        case .zinc:
            return Measurement(value: 11, unit: .milligrams)
            
        // Other - Milligrams
        case .omega3:
            return Measurement(value: 1600, unit: .milligrams)
        case .omega6:
            return Measurement(value: 17000, unit: .milligrams)
        case .cholesterol:
            return Measurement(value: 300, unit: .milligrams)
            
        // Other - Grams
        case .saturatedFat:
            return Measurement(value: 20, unit: .grams)
        case .transFat:
            return Measurement(value: 0, unit: .grams)
        case .sugar:
            return Measurement(value: 50, unit: .grams)
        }
    }
    
    /// Legacy daily value as Double for backward compatibility
    var dailyValue: Double {
        return dailyValueMeasurement.converted(to: measurementUnit as! UnitMass).value
    }
    
    /// Unit symbol for display (mcg, mg, g)
    var unit: String {
        measurementUnit.symbol
    }
    
    /// Whether this nutrient is a "limit" rather than a goal
    var isLimitNutrient: Bool {
        switch self {
        case .saturatedFat, .transFat, .cholesterol, .sugar, .sodium:
            return true
        default:
            return false
        }
    }
    
    /// HealthKit quantity type identifier for syncing with Apple Health
    @available(iOS 8.0, *)
    var healthKitIdentifier: HKQuantityTypeIdentifier? {
        switch self {
        // Vitamins
        case .vitaminA: return .dietaryVitaminA
        case .vitaminC: return .dietaryVitaminC
        case .vitaminD: return .dietaryVitaminD
        case .vitaminE: return .dietaryVitaminE
        case .vitaminK1, .vitaminK2: return .dietaryVitaminK
        case .thiamin: return .dietaryThiamin
        case .riboflavin: return .dietaryRiboflavin
        case .niacin: return .dietaryNiacin
        case .pantothenicAcid: return .dietaryPantothenicAcid
        case .vitaminB6: return .dietaryVitaminB6
        case .biotin: return .dietaryBiotin
        case .folate: return .dietaryFolate
        case .vitaminB12: return .dietaryVitaminB12
            
        // Minerals
        case .calcium: return .dietaryCalcium
        case .chromium: return .dietaryChromium
        case .copper: return .dietaryCopper
        case .iodine: return .dietaryIodine
        case .iron: return .dietaryIron
        case .magnesium: return .dietaryMagnesium
        case .manganese: return .dietaryManganese
        case .molybdenum: return .dietaryMolybdenum
        case .phosphorus: return .dietaryPhosphorus
        case .potassium: return .dietaryPotassium
        case .selenium: return .dietarySelenium
        case .sodium: return .dietarySodium
        case .zinc: return .dietaryZinc
            
        // Other nutrients
        case .cholesterol: return .dietaryCholesterol
        case .sugar: return .dietarySugar
            
        // No direct HealthKit mapping
        case .choline, .omega3, .omega6, .saturatedFat, .transFat:
            return nil
        }
    }
    
    /// Create a HealthKit quantity from a measurement
    @available(iOS 8.0, *)
    func createHealthKitQuantity(from measurement: Measurement<UnitMass>) -> HKQuantity? {
        guard let identifier = healthKitIdentifier else { return nil }
        
        // Convert to HealthKit's expected unit
        let hkUnit: HKUnit
        if measurementUnit == UnitMass.micrograms {
            hkUnit = .gramUnit(with: .micro)
        } else if measurementUnit == UnitMass.milligrams {
            hkUnit = .gramUnit(with: .milli)
        } else {
            hkUnit = .gram()
        }
        
        let convertedValue = measurement.converted(to: measurementUnit as! UnitMass).value
        return HKQuantity(unit: hkUnit, doubleValue: convertedValue)
    }
    
    /// Metabolic role description for body recomposition
    var metabolicRole: String {
        switch self {
        case .chromium:
            return "Glucose metabolism, insulin sensitivity, nutrient partitioning"
        case .iodine:
            return "Thyroid function, metabolic rate regulation"
        case .molybdenum:
            return "Amino acid metabolism, protein synthesis"
        case .vitaminK2:
            return "Bone health, calcium metabolism, cardiovascular function"
        case .biotin:
            return "Protein synthesis, fat metabolism, energy production"
        case .choline:
            return "Liver function, fat metabolism, prevents fatty liver"
        case .vitaminD:
            return "Calcium absorption, bone health, immune function, testosterone"
        case .magnesium:
            return "Protein synthesis, muscle function, energy production"
        case .zinc:
            return "Testosterone production, protein synthesis, immune function"
        default:
            return ""
        }
    }
}

// MARK: - Category
enum MicronutrientCategory: String, CaseIterable, Identifiable, Codable {
    case vitamins = "Vitamins"
    case minerals = "Minerals"
    case other = "Other Nutrients"
    
    var id: String { rawValue }
}

// MARK: - Micronutrient Data Structure
struct MicronutrientData: Codable, Equatable, Hashable {
    /// Stored as milligrams (mg) for consistency. All conversions handled through Measurement API
    private(set) var values: [String: Double] = [:]
    
    // MARK: - Subscript Access
    
    /// Get/set nutrient value as raw double (in the nutrient's native unit)
    subscript(nutrient: Micronutrient) -> Double {
        get { values[nutrient.rawValue] ?? 0 }
        set { values[nutrient.rawValue] = newValue }
    }
    
    /// Get/set nutrient value as Measurement for type safety
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
    
    // MARK: - Calculations
    
    /// Calculate percentage of daily value for a nutrient
    func percentage(for nutrient: Micronutrient) -> Double {
        let currentValue = self[measurement: nutrient]
        let dailyValue = nutrient.dailyValueMeasurement
        
        // Convert both to same unit for comparison
        let currentInDVUnit = currentValue.converted(to: dailyValue.unit)
        guard dailyValue.value > 0 else { return 0 }
        
        return (currentInDVUnit.value / dailyValue.value) * 100
    }
    
    /// Get all non-zero nutrients
    func nonZeroNutrients() -> [Micronutrient] {
        Micronutrient.allCases.filter { self[$0] > 0 }
    }
    
    // MARK: - Operators
    
    static func + (lhs: MicronutrientData, rhs: MicronutrientData) -> MicronutrientData {
        var result = MicronutrientData()
        let allKeys = Set(lhs.values.keys).union(rhs.values.keys)
        
        for key in allKeys {
            result.values[key] = (lhs.values[key] ?? 0) + (rhs.values[key] ?? 0)
        }
        
        return result
    }
    
    static func += (lhs: inout MicronutrientData, rhs: MicronutrientData) {
        for (key, value) in rhs.values {
            lhs.values[key] = (lhs.values[key] ?? 0) + value
        }
    }
    
    // MARK: - HealthKit Integration
    
    /// Create HealthKit samples for all tracked nutrients
    @available(iOS 8.0, *)
    func createHealthKitSamples(startDate: Date, endDate: Date) -> [(HKQuantityType, HKQuantitySample)] {
        var samples: [(HKQuantityType, HKQuantitySample)] = []
        
        for nutrient in Micronutrient.allCases {
            guard let identifier = nutrient.healthKitIdentifier,
                  let quantityType = HKQuantityType.quantityType(forIdentifier: identifier),
                  self[nutrient] > 0 else {
                continue
            }
            
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

// MARK: - USDA Nutrient Mapping
struct USDANutrientMapper {
    /// Maps USDA nutrient names to our Micronutrient enum with proper unit conversion
    static func mapNutrient(_ usdaNutrient: USDANutrient) -> (Micronutrient, Measurement<UnitMass>)? {
        let name = usdaNutrient.nutrientName.lowercased()
        let value = usdaNutrient.value ?? 0
        guard value > 0 else { return nil }
        
        let unitName = usdaNutrient.unitName?.uppercased() ?? ""
        
        // Determine source unit
        let sourceUnit: UnitMass
        switch unitName {
        case "G": sourceUnit = .grams
        case "MG": sourceUnit = .milligrams
        case "UG", "MCG", "µG": sourceUnit = .micrograms
        case "IU": sourceUnit = .micrograms // Approximate conversion
        default: sourceUnit = .milligrams
        }
        
        // Identify nutrient and return with measurement
        if let nutrient = identifyNutrient(from: name) {
            let measurement = Measurement(value: value, unit: sourceUnit)
            return (nutrient, measurement)
        }
        
        return nil
    }
    
    private static func identifyNutrient(from name: String) -> Micronutrient? {
        // Vitamins
        if name.contains("vitamin a") || name.contains("retinol") {
            return .vitaminA
        } else if name.contains("vitamin c") || name.contains("ascorbic acid") {
            return .vitaminC
        } else if name.contains("vitamin d") || name.contains("cholecalciferol") {
            return .vitaminD
        } else if name.contains("vitamin e") || name.contains("alpha-tocopherol") {
            return .vitaminE
        } else if name.contains("menaquinone") || name.contains("vitamin k2") || name.contains("mk-") {
            return .vitaminK2
        } else if name.contains("phylloquinone") || name.contains("vitamin k1") || (name.contains("vitamin k") && !name.contains("menaquinone")) {
            return .vitaminK1
        } else if name.contains("thiamin") || name == "vitamin b-1" {
            return .thiamin
        } else if name.contains("riboflavin") || name == "vitamin b-2" {
            return .riboflavin
        } else if name.contains("niacin") || name == "vitamin b-3" {
            return .niacin
        } else if name.contains("pantothenic") {
            return .pantothenicAcid
        } else if name.contains("vitamin b-6") || name.contains("pyridoxine") {
            return .vitaminB6
        } else if name.contains("biotin") {
            return .biotin
        } else if name.contains("folate") || name.contains("folic acid") {
            return .folate
        } else if name.contains("vitamin b-12") || name.contains("cobalamin") {
            return .vitaminB12
        } else if name.contains("choline") {
            return .choline
        }
        // Minerals
        else if name.contains("calcium") && !name.contains("pantothen") {
            return .calcium
        } else if name.contains("chromium") {
            return .chromium
        } else if name.contains("copper") {
            return .copper
        } else if name.contains("iodine") {
            return .iodine
        } else if name.contains("iron") {
            return .iron
        } else if name.contains("magnesium") {
            return .magnesium
        } else if name.contains("manganese") {
            return .manganese
        } else if name.contains("molybdenum") {
            return .molybdenum
        } else if name.contains("phosphorus") {
            return .phosphorus
        } else if name.contains("potassium") {
            return .potassium
        } else if name.contains("selenium") {
            return .selenium
        } else if name.contains("sodium") {
            return .sodium
        } else if name.contains("zinc") {
            return .zinc
        }
        // Other nutrients
        else if name.contains("fatty acids, total omega-3") || name.contains("18:3") {
            return .omega3
        } else if name.contains("fatty acids, total omega-6") || name.contains("18:2") {
            return .omega6
        } else if name.contains("fatty acids, total saturated") {
            return .saturatedFat
        } else if name.contains("fatty acids, total trans") {
            return .transFat
        } else if name.contains("cholesterol") {
            return .cholesterol
        } else if name.contains("sugars, total") || name == "sugars, added" {
            return .sugar
        }
        
        return nil
    }
}

// MARK: - Extension for USDAFood
extension USDAFood {
    /// Extract micronutrients using Measurement API for type safety
    func extractMicronutrients() -> MicronutrientData {
        var data = MicronutrientData()
        
        guard let nutrients = foodNutrients else { return data }
        
        for nutrient in nutrients {
            if let (micronutrient, measurement) = USDANutrientMapper.mapNutrient(nutrient) {
                // Convert measurement to the nutrient's native unit and store
                let converted = measurement.converted(to: micronutrient.measurementUnit as! UnitMass)
                data[micronutrient] = converted.value
            }
        }
        
        return data
    }
}

