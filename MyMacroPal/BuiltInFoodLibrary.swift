import Foundation

/// Built-in foods loaded from JSON file
/// Micronutrients: Focused on 8 key nutrients for body recomposition (from USDA data)
enum BuiltInFoodLibrary {
    
    // MARK: - JSON Structures
    
    private struct BuiltInFoodsJSON: Codable {
        let foods: [FoodJSON]
    }
    
    private struct FoodJSON: Codable {
        let name: String
        let gramsPerServing: Double
        let caloriesPerServing: Double
        let proteinPerServing: Double
        let fatPerServing: Double
        let carbsPerServing: Double
        let fiberPerServing: Double
        let micronutrients: MicronutrientJSON?
        
        struct MicronutrientJSON: Codable {
            let magnesium: Double?
            let zinc: Double?
            let iron: Double?
            let potassium: Double?
            let sodium: Double?
            let vitaminD: Double?
            let vitaminK2: Double?
            let chromium: Double?
            
            func toMicronutrientData() -> MicronutrientData {
                var data = MicronutrientData()
                if let magnesium = magnesium { data[.magnesium] = magnesium }
                if let zinc = zinc { data[.zinc] = zinc }
                if let iron = iron { data[.iron] = iron }
                if let potassium = potassium { data[.potassium] = potassium }
                if let sodium = sodium { data[.sodium] = sodium }
                if let vitaminD = vitaminD { data[.vitaminD] = vitaminD }
                if let vitaminK2 = vitaminK2 { data[.vitaminK2] = vitaminK2 }
                if let chromium = chromium { data[.chromium] = chromium }
                return data
            }
        }
        
        func toLibraryFood() -> LibraryFood {
            return LibraryFood(
                name: name,
                gramsPerServing: gramsPerServing,
                caloriesPerServing: caloriesPerServing,
                proteinPerServing: proteinPerServing,
                fatPerServing: fatPerServing,
                carbsPerServing: carbsPerServing,
                fiberPerServing: fiberPerServing,
                micronutrientsPerServing: micronutrients?.toMicronutrientData()
            )
        }
    }
    
    // MARK: - Loading
    
    /// Cached foods loaded from JSON
    private static var _cachedFoods: [LibraryFood]?
    
    /// Load built-in foods from JSON file
    static var foods: [LibraryFood] {
        // Return cached if available
        if let cached = _cachedFoods {
            return cached
        }
        
        // Load from JSON
        guard let url = Bundle.main.url(forResource: "BuiltInFoods", withExtension: "json") else {
            print("⚠️ BuiltInFoods.json not found in bundle. Using empty array.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let json = try decoder.decode(BuiltInFoodsJSON.self, from: data)
            let foods = json.foods.map { $0.toLibraryFood() }
            
            // Cache for future use
            _cachedFoods = foods
            
            print("✅ Loaded \(foods.count) built-in foods from JSON")
            return foods
        } catch {
            print("❌ Error loading BuiltInFoods.json: \(error)")
            return []
        }
    }
    
    /// Reload foods from JSON (useful for testing or updates)
    static func reload() {
        _cachedFoods = nil
        _ = foods // Trigger reload
    }
}
