import Foundation
import CoreData

// MARK: - USDA API Models
struct USDAFoodSearchResult: Decodable {
    let foods: [USDAFood]
}

struct USDAFood: Decodable {
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

// MARK: - Core Data Entities
@objc(FoodEntryEntity)
public class FoodEntryEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var calories: Double
    @NSManaged public var protein: Double
    @NSManaged public var fat: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fiber: Double
    @NSManaged public var quantityGrams: Double
    @NSManaged public var source: String?
    @NSManaged public var fdcId: Int64
    @NSManaged public var date: Date?
    @NSManaged public var dailyLog: DailyLogEntity?
}

@objc(DailyLogEntity)
public class DailyLogEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var goalCalories: Double
    @NSManaged public var goalProtein: Double
    @NSManaged public var goalFat: Double
    @NSManaged public var goalCarbs: Double
    @NSManaged public var goalFiber: Double
    @NSManaged public var entries: NSSet?
    
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
}

// MARK: - Extensions
extension UserDefaults {
    func double(forKey key: String, default defaultValue: Double) -> Double {
        let v = double(forKey: key)
        return v == 0 ? defaultValue : v
    }
}
