import WidgetKit
import SwiftUI
import CoreData

// MARK: - Widget Entry
struct MacroEntry: TimelineEntry {
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let goalCalories: Double
    let goalProtein: Double
    let goalCarbs: Double
    let goalFat: Double
}

// MARK: - Timeline Provider
struct MacroProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacroEntry {
        MacroEntry(
            date: Date(),
            calories: 1200,
            protein: 80,
            carbs: 150,
            fat: 45,
            goalCalories: 2000,
            goalProtein: 150,
            goalCarbs: 250,
            goalFat: 70
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MacroEntry) -> Void) {
        let entry = fetchCurrentData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroEntry>) -> Void) {
        let entry = fetchCurrentData()
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func fetchCurrentData() -> MacroEntry {
        let container = NSPersistentContainer(name: "MyMacroPal")
        container.persistentStoreDescriptions.first?.url = SharedConfig.sharedContainerURL
        
        var totalCalories = 0.0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0
        
        let semaphore = DispatchSemaphore(value: 0)
        
        container.loadPersistentStores { _, error in
            if error == nil {
                let context = container.viewContext
                let request: NSFetchRequest<FoodEntryEntity> = FoodEntryEntity.fetchRequest()
                let start = Calendar.current.startOfDay(for: Date())
                let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
                request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
                
                if let items = try? context.fetch(request) {
                    totalCalories = items.reduce(0) { $0 + $1.calories }
                    totalProtein = items.reduce(0) { $0 + $1.protein }
                    totalCarbs = items.reduce(0) { $0 + $1.carbs }
                    totalFat = items.reduce(0) { $0 + $1.fat }
                }
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        // Fetch goals from shared UserDefaults
        let defaults = UserDefaults.shared
        let goalCalories = defaults.double(forKey: "goalCalories", default: 2000)
        let goalProtein = defaults.double(forKey: "goalProtein", default: 150)
        let goalCarbs = defaults.double(forKey: "goalCarbs", default: 250)
        let goalFat = defaults.double(forKey: "goalFat", default: 70)
        
        return MacroEntry(
            date: Date(),
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            goalCalories: goalCalories,
            goalProtein: goalProtein,
            goalCarbs: goalCarbs,
            goalFat: goalFat
        )
    }
}

// MARK: - Widget Views

// Compact Widget (4 macros in 2x2 grid)
struct MacroWidgetSmallView: View {
    var entry: MacroEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(UIColor.systemBackground))
            
            VStack(spacing: 6) {
                // Top row: Calories (left) and Protein (right)
                HStack(spacing: 6) {
                    CircularProgressView(
                        label: "Calories",
                        value: entry.calories,
                        goal: entry.goalCalories,
                        color: .blue,
                        size: .small
                    )
                    
                    CircularProgressView(
                        label: "Protein",
                        value: entry.protein,
                        goal: entry.goalProtein,
                        color: .green,
                        size: .small
                    )
                }
                
                // Bottom row: Carbs (left) and Fat (right)
                HStack(spacing: 6) {
                    CircularProgressView(
                        label: "Carbs",
                        value: entry.carbs,
                        goal: entry.goalCarbs,
                        color: .purple,
                        size: .small
                    )
                    
                    CircularProgressView(
                        label: "Fat",
                        value: entry.fat,
                        goal: entry.goalFat,
                        color: .orange,
                        size: .small
                    )
                }
            }
            .padding(12)
        }
    }
}

// Single Macro Widget - Calories
struct CaloriesWidgetView: View {
    var entry: MacroEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(UIColor.systemBackground))
            
            CircularProgressView(
                label: "Calories",
                value: entry.calories,
                goal: entry.goalCalories,
                color: .blue,
                size: .large
            )
            .padding(16)
        }
    }
}

// Single Macro Widget - Protein
struct ProteinWidgetView: View {
    var entry: MacroEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(UIColor.systemBackground))
            
            CircularProgressView(
                label: "Protein",
                value: entry.protein,
                goal: entry.goalProtein,
                color: .green,
                size: .large
            )
            .padding(16)
        }
    }
}

// Single Macro Widget - Carbs
struct CarbsWidgetView: View {
    var entry: MacroEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(UIColor.systemBackground))
            
            CircularProgressView(
                label: "Carbs",
                value: entry.carbs,
                goal: entry.goalCarbs,
                color: .purple,
                size: .large
            )
            .padding(16)
        }
    }
}

// Single Macro Widget - Fat
struct FatWidgetView: View {
    var entry: MacroEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(UIColor.systemBackground))
            
            CircularProgressView(
                label: "Fat",
                value: entry.fat,
                goal: entry.goalFat,
                color: .orange,
                size: .large
            )
            .padding(16)
        }
    }
}

// MARK: - Circular Progress Component
struct CircularProgressView: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    let size: WidgetSize
    
    enum WidgetSize {
        case small, large
        
        var circleSize: CGFloat {
            switch self {
            case .small: return 50
            case .large: return 90
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .small: return 5
            case .large: return 9
            }
        }
        
        var percentageFont: Font {
            switch self {
            case .small: return .system(size: 13, weight: .bold, design: .rounded)
            case .large: return .system(size: 24, weight: .bold, design: .rounded)
            }
        }
        
        var valueFont: Font {
            switch self {
            case .small: return .system(size: 9, weight: .medium)
            case .large: return .system(size: 14, weight: .medium)
            }
        }
        
        var labelFont: Font {
            switch self {
            case .small: return .system(size: 9, weight: .semibold)
            case .large: return .system(size: 13, weight: .semibold)
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small: return 3
            case .large: return 8
            }
        }
    }
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    
    private var percentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        VStack(spacing: size.spacing) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: size.lineWidth)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                // Center content
                VStack(spacing: 1) {
                    Text("\(percentage)%")
                        .font(size.percentageFont)
                        .foregroundColor(color)
                    
                    Text("\(Int(value))")
                        .font(size.valueFont)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: size.circleSize, height: size.circleSize)
            
            Text(label)
                .font(size.labelFont)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Widget Configurations

// All Macros Widget (Compact)
struct AllMacrosSmallWidget: Widget {
    let kind: String = "AllMacrosSmallWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroProvider()) { entry in
            MacroWidgetSmallView(entry: entry)
        }
        .configurationDisplayName("All Macros")
        .description("Track all macros with 1 compact widget")
        .supportedFamilies([.systemSmall])
    }
}

// Calories Widget
struct CaloriesWidget: Widget {
    let kind: String = "CaloriesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroProvider()) { entry in
            CaloriesWidgetView(entry: entry)
        }
        .configurationDisplayName("Calories")
        .description("Track daily calorie intake")
        .supportedFamilies([.systemSmall])
    }
}

// Protein Widget
struct ProteinWidget: Widget {
    let kind: String = "ProteinWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroProvider()) { entry in
            ProteinWidgetView(entry: entry)
        }
        .configurationDisplayName("Protein")
        .description("Track daily protein intake")
        .supportedFamilies([.systemSmall])
    }
}

// Carbs Widget
struct CarbsWidget: Widget {
    let kind: String = "CarbsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroProvider()) { entry in
            CarbsWidgetView(entry: entry)
        }
        .configurationDisplayName("Carbs")
        .description("Track daily carbohydrate intake")
        .supportedFamilies([.systemSmall])
    }
}

// Fat Widget
struct FatWidget: Widget {
    let kind: String = "FatWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroProvider()) { entry in
            FatWidgetView(entry: entry)
        }
        .configurationDisplayName("Fat")
        .description("Track daily fat intake")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview
struct MyMacroPalWidget_Previews: PreviewProvider {
    static let sampleEntry = MacroEntry(
        date: Date(),
        calories: 1200,
        protein: 80,
        carbs: 150,
        fat: 45,
        goalCalories: 2000,
        goalProtein: 150,
        goalCarbs: 250,
        goalFat: 70
    )
    
    static var previews: some View {
        Group {
            MacroWidgetSmallView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("All Macros")
            
            CaloriesWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Calories")
            
            ProteinWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Protein")
            
            CarbsWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Carbs")
            
            FatWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Fat")
        }
    }
}
