import Foundation

/// Helper to migrate user goals from standard UserDefaults to shared UserDefaults
/// This should be called once when the app launches after the widget update
struct UserDefaultsMigration {
    
    /// Migrates existing goals from standard UserDefaults to shared App Group UserDefaults
    static func migrateGoalsIfNeeded() {
        let migrationKey = "hasModernAppGroupMigrated"
        
        // Check if migration already completed
        if UserDefaults.shared.bool(forKey: migrationKey) {
            return
        }
        
        let standard = UserDefaults.standard
        let shared = UserDefaults.shared
        
        let keysToMigrate = [
            "goalCalories",
            "goalProtein",
            "goalFat",
            "goalCarbs",
            "goalFiber"
        ]
        
        var didMigrate = false
        
        for key in keysToMigrate {
            let value = standard.double(forKey: key)
            // Only migrate if there's an existing value (non-zero)
            if value > 0 {
                // Only write if shared doesn't already have a value
                let existingShared = shared.double(forKey: key)
                if existingShared == 0 {
                    shared.set(value, forKey: key)
                    didMigrate = true
                }
            }
        }
        
        // Mark migration as complete
        shared.set(true, forKey: migrationKey)
        
        if didMigrate {
            print("✅ Successfully migrated user goals to shared app group")
        } else {
            print("ℹ️ No migration needed - using existing shared defaults")
        }
    }
}

