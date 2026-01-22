import Foundation
import CoreData

// MARK: - UI Helper Models

// Helper struct to track add food context
struct AddFoodContext: Identifiable {
    let id = UUID()
    let targetMeal: MealEntity?
    let targetDate: Date
}

// MARK: - USDA API Models
struct USDAFoodSearchResult: Decodable {
    let foods: [USDAFood]
}

struct USDAFood: Decodable, Identifiable {
    var id: Int { fdcId }
    let fdcId: Int
    let description: String
    let dataType: String?
    let foodNutrients: [USDANutrient]?
    let foodPortions: [USDAPortion]?
}

struct USDANutrient: Decodable {
    let nutrientName: String
    let value: Double?
    let unitName: String?
}

struct USDAPortion: Decodable {
    let measureUnitName: String?
    let gramWeight: Double?
}

// MARK: - Extensions
extension Double {
    /// Returns the value if it is finite and non-negative; otherwise returns 0.
    var sanitizedNonNegativeFinite: Double {
        if self.isFinite && self >= 0 { return self }
        return 0
    }
}

extension UserDefaults {
    func double(forKey key: String, default defaultValue: Double) -> Double {
        let v = double(forKey: key)
        // Treat zero, negatives, and non-finite values as unset and fall back to default
        guard v.isFinite, v > 0 else { return defaultValue }
        return v
    }
}

// MARK: - Core Data Entity Extensions
extension FoodEntryEntity {
    var totalCalories: Double {
        return calories
    }
    
    var totalProtein: Double {
        return protein
    }
    
    var totalFat: Double {
        return fat
    }
    
    var totalCarbs: Double {
        return carbs
    }
    
    var totalFiber: Double {
        return fiber
    }
    
    var micronutrients: MicronutrientData {
        get {
            guard let data = micronutrientsData else { return MicronutrientData() }
            let decoder = JSONDecoder()
            return (try? decoder.decode(MicronutrientData.self, from: data)) ?? MicronutrientData()
        }
        set {
            let encoder = JSONEncoder()
            micronutrientsData = try? encoder.encode(newValue)
        }
    }
}

extension DailyLogEntity {
    var totalCalories: Double {
        guard let entries = entries as? Set<FoodEntryEntity> else { return 0 }
        return entries.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        guard let entries = entries as? Set<FoodEntryEntity> else { return 0 }
        return entries.reduce(0) { $0 + $1.protein }
    }
    
    var totalFat: Double {
        guard let entries = entries as? Set<FoodEntryEntity> else { return 0 }
        return entries.reduce(0) { $0 + $1.fat }
    }
    
    var totalCarbs: Double {
        guard let entries = entries as? Set<FoodEntryEntity> else { return 0 }
        return entries.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFiber: Double {
        guard let entries = entries as? Set<FoodEntryEntity> else { return 0 }
        return entries.reduce(0) { $0 + $1.fiber }
    }
    
    var totalMicronutrients: MicronutrientData {
        guard let entries = entries as? Set<FoodEntryEntity> else { return MicronutrientData() }
        return entries.reduce(MicronutrientData()) { $0 + $1.micronutrients }
    }
}

// MARK: - Meal Entity Extensions
extension MealEntity {
    var foodEntries: [FoodEntryEntity] {
        let set = entries as? Set<FoodEntryEntity> ?? []
        return set.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }
    
    var totalCalories: Double {
        foodEntries.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        foodEntries.reduce(0) { $0 + $1.protein }
    }
    
    var totalFat: Double {
        foodEntries.reduce(0) { $0 + $1.fat }
    }
    
    var totalCarbs: Double {
        foodEntries.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFiber: Double {
        foodEntries.reduce(0) { $0 + $1.fiber }
    }
}

// MARK: - Meal Library Models
struct LibraryMeal: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [LibraryMealItem]
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, items: [LibraryMealItem]) {
        self.id = id
        self.name = name
        self.items = items
        self.createdAt = Date()
    }
}

struct LibraryMealItem: Identifiable, Codable {
    let id: UUID
    var foodName: String
    var grams: Double
    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double
    var fiber: Double
    var micronutrients: MicronutrientData?
    
    init(id: UUID = UUID(), foodName: String, grams: Double, calories: Double, protein: Double, fat: Double, carbs: Double, fiber: Double, micronutrients: MicronutrientData? = nil) {
        self.id = id
        self.foodName = foodName
        self.grams = grams
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.fiber = fiber
        self.micronutrients = micronutrients
    }
}
