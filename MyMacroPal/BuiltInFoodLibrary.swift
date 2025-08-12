import Foundation

/// Built-in foods that ship with the app, derived from markdown in `BuiltInFoods/`.
/// Values are per labeled serving. `gramsPerServing` is used for scaling when using grams/servings.
enum BuiltInFoodLibrary {
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
            fiberPerServing: 0
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
            fiberPerServing: 10
        ),

        // MARK: Eggs
        LibraryFood(
            name: "Large Egg",
            gramsPerServing: 50,
            caloriesPerServing: 70,
            proteinPerServing: 6,
            fatPerServing: 5,
            carbsPerServing: 0,
            fiberPerServing: 0
        ),
        LibraryFood(
            name: "Large Egg White",
            gramsPerServing: 33,
            caloriesPerServing: 17,
            proteinPerServing: 3.6,
            fatPerServing: 0.05,
            carbsPerServing: 0.24,
            fiberPerServing: 0
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
            fiberPerServing: 0
        ),

        // MARK: Vegetables (Raw)
        LibraryFood(
            name: "Yellow Potato (raw)",
            gramsPerServing: 150,
            caloriesPerServing: 110,
            proteinPerServing: 3,
            fatPerServing: 0,
            carbsPerServing: 26,
            fiberPerServing: 2
        ),
        LibraryFood(
            name: "Red Potato (raw)",
            gramsPerServing: 150,
            caloriesPerServing: 110,
            proteinPerServing: 3,
            fatPerServing: 0,
            carbsPerServing: 26,
            fiberPerServing: 2
        ),
        LibraryFood(
            name: "Sweet Potato (raw)",
            gramsPerServing: 130,
            caloriesPerServing: 112,
            proteinPerServing: 2,
            fatPerServing: 0,
            carbsPerServing: 26,
            fiberPerServing: 4
        ),
        LibraryFood(
            name: "Broccoli (raw)",
            gramsPerServing: 90,
            caloriesPerServing: 25,
            proteinPerServing: 3,
            fatPerServing: 0,
            carbsPerServing: 5,
            fiberPerServing: 2
        ),
        LibraryFood(
            name: "Broccolini (raw)",
            gramsPerServing: 85,
            caloriesPerServing: 25,
            proteinPerServing: 3,
            fatPerServing: 0,
            carbsPerServing: 4,
            fiberPerServing: 2
        ),
        LibraryFood(
            name: "Spinach (raw)",
            gramsPerServing: 30,
            caloriesPerServing: 7,
            proteinPerServing: 1,
            fatPerServing: 0,
            carbsPerServing: 1,
            fiberPerServing: 1
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
            fiberPerServing: 4
        ),
        LibraryFood(
            name: "Raspberries",
            gramsPerServing: 125,
            caloriesPerServing: 65,
            proteinPerServing: 1,
            fatPerServing: 1,
            carbsPerServing: 15,
            fiberPerServing: 8
        ),
        LibraryFood(
            name: "Honeycrisp Apple",
            gramsPerServing: 180,
            caloriesPerServing: 95,
            proteinPerServing: 0,
            fatPerServing: 0,
            carbsPerServing: 25,
            fiberPerServing: 4
        ),
        LibraryFood(
            name: "Banana",
            gramsPerServing: 120,
            caloriesPerServing: 105,
            proteinPerServing: 1,
            fatPerServing: 0,
            carbsPerServing: 27,
            fiberPerServing: 3
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
            fiberPerServing: 14
        ),

        // MARK: Meat (Raw)
        LibraryFood(
            name: "Chicken Breast (Skinless, raw)",
            gramsPerServing: 100,
            caloriesPerServing: 165,
            proteinPerServing: 31,
            fatPerServing: 4,
            carbsPerServing: 0,
            fiberPerServing: 0
        ),
        LibraryFood(
            name: "Sockeye Salmon (raw)",
            gramsPerServing: 100,
            caloriesPerServing: 216,
            proteinPerServing: 27,
            fatPerServing: 11,
            carbsPerServing: 0,
            fiberPerServing: 0
        ),
        LibraryFood(
            name: "93/7 Ground Beef (raw)",
            gramsPerServing: 100,
            caloriesPerServing: 152,
            proteinPerServing: 22,
            fatPerServing: 7,
            carbsPerServing: 0,
            fiberPerServing: 0
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


