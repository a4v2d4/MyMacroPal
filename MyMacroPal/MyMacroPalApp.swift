import SwiftUI
import CoreData

@main
struct MyMacroPalApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var foodLibrary = FoodLibraryStore()
    @StateObject private var mealLibrary = MealLibraryStore()

    init() {
        // Migrate existing user goals to shared app group for widget access
        UserDefaultsMigration.migrateGoalsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(foodLibrary)
                .environmentObject(mealLibrary)
        }
    }
}
