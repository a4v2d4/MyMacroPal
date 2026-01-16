import Foundation
import CoreData
import Combine

// MARK: - Home View Model
final class HomeViewModel: ObservableObject {
    @Published var totalCalories: Double = 0
    @Published var totalProtein: Double = 0
    @Published var totalFat: Double = 0
    @Published var totalCarbs: Double = 0
    @Published var totalFiber: Double = 0
    @Published var totalMicronutrients: MicronutrientData = MicronutrientData()

    private var context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.context = context
        calculateTotalsForToday()
    }

    func calculateTotalsForToday() {
        let request: NSFetchRequest<FoodEntryEntity> = FoodEntryEntity.fetchRequest()
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)

        do {
            let items = try context.fetch(request)
            totalCalories = items.reduce(0) { $0 + $1.calories.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
            totalProtein = items.reduce(0) { $0 + $1.protein.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
            totalFat = items.reduce(0) { $0 + $1.fat.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
            totalCarbs = items.reduce(0) { $0 + $1.carbs.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
            totalFiber = items.reduce(0) { $0 + $1.fiber.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
            totalMicronutrients = items.reduce(MicronutrientData()) { $0 + $1.micronutrients }
        } catch {
            print("Fetch error: \(error)")
        }
    }
}

// MARK: - Add Food View Model
final class AddFoodViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [USDAFood] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let service = USDAService()
    
    private var searchTask: Task<Void, Never>?

    func search(_ query: String) {
        searchTask?.cancel()
        self.query = query
        self.errorMessage = nil
        
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            results = []
            return
        }

        searchTask = Task { [weak self] in
            await self?.performSearch(query)
        }
    }

    private func performSearch(_ query: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let results = try await service.searchFoods(query: query)
            await MainActor.run {
                self.results = results
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.results = []
                self.isLoading = false
                if let usdaError = error as? USDAServiceError {
                    self.errorMessage = usdaError.localizedDescription
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Food Detail View Model
final class FoodDetailViewModel: ObservableObject {
    @Published var food: USDAFood
    @Published var chosenGrams: Double = 100
    @Published var calculatedCalories: Double = 0
    @Published var calculatedProtein: Double = 0
    @Published var calculatedFat: Double = 0
    @Published var calculatedCarbs: Double = 0
    @Published var calculatedFiber: Double = 0
    @Published var calculatedMicronutrients: MicronutrientData = MicronutrientData()

    init(food: USDAFood) {
        self.food = food
        calculate(for: chosenGrams)
    }

    func calculate(for grams: Double) {
        // Extract per 100g values from food.foodNutrients
        func nutrientValue(_ name: String) -> Double {
            guard let nutrients = food.foodNutrients else { return 0 }
            if let nutrient = nutrients.first(where: { 
                $0.nutrientName.lowercased().contains(name.lowercased()) 
            }) {
                return (nutrient.value ?? 0).sanitizedNonNegativeFinite
            }
            return 0
        }

        // USDA values are typically per 100g
        let per100cal = nutrientValue("energy").sanitizedNonNegativeFinite
        let per100p = nutrientValue("protein").sanitizedNonNegativeFinite
        let per100f = nutrientValue("total lipid").sanitizedNonNegativeFinite
        let per100c = nutrientValue("carbohydrate").sanitizedNonNegativeFinite
        let per100fi = nutrientValue("fiber").sanitizedNonNegativeFinite

        let factor = (grams.isFinite ? grams : 0) / 100.0
        calculatedCalories = (per100cal * factor).sanitizedNonNegativeFinite
        calculatedProtein = (per100p * factor).sanitizedNonNegativeFinite
        calculatedFat = (per100f * factor).sanitizedNonNegativeFinite
        calculatedCarbs = (per100c * factor).sanitizedNonNegativeFinite
        calculatedFiber = (per100fi * factor).sanitizedNonNegativeFinite
        
        // Extract and scale micronutrients (USDA values are per 100g)
        let per100gMicros = food.extractMicronutrients()
        var scaledMicros = MicronutrientData()
        for nutrient in Micronutrient.allCases {
            scaledMicros[nutrient] = (per100gMicros[nutrient] * factor).sanitizedNonNegativeFinite
        }
        calculatedMicronutrients = scaledMicros
    }
}
