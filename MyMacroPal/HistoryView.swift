import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodEntryEntity.date, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<FoodEntryEntity>

    @State private var selectedMode: Int = 0 // 0: List, 1: Calendar
    @State private var selectedDate: Date = Date()
    @State private var showAddFood: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedMode) {
                Text("List").tag(0)
                Text("Calendar").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedMode == 0 {
                // List summary of days
                List {
                    ForEach(allDatesSorted, id: \.self) { date in
                        NavigationLink(destination: DailyLogDetailView(date: date)) {
                            DailyLogRow(date: date, entries: groupedEntries[date] ?? [])
                        }
                    }
                }
            } else {
                // Calendar selection + detail for the selected day
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)

                        NavigationLink(destination: DailyLogDetailView(date: Calendar.current.startOfDay(for: selectedDate))) {
                            Text("View Day Details")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddFood) {
            AddFoodView(targetDate: selectedMode == 0 ? nil : Calendar.current.startOfDay(for: selectedDate))
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private var groupedEntries: [Date: [FoodEntryEntity]] {
        let calendar = Calendar.current
        return Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date ?? Date())
        }
    }

    private var allDatesSorted: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let pastOrTodayDatesWithEntries = groupedEntries.keys
            .map { calendar.startOfDay(for: $0) }
            .filter { $0 <= today }
        var set: Set<Date> = Set(pastOrTodayDatesWithEntries)
        set.insert(today)
        return Array(set).sorted(by: >)
    }
}

struct DailyLogRow: View {
    let date: Date
    let entries: [FoodEntryEntity]

    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.calories.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
    }

    private var totalProtein: Double {
        entries.reduce(0) { $0 + $1.protein.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
    }

    private var totalFat: Double {
        entries.reduce(0) { $0 + $1.fat.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
    }

    private var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.carbs.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
    }

    private var totalFiber: Double {
        entries.reduce(0) { $0 + $1.fiber.sanitizedNonNegativeFinite }.sanitizedNonNegativeFinite
    }

    private var goalCalories: Double {
        UserDefaults.shared.double(forKey: "goalCalories", default: 2000)
    }

    private var goalProtein: Double {
        UserDefaults.shared.double(forKey: "goalProtein", default: 150)
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
    @State private var showAddFood: Bool = false

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
                }
                ForEach(entries, id: \.id) { entry in
                    EditableFoodEntryRow(entry: entry)
                }
                .onDelete(perform: deleteItems)
            }
        }
        .navigationTitle(dateString(date))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                Button(action: { showAddFood = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Food")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .background(.thinMaterial)
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodView(targetDate: Calendar.current.startOfDay(for: date))
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets { viewContext.delete(entries[index]) }
        do { try viewContext.save() } catch { print("Delete error: \(error)") }
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

struct EditableFoodEntryRow: View {
    @ObservedObject var entry: FoodEntryEntity
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isEditing = false
    @State private var gramsText: String = ""
    @State private var showEditDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            
            if isEditing {
                HStack {
                    Text("Grams:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $gramsText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Spacer()
                    Button("Save") { saveEdits() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                HStack(spacing: 12) {
                    Text("\(Int(entry.calories)) cal").font(.caption).foregroundColor(.blue)
                    Text("P: \(Int(entry.protein))g").font(.caption).foregroundColor(.green)
                    Text("F: \(Int(entry.fat))g").font(.caption).foregroundColor(.orange)
                    Text("C: \(Int(entry.carbs))g").font(.caption).foregroundColor(.purple)
                    if entry.quantityGrams > 0 {
                        Spacer()
                        Text("(\(Int(entry.quantityGrams))g)").font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                Button(isEditing ? "Cancel" : "Change Amount") {
                    if isEditing {
                        isEditing = false
                    } else {
                        gramsText = entry.quantityGrams > 0 ? String(Int(entry.quantityGrams)) : ""
                        isEditing = true
                    }
                }
                .buttonStyle(.bordered)

                Button("Edit Details") { showEditDetails = true }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showEditDetails) {
            FoodEntryEditView(entry: entry)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func saveEdits() {
        let oldGrams = entry.quantityGrams
        let newGrams = Double(gramsText) ?? oldGrams
        entry.quantityGrams = newGrams
        if oldGrams > 0, newGrams > 0 {
            let factor = newGrams / oldGrams
            entry.calories *= factor
            entry.protein *= factor
            entry.fat *= factor
            entry.carbs *= factor
            entry.fiber *= factor
        }
        do { try viewContext.save() } catch { print("Save error: \(error)") }
        isEditing = false
    }
}

// Full edit sheet for a food entry
struct FoodEntryEditView: View {
    @ObservedObject var entry: FoodEntryEntity
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var fatText: String = ""
    @State private var carbsText: String = ""
    @State private var fiberText: String = ""
    @State private var gramsText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food")) {
                    TextField("Name", text: $name)
                }
                Section(header: Text("Macros")) {
                    HStack { Text("Calories"); Spacer(); TextField("0", text: $caloriesText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Protein (g)"); Spacer(); TextField("0", text: $proteinText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Fat (g)"); Spacer(); TextField("0", text: $fatText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Carbs (g)"); Spacer(); TextField("0", text: $carbsText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Fiber (g)"); Spacer(); TextField("0", text: $fiberText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                }
                Section(header: Text("Amount")) {
                    HStack { Text("Grams"); Spacer(); TextField("0", text: $gramsText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { save() }.buttonStyle(.borderedProminent) }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        name = entry.name ?? ""
        caloriesText = String(Int(entry.calories))
        proteinText = String(Int(entry.protein))
        fatText = String(Int(entry.fat))
        carbsText = String(Int(entry.carbs))
        fiberText = String(Int(entry.fiber))
        gramsText = entry.quantityGrams > 0 ? String(Int(entry.quantityGrams)) : ""
    }

    private func save() {
        entry.name = name
        entry.calories = Double(caloriesText) ?? entry.calories
        entry.protein = Double(proteinText) ?? entry.protein
        entry.fat = Double(fatText) ?? entry.fat
        entry.carbs = Double(carbsText) ?? entry.carbs
        entry.fiber = Double(fiberText) ?? entry.fiber
        entry.quantityGrams = Double(gramsText) ?? entry.quantityGrams
        do { try viewContext.save() } catch { print("Edit save error: \(error)") }
        dismiss()
    }
}

#Preview {
    NavigationView {
        HistoryView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
