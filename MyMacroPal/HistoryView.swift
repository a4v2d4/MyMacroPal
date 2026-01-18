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
    @EnvironmentObject private var mealLibrary: MealLibraryStore
    @FetchRequest private var meals: FetchedResults<MealEntity>
    @FetchRequest private var uncategorizedEntries: FetchedResults<FoodEntryEntity>
    @State private var showAddFood: Bool = false
    @State private var selectedMeal: MealEntity?
    @State private var mealToEdit: MealEntity?

    init(date: Date) {
        self.date = date
        // ... (init code remains same) ...
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        _meals = FetchRequest(
            entity: MealEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \MealEntity.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        )
        
        _uncategorizedEntries = FetchRequest(
            entity: FoodEntryEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \FoodEntryEntity.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@ AND meal == nil", start as NSDate, end as NSDate)
        )
    }

    private var allEntries: [FoodEntryEntity] {
        let mealEntries = meals.flatMap { $0.foodEntries }
        return mealEntries + Array(uncategorizedEntries)
    }

    private var totalCalories: Double {
        allEntries.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        allEntries.reduce(0) { $0 + $1.protein }
    }

    private var totalFat: Double {
        allEntries.reduce(0) { $0 + $1.fat }
    }

    private var totalCarbs: Double {
        allEntries.reduce(0) { $0 + $1.carbs }
    }

    private var totalFiber: Double {
        allEntries.reduce(0) { $0 + $1.fiber }
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

            ForEach(meals) { meal in
                Section {
                    if meal.foodEntries.isEmpty {
                        Text("No items in this meal")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(meal.foodEntries, id: \.id) { entry in
                            EditableFoodEntryRow(entry: entry)
                        }
                        .onDelete { offsets in
                            deleteEntries(at: offsets, from: meal)
                        }
                    }
                }                 header: {
                    HStack {
                        Text(meal.name ?? "Meal")
                        Spacer()
                        if let mealDate = meal.date {
                            Text(timeString(mealDate))
                                .font(.caption)
                                .textCase(nil)
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                selectedMeal = meal
                                showAddFood = true
                            }) {
                                Image(systemName: "plus")
                            }
                            
                            Menu {
                                Button(action: {
                                    mealToEdit = meal
                                }) {
                                    Label("Edit Meal", systemImage: "pencil")
                                }
                                
                                Button(action: {
                                    presentSaveMealAlert(meal)
                                }) {
                                    Label("Save to Library", systemImage: "square.and.arrow.down")
                                }
                                
                                Button(role: .destructive, action: {
                                    deleteMeal(meal)
                                }) {
                                    Label("Delete Meal", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                } footer: {
                    HStack {
                        Text("Meal Total:")
                        Spacer()
                        Text("\(Int(meal.totalCalories)) cal | P: \(Int(meal.totalProtein))g | F: \(Int(meal.totalFat))g | C: \(Int(meal.totalCarbs))g")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            if !uncategorizedEntries.isEmpty {
                Section("Uncategorized") {
                    ForEach(uncategorizedEntries, id: \.id) { entry in
                        EditableFoodEntryRow(entry: entry)
                    }
                    .onDelete(perform: deleteUncategorizedItems)
                }
            }
            
            Section {
                Button(action: addNextMeal) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Meal #\(meals.count + 1)")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle(dateString(date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Meal") {
                    addNextMeal()
                }
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodView(targetDate: date, targetMeal: selectedMeal)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $mealToEdit) { meal in
            MealEditView(meal: meal)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private func addNextMeal() {
        let newMeal = MealEntity(context: viewContext)
        newMeal.id = UUID()
        newMeal.name = "Meal #\(meals.count + 1)"
        
        // If it's today, use current time. If it's a past/future day, use that day's start time + some offset
        let now = Date()
        let calendar = Calendar.current
        if calendar.isDate(now, inSameDayAs: date) {
            newMeal.date = now
        } else {
            newMeal.date = calendar.date(bySettingHour: 8 + (meals.count * 2), minute: 0, second: 0, of: date) ?? date
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error adding meal: \(error)")
        }
    }

    private func deleteEntries(at offsets: IndexSet, from meal: MealEntity) {
        let entries = meal.foodEntries
        for index in offsets {
            viewContext.delete(entries[index])
        }
        do { try viewContext.save() } catch { print("Delete error: \(error)") }
    }

    private func deleteMeal(_ meal: MealEntity) {
        viewContext.delete(meal)
        do { try viewContext.save() } catch { print("Delete meal error: \(error)") }
    }

    private func deleteUncategorizedItems(at offsets: IndexSet) {
        for index in offsets { viewContext.delete(uncategorizedEntries[index]) }
        do { try viewContext.save() } catch { print("Delete error: \(error)") }
    }
    
    private func presentSaveMealAlert(_ meal: MealEntity) {
        let alert = UIAlertController(title: "Save Meal", message: "Enter a name for this meal library entry.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Meal Name"
            tf.text = meal.name
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let name = alert.textFields?.first?.text ?? ""
            let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (meal.name ?? "My Meal") : name
            mealLibrary.saveMeal(meal, name: finalName)
        }))
        
        // Find the active window scene to present the alert
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
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
    @State private var showMoveMeal = false

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
                
                Menu {
                    Button(action: {
                        gramsText = entry.quantityGrams > 0 ? String(Int(entry.quantityGrams)) : ""
                        isEditing = true
                    }) {
                        Label("Change Amount", systemImage: "scalemass")
                    }
                    
                    Button(action: {
                        showEditDetails = true
                    }) {
                        Label("Edit Details", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        showMoveMeal = true
                    }) {
                        Label("Move to Meal", systemImage: "arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .padding(8)
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
                    Button("Cancel") {
                        isEditing = false
                    }
                    .buttonStyle(.bordered)
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
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showEditDetails) {
            FoodEntryEditView(entry: entry)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showMoveMeal) {
            MoveMealSelectionView(entry: entry)
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

// Move meal selection sheet
struct MoveMealSelectionView: View {
    @ObservedObject var entry: FoodEntryEntity
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest private var meals: FetchedResults<MealEntity>
    
    init(entry: FoodEntryEntity) {
        self.entry = entry
        
        // Fetch meals for the same day as the entry
        let entryDate = entry.date ?? Date()
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: entryDate)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        _meals = FetchRequest(
            entity: MealEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \MealEntity.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Select Meal")) {
                    // Option to move to uncategorized
                    Button(action: {
                        moveToMeal(nil)
                    }) {
                        HStack {
                            Text("Uncategorized")
                            Spacer()
                            if entry.meal == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    // Options for each meal
                    ForEach(meals) { meal in
                        Button(action: {
                            moveToMeal(meal)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(meal.name ?? "Meal")
                                    if let mealDate = meal.date {
                                        Text(timeString(mealDate))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if entry.meal == meal {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Move to Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func moveToMeal(_ meal: MealEntity?) {
        entry.meal = meal
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error moving entry to meal: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        HistoryView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
