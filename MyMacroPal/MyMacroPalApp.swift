import SwiftUI
import CoreData

@main
struct MyMacroPalApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Migrate existing user goals to shared app group for widget access
        UserDefaultsMigration.migrateGoalsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
