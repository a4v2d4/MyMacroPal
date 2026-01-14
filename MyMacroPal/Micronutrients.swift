import Foundation

// MARK: - Micronutrient Definition
enum Micronutrient: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    // Vitamins
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
    
    // Minerals
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
    
    // Other nutrients
    case omega3 = "Omega-3"
    case omega6 = "Omega-6"
    case saturatedFat = "Saturated Fat"
    case transFat = "Trans Fat"
    case cholesterol = "Cholesterol"
    case sugar = "Sugar"
    
    var category: MicronutrientCategory {
        switch self {
        case .vitaminA, .vitaminC, .vitaminD, .vitaminE, .vitaminK1, .vitaminK2, .thiamin, .riboflavin, .niacin, .pantothenicAcid, .vitaminB6, .biotin, .folate, .vitaminB12, .choline:
            return .vitamins
        case .calcium, .chromium, .copper, .iodine, .iron, .magnesium, .manganese, .molybdenum, .phosphorus, .potassium, .selenium, .sodium, .zinc:
            return .minerals
        case .omega3, .omega6, .saturatedFat, .transFat, .cholesterol, .sugar:
            return .other
        }
    }
    
    /// Daily Value (DV) based on FDA standards for adults
    var dailyValue: Double {
        switch self {
        // Vitamins (in various units - stored as base units)
        case .vitaminA: return 900 // mcg RAE
        case .vitaminC: return 90 // mg
        case .vitaminD: return 20 // mcg (800 IU)
        case .vitaminE: return 15 // mg
        case .vitaminK1: return 120 // mcg (phylloquinone)
        case .vitaminK2: return 90 // mcg (menaquinone, optimal for bone/cardiovascular health)
        case .thiamin: return 1.2 // mg
        case .riboflavin: return 1.3 // mg
        case .niacin: return 16 // mg
        case .pantothenicAcid: return 5 // mg
        case .vitaminB6: return 1.7 // mg
        case .biotin: return 30 // mcg
        case .folate: return 400 // mcg DFE
        case .vitaminB12: return 2.4 // mcg
        case .choline: return 550 // mg
            
        // Minerals
        case .calcium: return 1300 // mg
        case .chromium: return 35 // mcg (glucose metabolism, insulin sensitivity)
        case .copper: return 0.9 // mg
        case .iodine: return 150 // mcg (thyroid function)
        case .iron: return 18 // mg
        case .magnesium: return 420 // mg
        case .manganese: return 2.3 // mg
        case .molybdenum: return 45 // mcg (enzyme cofactor)
        case .phosphorus: return 1250 // mg
        case .potassium: return 4700 // mg
        case .selenium: return 55 // mcg
        case .sodium: return 2300 // mg
        case .zinc: return 11 // mg
            
        // Other nutrients
        case .omega3: return 1600 // mg (ALA)
        case .omega6: return 17000 // mg (linoleic acid)
        case .saturatedFat: return 20 // g (limit, not goal)
        case .transFat: return 0 // g (limit)
        case .cholesterol: return 300 // mg (limit)
        case .sugar: return 50 // g (limit, based on 10% of 2000 cal)
        }
    }
    
    var unit: String {
        switch self {
        case .vitaminA, .vitaminD, .vitaminK1, .vitaminK2, .biotin, .folate, .vitaminB12, .chromium, .iodine, .molybdenum, .selenium:
            return "mcg"
        case .vitaminC, .vitaminE, .thiamin, .riboflavin, .niacin, .pantothenicAcid, .vitaminB6, .choline,
             .calcium, .copper, .iron, .magnesium, .manganese, .phosphorus, .potassium, .sodium, .zinc,
             .omega3, .omega6, .cholesterol:
            return "mg"
        case .saturatedFat, .transFat, .sugar:
            return "g"
        }
    }
    
    var isLimitNutrient: Bool {
        switch self {
        case .saturatedFat, .transFat, .cholesterol, .sugar, .sodium:
            return true
        default:
            return false
        }
    }
}

enum MicronutrientCategory: String, CaseIterable {
    case vitamins = "Vitamins"
    case minerals = "Minerals"
    case other = "Other Nutrients"
}

// MARK: - Micronutrient Data Structure
struct MicronutrientData: Codable {
    var values: [String: Double] = [:]
    
    subscript(nutrient: Micronutrient) -> Double {
        get { values[nutrient.rawValue] ?? 0 }
        set { values[nutrient.rawValue] = newValue }
    }
    
    func percentage(for nutrient: Micronutrient) -> Double {
        let value = self[nutrient]
        guard nutrient.dailyValue > 0 else { return 0 }
        return (value / nutrient.dailyValue) * 100
    }
    
    static func + (lhs: MicronutrientData, rhs: MicronutrientData) -> MicronutrientData {
        var result = MicronutrientData()
        let allKeys = Set(lhs.values.keys).union(rhs.values.keys)
        for key in allKeys {
            result.values[key] = (lhs.values[key] ?? 0) + (rhs.values[key] ?? 0)
        }
        return result
    }
}

// MARK: - USDA Nutrient Mapping
struct USDANutrientMapper {
    /// Maps USDA nutrient IDs and names to our Micronutrient enum
    /// Based on USDA FoodData Central nutrient database
    static func mapNutrient(_ usdaNutrient: USDANutrient) -> (Micronutrient, Double)? {
        let name = usdaNutrient.nutrientName.lowercased()
        let value = usdaNutrient.value ?? 0
        let unit = usdaNutrient.unitName?.uppercased() ?? ""
        
        // Vitamins
        if name.contains("vitamin a") || name.contains("retinol") {
            return (.vitaminA, convertToMcg(value, from: unit))
        } else if name.contains("vitamin c") || name.contains("ascorbic acid") {
            return (.vitaminC, convertToMg(value, from: unit))
        } else if name.contains("vitamin d") || name.contains("cholecalciferol") {
            return (.vitaminD, convertToMcg(value, from: unit))
        } else if name.contains("vitamin e") || name.contains("alpha-tocopherol") {
            return (.vitaminE, convertToMg(value, from: unit))
        } else if name.contains("menaquinone") || name.contains("vitamin k2") || name.contains("mk-") {
            return (.vitaminK2, convertToMcg(value, from: unit))
        } else if name.contains("phylloquinone") || name.contains("vitamin k1") || (name.contains("vitamin k") && !name.contains("menaquinone")) {
            return (.vitaminK1, convertToMcg(value, from: unit))
        } else if name.contains("thiamin") || name == "vitamin b-1" {
            return (.thiamin, convertToMg(value, from: unit))
        } else if name.contains("riboflavin") || name == "vitamin b-2" {
            return (.riboflavin, convertToMg(value, from: unit))
        } else if name.contains("niacin") || name == "vitamin b-3" {
            return (.niacin, convertToMg(value, from: unit))
        } else if name.contains("pantothenic") {
            return (.pantothenicAcid, convertToMg(value, from: unit))
        } else if name.contains("vitamin b-6") || name.contains("pyridoxine") {
            return (.vitaminB6, convertToMg(value, from: unit))
        } else if name.contains("biotin") {
            return (.biotin, convertToMcg(value, from: unit))
        } else if name.contains("folate") || name.contains("folic acid") {
            return (.folate, convertToMcg(value, from: unit))
        } else if name.contains("vitamin b-12") || name.contains("cobalamin") {
            return (.vitaminB12, convertToMcg(value, from: unit))
        } else if name.contains("choline") {
            return (.choline, convertToMg(value, from: unit))
        }
        // Minerals
        else if name.contains("calcium") && !name.contains("pantothen") {
            return (.calcium, convertToMg(value, from: unit))
        } else if name.contains("chromium") {
            return (.chromium, convertToMcg(value, from: unit))
        } else if name.contains("copper") {
            return (.copper, convertToMg(value, from: unit))
        } else if name.contains("iodine") {
            return (.iodine, convertToMcg(value, from: unit))
        } else if name.contains("iron") {
            return (.iron, convertToMg(value, from: unit))
        } else if name.contains("magnesium") {
            return (.magnesium, convertToMg(value, from: unit))
        } else if name.contains("manganese") {
            return (.manganese, convertToMg(value, from: unit))
        } else if name.contains("molybdenum") {
            return (.molybdenum, convertToMcg(value, from: unit))
        } else if name.contains("phosphorus") {
            return (.phosphorus, convertToMg(value, from: unit))
        } else if name.contains("potassium") {
            return (.potassium, convertToMg(value, from: unit))
        } else if name.contains("selenium") {
            return (.selenium, convertToMcg(value, from: unit))
        } else if name.contains("sodium") {
            return (.sodium, convertToMg(value, from: unit))
        } else if name.contains("zinc") {
            return (.zinc, convertToMg(value, from: unit))
        }
        // Other nutrients
        else if name.contains("fatty acids, total omega-3") || name.contains("18:3") {
            return (.omega3, convertToMg(value, from: unit))
        } else if name.contains("fatty acids, total omega-6") || name.contains("18:2") {
            return (.omega6, convertToMg(value, from: unit))
        } else if name.contains("fatty acids, total saturated") {
            return (.saturatedFat, convertToG(value, from: unit))
        } else if name.contains("fatty acids, total trans") {
            return (.transFat, convertToG(value, from: unit))
        } else if name.contains("cholesterol") {
            return (.cholesterol, convertToMg(value, from: unit))
        } else if name.contains("sugars, total") || name == "sugars, added" {
            return (.sugar, convertToG(value, from: unit))
        }
        
        return nil
    }
    
    // Unit conversion helpers
    private static func convertToMcg(_ value: Double, from unit: String) -> Double {
        switch unit {
        case "UG", "MCG": return value
        case "MG": return value * 1000
        case "G": return value * 1_000_000
        case "IU": return value * 0.3 // Approximate for vitamin A/D
        default: return value
        }
    }
    
    private static func convertToMg(_ value: Double, from unit: String) -> Double {
        switch unit {
        case "MG": return value
        case "G": return value * 1000
        case "UG", "MCG": return value / 1000
        default: return value
        }
    }
    
    private static func convertToG(_ value: Double, from unit: String) -> Double {
        switch unit {
        case "G": return value
        case "MG": return value / 1000
        case "UG", "MCG": return value / 1_000_000
        default: return value
        }
    }
}

// MARK: - Extension for USDAFood
extension USDAFood {
    func extractMicronutrients() -> MicronutrientData {
        var data = MicronutrientData()
        
        guard let nutrients = foodNutrients else { return data }
        
        for nutrient in nutrients {
            if let (micronutrient, value) = USDANutrientMapper.mapNutrient(nutrient) {
                data[micronutrient] = value
            }
        }
        
        return data
    }
}

