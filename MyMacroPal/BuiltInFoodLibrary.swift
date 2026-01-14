import Foundation

/// Built-in foods that ship with the app, derived from markdown in `BuiltInFoods/`.
/// Values are per labeled serving. `gramsPerServing` is used for scaling when using grams/servings.
/// Micronutrients: Focused on 8 key nutrients for body recomposition (per serving, from USDA data)
enum BuiltInFoodLibrary {
    
    /// Helper to create micronutrient data for body recomposition essentials
    private static func micros(
        magnesium: Double? = nil,
        zinc: Double? = nil,
        iron: Double? = nil,
        potassium: Double? = nil,
        sodium: Double? = nil,
        vitaminD: Double? = nil,
        vitaminK2: Double? = nil,
        chromium: Double? = nil
    ) -> MicronutrientData {
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
    
    static let foods: [LibraryFood] = [
        // MARK: Oils
        LibraryFood(
            name: "Olive Oil",
            gramsPerServing: 14, // ~1 tbsp mass
            caloriesPerServing: 120,
            proteinPerServing: 0,
            fatPerServing: 13,
            carbsPerServing: 0,
            fiberPerServing: 0
        ),

        // MARK: Dairy
        LibraryFood(
            name: "Low Fat Greek Yogurt",
            gramsPerServing: 170,
            caloriesPerServing: 150,
            proteinPerServing: 16,
            fatPerServing: 6,
            carbsPerServing: 7,
            fiberPerServing: 0,
            micronutrientsPerServing: micros(
                magnesium: 19.0,     // Muscle recovery
                zinc: 0.9,           // Protein synthesis
                potassium: 220.0,    // Muscle function
                sodium: 60.0
            )
        ),

        // MARK: Grains
        LibraryFood(
            name: "Dave’s 21 Whole Grains & Seeds (Thin-Sliced)",
            gramsPerServing: 28,
            caloriesPerServing: 60,
            proteinPerServing: 3,
            fatPerServing: 1,
            carbsPerServing: 14,
            fiberPerServing: 3
        ),
        LibraryFood(
            name: "Sourdough Bread",
            gramsPerServing: 38,
            caloriesPerServing: 113,
            proteinPerServing: 4,
            fatPerServing: 1,
            carbsPerServing: 22,
            fiberPerServing: 0
        ),
        LibraryFood(
            name: "White Rice (Uncooked)",
            gramsPerServing: 185,
            caloriesPerServing: 640,
            proteinPerServing: 12,
            fatPerServing: 1.9,
            carbsPerServing: 144,
            fiberPerServing: 2
        ),
        LibraryFood(
            name: "White Rice (Cooked)",
            gramsPerServing: 158,
            caloriesPerServing: 205,
            proteinPerServing: 4.3,
            fatPerServing: 0.44,
            carbsPerServing: 44.5,
            fiberPerServing: 0.6
        ),

        // MARK: Spreads & Nut Butters
        LibraryFood(
            name: "Organic No Stir Crunchy Dark Roasted Peanut Butter",
            gramsPerServing: 32,
            caloriesPerServing: 190,
            proteinPerServing: 8,
            fatPerServing: 17,
            carbsPerServing: 5,
            fiberPerServing: 3
        ),

        // MARK: Sweeteners
        LibraryFood(
            name: "Honey",
            gramsPerServing: 21,
            caloriesPerServing: 60,
            proteinPerServing: 0,
            fatPerServing: 0,
            carbsPerServing: 17,
            fiberPerServing: 0
        ),

        // MARK: Seeds
        LibraryFood(
            name: "Chia Seeds",
            gramsPerServing: 30,
            caloriesPerServing: 160,
            proteinPerServing: 6,
            fatPerServing: 10,
            carbsPerServing: 11,
            fiberPerServing: 10,
            micronutrientsPerServing: micros(
                magnesium: 95.0,     // VERY HIGH - muscle recovery
                zinc: 1.4,
                iron: 2.3,           // HIGH - oxygen transport
                potassium: 120.0,
                sodium: 5.0
            )
        ),

        // MARK: Eggs
        LibraryFood(
            name: "Large Egg",
            gramsPerServing: 50,
            caloriesPerServing: 70,
            proteinPerServing: 6,
            fatPerServing: 5,
            carbsPerServing: 0,
            fiberPerServing: 0,
            micronutrientsPerServing: micros(
                zinc: 0.65,          // Hormone support
                iron: 0.9,           // Oxygen transport
                potassium: 69.0,
                sodium: 71.0,
                vitaminD: 1.1        // Bone health & testosterone
            )
        ),
        LibraryFood(
            name: "Large Egg White",
            gramsPerServing: 33,
            caloriesPerServing: 17,
            proteinPerServing: 3.6,
            fatPerServing: 0.05,
            carbsPerServing: 0.24,
            fiberPerServing: 0,
            micronutrientsPerServing: micros(
                potassium: 54.0,
                sodium: 55.0
            )
        ),

        // MARK: Deli Meat
        LibraryFood(
            name: "Turkey Breast Deli Meat",
            gramsPerServing: 55,
            caloriesPerServing: 60,
            proteinPerServing: 14,
            fatPerServing: 0,
            carbsPerServing: 0,
            fiberPerServing: 0
        ),

        // MARK: Supplements
        LibraryFood(
            name: "Whey Protein Shake Powder",
            gramsPerServing: 35,
            caloriesPerServing: 130,
            proteinPerServing: 30,
            fatPerServing: 0.5,
            carbsPerServing: 0.8,
            fiberPerServing: 0,
            micronutrientsPerServing: micros(
                magnesium: 35.0,     // Recovery
                zinc: 2.5,           // Protein synthesis
                iron: 0.5,
                potassium: 280.0,
                sodium: 105.0
            )
        ),

        // MARK: Vegetables (Raw)
        LibraryFood(
            name: "Yellow Potato (raw)",
            gramsPerServing: 150,
            caloriesPerServing: 110,
            proteinPerServing: 3,
            fatPerServing: 0,
            carbsPerServing: 26,
            fiberPerServing: 2,
            micronutrientsPerServing: micros(
                magnesium: 34.5,
                iron: 1.2,
                potassium: 634.0,    // HIGH - prevents water retention
                sodium: 9.0,
                chromium: 1.5        // Glucose metabolism
            )
        ),
        LibraryFood(
            name: "Red Potato (raw)",
            gramsPerServing: 150,
            caloriesPerServing: 110,
            proteinPerServing: 3,
            fatPerServing: 0,
            carbsPerServing: 26,
            fiberPerServing: 2,
            micronutrientsPerServing: micros(
                magnesium: 34.5,
                iron: 1.2,
                potassium: 634.0,    // HIGH
                sodium: 9.0,
                chromium: 1.5
            )
        ),
        LibraryFood(
            name: "Sweet Potato (raw)",
            gramsPerServing: 130,
            caloriesPerServing: 112,
            proteinPerServing: 2,
            fatPerServing: 0,
            carbsPerServing: 26,
            fiberPerServing: 4,
            micronutrientsPerServing: micros(
                magnesium: 32.5,
                iron: 0.8,
                potassium: 429.0,
                sodium: 72.0
            )
        ),
        LibraryFood(
            name: "Broccoli (raw)",
            gramsPerServing: 90,
            caloriesPerServing: 25,
            proteinPerServing: 3,
            fatPerServing: 0,
            carbsPerServing: 5,
            fiberPerServing: 2,
            micronutrientsPerServing: micros(
                magnesium: 19.0,
                zinc: 0.4,
                iron: 0.7,
                potassium: 288.0,
                sodium: 30.0,
                chromium: 1.5        // Insulin sensitivity
            )
        ),
        LibraryFood(
            name: "Broccolini (raw)",
            gramsPerServing: 85,
            caloriesPerServing: 25,
            proteinPerServing: 3,
            fatPerServing: 0,
            carbsPerServing: 4,
            fiberPerServing: 2,
            micronutrientsPerServing: micros(
                magnesium: 18.0,
                zinc: 0.4,
                iron: 0.7,
                potassium: 272.0,
                sodium: 28.0
            )
        ),
        LibraryFood(
            name: "Spinach (raw)",
            gramsPerServing: 30,
            caloriesPerServing: 7,
            proteinPerServing: 1,
            fatPerServing: 0,
            carbsPerServing: 1,
            fiberPerServing: 1,
            micronutrientsPerServing: micros(
                magnesium: 24.0,     // HIGH per gram - muscle relaxation
                zinc: 0.16,
                iron: 0.8,           // Good iron source
                potassium: 168.0,
                sodium: 24.0
            )
        ),
        LibraryFood(
            name: "Zucchini (raw)",
            gramsPerServing: 120,
            caloriesPerServing: 20,
            proteinPerServing: 1,
            fatPerServing: 0,
            carbsPerServing: 4,
            fiberPerServing: 1
        ),
        LibraryFood(
            name: "Asparagus (raw)",
            gramsPerServing: 135,
            caloriesPerServing: 27,
            proteinPerServing: 3,
            fatPerServing: 0,
            carbsPerServing: 5,
            fiberPerServing: 3
        ),

        // MARK: Fruits (Raw)
        LibraryFood(
            name: "Blueberries",
            gramsPerServing: 150,
            caloriesPerServing: 85,
            proteinPerServing: 1,
            fatPerServing: 0,
            carbsPerServing: 21,
            fiberPerServing: 4,
            micronutrientsPerServing: micros(
                magnesium: 9.0,
                iron: 0.4,
                potassium: 116.0,
                sodium: 2.0
            )
        ),
        LibraryFood(
            name: "Raspberries",
            gramsPerServing: 125,
            caloriesPerServing: 65,
            proteinPerServing: 1,
            fatPerServing: 1,
            carbsPerServing: 15,
            fiberPerServing: 8,
            micronutrientsPerServing: micros(
                magnesium: 27.0,     // Good magnesium source
                zinc: 0.5,
                iron: 0.9,
                potassium: 186.0,
                sodium: 1.0
            )
        ),
        LibraryFood(
            name: "Honeycrisp Apple",
            gramsPerServing: 180,
            caloriesPerServing: 95,
            proteinPerServing: 0,
            fatPerServing: 0,
            carbsPerServing: 25,
            fiberPerServing: 4,
            micronutrientsPerServing: micros(
                magnesium: 9.0,
                iron: 0.2,
                potassium: 195.0,
                sodium: 2.0
            )
        ),
        LibraryFood(
            name: "Banana",
            gramsPerServing: 120,
            caloriesPerServing: 105,
            proteinPerServing: 1,
            fatPerServing: 0,
            carbsPerServing: 27,
            fiberPerServing: 3,
            micronutrientsPerServing: micros(
                magnesium: 32.0,     // Good magnesium
                zinc: 0.2,
                iron: 0.3,
                potassium: 430.0,    // HIGH - prevents cramping
                sodium: 1.0
            )
        ),
        LibraryFood(
            name: "Orange",
            gramsPerServing: 155,
            caloriesPerServing: 62,
            proteinPerServing: 1,
            fatPerServing: 0,
            carbsPerServing: 15,
            fiberPerServing: 3
        ),
        LibraryFood(
            name: "Red Seedless Grapes",
            gramsPerServing: 150,
            caloriesPerServing: 104,
            proteinPerServing: 1,
            fatPerServing: 0,
            carbsPerServing: 27,
            fiberPerServing: 1
        ),
        LibraryFood(
            name: "Avocado",
            gramsPerServing: 200,
            caloriesPerServing: 320,
            proteinPerServing: 4,
            fatPerServing: 29,
            carbsPerServing: 17,
            fiberPerServing: 14,
            micronutrientsPerServing: micros(
                magnesium: 58.0,     // HIGH - recovery
                zinc: 1.3,
                iron: 1.1,
                potassium: 970.0,    // VERY HIGH - prevents cramping
                sodium: 14.0
            )
        ),

        // MARK: Meat (Raw)
        LibraryFood(
            name: "Chicken Breast (Skinless, raw)",
            gramsPerServing: 100,
            caloriesPerServing: 165,
            proteinPerServing: 31,
            fatPerServing: 4,
            carbsPerServing: 0,
            fiberPerServing: 0,
            micronutrientsPerServing: micros(
                magnesium: 29.0,     // ATP production
                zinc: 0.9,           // Protein synthesis
                iron: 0.7,
                potassium: 256.0,    // Muscle contraction
                sodium: 63.0
            )
        ),
        LibraryFood(
            name: "Sockeye Salmon (raw)",
            gramsPerServing: 100,
            caloriesPerServing: 216,
            proteinPerServing: 27,
            fatPerServing: 11,
            carbsPerServing: 0,
            fiberPerServing: 0,
            micronutrientsPerServing: micros(
                magnesium: 29.0,     // Recovery
                zinc: 0.6,
                iron: 0.5,
                potassium: 460.0,    // HIGH - prevents cramping
                sodium: 59.0,
                vitaminD: 16.3       // HIGH - hormone health
            )
        ),
        LibraryFood(
            name: "93/7 Ground Beef (raw)",
            gramsPerServing: 100,
            caloriesPerServing: 152,
            proteinPerServing: 22,
            fatPerServing: 7,
            carbsPerServing: 0,
            fiberPerServing: 0,
            micronutrientsPerServing: micros(
                magnesium: 21.0,
                zinc: 6.3,           // HIGH - testosterone support
                iron: 2.5,           // HIGH - oxygen transport
                potassium: 330.0,
                sodium: 66.0
            )
        ),
        LibraryFood(
            name: "Strip Steak (raw)",
            gramsPerServing: 100,
            caloriesPerServing: 155,
            proteinPerServing: 26,
            fatPerServing: 5,
            carbsPerServing: 0,
            fiberPerServing: 0
        ),
        LibraryFood(
            name: "Chicken Thigh (Skinless, raw)",
            gramsPerServing: 100,
            caloriesPerServing: 209,
            proteinPerServing: 26,
            fatPerServing: 11,
            carbsPerServing: 0,
            fiberPerServing: 0
        ),
        LibraryFood(
            name: "Chicken Drumstick (Skinless, raw)",
            gramsPerServing: 100,
            caloriesPerServing: 172,
            proteinPerServing: 28,
            fatPerServing: 6,
            carbsPerServing: 0,
            fiberPerServing: 0
        ),
        LibraryFood(
            name: "Chicken Wing (Skinless, raw)",
            gramsPerServing: 100,
            caloriesPerServing: 203,
            proteinPerServing: 30,
            fatPerServing: 8,
            carbsPerServing: 0,
            fiberPerServing: 0
        )
    ]
}


