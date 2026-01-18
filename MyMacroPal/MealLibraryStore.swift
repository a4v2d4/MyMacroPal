import Foundation
import Combine

final class MealLibraryStore: ObservableObject {
    @Published private(set) var meals: [LibraryMeal] = []

    private let fileURL: URL
    private let queue = DispatchQueue(label: "MealLibraryStore")

    init(filename: String = "meal_library.json") {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        fileURL = dir.appendingPathComponent(filename)
        load()
    }

    func saveMeal(_ meal: MealEntity, name: String) {
        let items = meal.foodEntries.map { entry in
            LibraryMealItem(
                foodName: entry.name ?? "Unknown Food",
                grams: entry.quantityGrams,
                calories: entry.calories,
                protein: entry.protein,
                fat: entry.fat,
                carbs: entry.carbs,
                fiber: entry.fiber,
                micronutrients: entry.micronutrients
            )
        }
        let libraryMeal = LibraryMeal(name: name, items: items)
        meals.append(libraryMeal)
        persist()
    }

    func addMeal(_ meal: LibraryMeal) {
        meals.append(meal)
        persist()
    }

    func deleteMeal(id: UUID) {
        meals.removeAll { $0.id == id }
        persist()
    }

    private func load() {
        queue.sync {
            guard let data = try? Data(contentsOf: fileURL) else { return }
            do {
                let decoded = try JSONDecoder().decode([LibraryMeal].self, from: data)
                DispatchQueue.main.async { self.meals = decoded }
            } catch { 
                print("Error loading meal library: \(error)")
            }
        }
    }

    private func persist() {
        let snapshot = meals
        queue.async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: self.fileURL, options: [.atomic])
            } catch { 
                print("Error saving meal library: \(error)")
            }
        }
    }
}
