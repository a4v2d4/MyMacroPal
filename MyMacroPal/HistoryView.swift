import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodEntryEntity.date, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<FoodEntryEntity>

    var body: some View {
        List {
            ForEach(groupedEntries.keys.sorted(by: >), id: \.self) { date in
                NavigationLink(destination: DailyLogDetailView(date: date)) {
                    DailyLogRow(date: date, entries: groupedEntries[date] ?? [])
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }

    private var groupedEntries: [Date: [FoodEntryEntity]] {
        let calendar = Calendar.current
        return Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date ?? Date())
        }
    }
}

struct DailyLogRow: View {
    let date: Date
    let entries: [FoodEntryEntity]

    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        entries.reduce(0) { $0 + $1.protein }
    }

    private var totalFat: Double {
        entries.reduce(0) { $0 + $1.fat }
    }

    private var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.carbs }
    }

    private var totalFiber: Double {
        entries.reduce(0) { $0 + $1.fiber }
    }

    private var goalCalories: Double {
        UserDefaults.standard.double(forKey: "goalCalories", default: 2000)
    }

    private var goalProtein: Double {
        UserDefaults.standard.double(forKey: "goalProtein", default: 150)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateString(date))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(entries.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 4) {
                HStack {
                    Text("Calories:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(Int(totalCalories))/\(Int(goalCalories))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Protein:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(Int(totalProtein))/\(Int(goalProtein))g")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Fat: \(Int(totalFat))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Carbs: \(Int(totalCarbs))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Fiber: \(Int(totalFiber))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DailyLogDetailView: View {
    let date: Date
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var entries: FetchedResults<FoodEntryEntity>

    init(date: Date) {
        self.date = date
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        _entries = FetchRequest(
            entity: FoodEntryEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \FoodEntryEntity.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        )
    }

    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        entries.reduce(0) { $0 + $1.protein }
    }

    private var totalFat: Double {
        entries.reduce(0) { $0 + $1.fat }
    }

    private var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.carbs }
    }

    private var totalFiber: Double {
        entries.reduce(0) { $0 + $1.fiber }
    }

    var body: some View {
        List {
            Section("Summary") {
                VStack(spacing: 12) {
                    MacroSummaryRow(label: "Calories", value: totalCalories, unit: "kcal", color: .blue)
                    MacroSummaryRow(label: "Protein", value: totalProtein, unit: "g", color: .green)
                    MacroSummaryRow(label: "Fat", value: totalFat, unit: "g", color: .orange)
                    MacroSummaryRow(label: "Carbs", value: totalCarbs, unit: "g", color: .purple)
                    MacroSummaryRow(label: "Fiber", value: totalFiber, unit: "g", color: .brown)
                }
                .padding(.vertical, 8)
            }

            Section("Food Items") {
                if entries.isEmpty {
                    Text("No food items logged for this day")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(entries, id: \.id) { entry in
                        FoodEntryRow(entry: entry)
                    }
                }
            }
        }
        .navigationTitle(dateString(date))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct MacroSummaryRow: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(Int(value)) \(unit)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntryEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.name ?? "Unknown Food")
                    .font(.headline)
                
                Spacer()
                
                if entry.source == "usda" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            HStack(spacing: 12) {
                Text("\(Int(entry.calories)) cal")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("P: \(Int(entry.protein))g")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("F: \(Int(entry.fat))g")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("C: \(Int(entry.carbs))g")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                if entry.quantityGrams > 0 {
                    Spacer()
                    Text("(\(Int(entry.quantityGrams))g)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        HistoryView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
