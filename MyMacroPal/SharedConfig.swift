import Foundation

/// Shared configuration for app group access between main app and widget
enum SharedConfig {
    static let appGroupID = "group.AVIDWareAthletics.MyMacroPal"
    
    /// Shared UserDefaults instance for accessing goals across app and widget
    static var sharedDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            fatalError("Unable to create UserDefaults with app group ID")
        }
        return defaults
    }
    
    /// Core Data store URL in the shared app group container
    static var sharedContainerURL: URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Unable to access app group container")
        }
        return containerURL.appendingPathComponent("MyMacroPal.sqlite")
    }
}

/// Extension to make accessing shared defaults cleaner
extension UserDefaults {
    static var shared: UserDefaults {
        return SharedConfig.sharedDefaults
    }
}

