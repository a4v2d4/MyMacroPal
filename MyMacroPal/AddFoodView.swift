import SwiftUI
import CoreData
import UIKit
import Combine
import Foundation

// MARK: - Food Library (inline to avoid project file changes)

struct LibraryFood: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var gramsPerServing: Double
    var caloriesPerServing: Double
    var proteinPerServing: Double
    var fatPerServing: Double
    var carbsPerServing: Double
    var fiberPerServing: Double
    var micronutrientsPerServing: MicronutrientData?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        gramsPerServing: Double,
        caloriesPerServing: Double,
        proteinPerServing: Double,
        fatPerServing: Double,
        carbsPerServing: Double,
        fiberPerServing: Double,
        micronutrientsPerServing: MicronutrientData? = nil
    ) {
        self.id = id
        self.name = name
        self.gramsPerServing = gramsPerServing
        self.caloriesPerServing = caloriesPerServing
        self.proteinPerServing = proteinPerServing
        self.fatPerServing = fatPerServing
        self.carbsPerServing = carbsPerServing
        self.fiberPerServing = fiberPerServing
        self.micronutrientsPerServing = micronutrientsPerServing
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    func macrosFor(grams: Double) -> (calories: Double, protein: Double, fat: Double, carbs: Double, fiber: Double) {
        let safeServingGrams = max(gramsPerServing, 0.00001)
        let factor = grams / safeServingGrams
        return (
            calories: caloriesPerServing * factor,
            protein: proteinPerServing * factor,
            fat: fatPerServing * factor,
            carbs: carbsPerServing * factor,
            fiber: fiberPerServing * factor
        )
    }
    
    func micronutrientsFor(grams: Double) -> MicronutrientData {
        guard let micros = micronutrientsPerServing else { return MicronutrientData() }
        let safeServingGrams = max(gramsPerServing, 0.00001)
        let factor = grams / safeServingGrams
        
        var scaled = MicronutrientData()
        for nutrient in Micronutrient.allCases {
            scaled[nutrient] = micros[nutrient] * factor
        }
        return scaled
    }
}

final class FoodLibraryStore: ObservableObject {
    @Published private(set) var foods: [LibraryFood] = []

    private let fileURL: URL
    private let queue = DispatchQueue(label: "FoodLibraryStore")

    init(filename: String = "food_library.json") {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        fileURL = dir.appendingPathComponent(filename)
        load()
    }

    func search(query: String) -> [LibraryFood] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return foods.sorted { $0.name < $1.name } }
        return foods
            .filter { $0.name.lowercased().contains(q) }
            .sorted { $0.name < $1.name }
    }

    func addFood(_ food: LibraryFood) {
        foods.append(food)
        persist()
    }

    func updateFood(_ food: LibraryFood) {
        if let idx = foods.firstIndex(where: { $0.id == food.id }) {
            var updated = food
            updated.updatedAt = Date()
            foods[idx] = updated
            persist()
        }
    }

    func deleteFood(id: UUID) {
        foods.removeAll { $0.id == id }
        persist()
    }

    // Presets removed — library now supports grams and servings only

    private func load() {
        queue.sync {
            guard let data = try? Data(contentsOf: fileURL) else { return }
            do {
                let decoded = try JSONDecoder().decode([LibraryFood].self, from: data)
                DispatchQueue.main.async { self.foods = decoded }
            } catch { }
        }
    }

    private func persist() {
        let snapshot = foods
        queue.async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: self.fileURL, options: [.atomic])
            } catch { }
        }
    }
}

struct AddFoodView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var libraryStore: FoodLibraryStore
    @EnvironmentObject private var mealLibrary: MealLibraryStore
    @StateObject private var viewModel = AddFoodViewModel()
    @State private var selectedTab = 0
    var targetDate: Date? = nil
    var targetMeal: MealEntity? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Mode", selection: $selectedTab) {
                    Text("My Library").tag(0)
                    Text("Meals").tag(1)
                    Text("Built-In").tag(2)
                    Text("USDA Search").tag(3)
                    Text("Manual").tag(4)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected tab
                if selectedTab == 0 {
                    FoodLibraryTabView(library: libraryStore, targetDate: targetDate, targetMeal: targetMeal)
                } else if selectedTab == 1 {
                    MealLibraryTabView(library: mealLibrary, targetDate: targetDate, targetMeal: targetMeal)
                } else if selectedTab == 2 {
                    BuiltInFoodTabView(targetDate: targetDate, targetMeal: targetMeal)
                } else if selectedTab == 3 {
                    USDASearchView(viewModel: viewModel, targetDate: targetDate, targetMeal: targetMeal)
                } else {
                    ManualEntryView(targetDate: targetDate, targetMeal: targetMeal) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == 0 {
                        NavigationLink(destination: FoodLibraryEditor(library: libraryStore)) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }
}

struct FoodDetailSheet: View {
    let food: USDAFood
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var detailViewModel: FoodDetailViewModel?
    @State private var loadError: String?
    @State private var isFetchingDetails = false
    var targetDate: Date? = nil
    var targetMeal: MealEntity? = nil

    var body: some View {
        ZStack {
            Group {
                if let vm = detailViewModel {
                    FoodDetailView(viewModel: vm, targetDate: targetDate, targetMeal: targetMeal)
                } else if let error = loadError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Failed to load details")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        HStack(spacing: 12) {
                            Button("Dismiss") { dismiss() }
                                .buttonStyle(.bordered)
                            Button("Use Basic Info") {
                                detailViewModel = FoodDetailViewModel(food: food)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Fallback if basic view-model hasn't been set yet (brief state)
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            if isFetchingDetails {
                VStack {
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top)
            }
        }
        .onAppear {
            if detailViewModel == nil {
                // Immediately show basic info so the user can proceed
                detailViewModel = FoodDetailViewModel(food: food)
            }
        }
        .task(id: food.fdcId) {
            await loadDetails()
        }
    }

    private func loadDetails() async {
        await MainActor.run { isFetchingDetails = true }
        defer { Task { await MainActor.run { isFetchingDetails = false } } }
        do {
            let service = USDAService()
            let detailedFood = try await service.getFoodDetails(fdcId: food.fdcId)
            await MainActor.run {
                detailViewModel = FoodDetailViewModel(food: detailedFood)
                loadError = nil
            }
        } catch {
            await MainActor.run {
                loadError = (error as? USDAServiceError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }
}

// MARK: - Built-In Food Tab

struct BuiltInFoodTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var library: FoodLibraryStore
    var targetDate: Date? = nil
    var targetMeal: MealEntity? = nil

    @State private var query: String = ""
    @State private var selected: LibraryFood? = nil

    private func filteredFoods() -> [LibraryFood] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let items = BuiltInFoodLibrary.foods
        guard !q.isEmpty else { return items.sorted { $0.name < $1.name } }
        return items.filter { $0.name.lowercased().contains(q) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search built-in foods...", text: $query)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            let items = filteredFoods()
            if items.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.largeTitle).foregroundColor(.secondary)
                    Text("No matches").foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name).font(.headline)
                        HStack(spacing: 12) {
                            MacroChip(label: "Cal", value: String(Int(item.caloriesPerServing)), unit: "kcal")
                            MacroChip(label: "P", value: String(Int(item.proteinPerServing)), unit: "g")
                            MacroChip(label: "F", value: String(Int(item.fatPerServing)), unit: "g")
                            MacroChip(label: "C", value: String(Int(item.carbsPerServing)), unit: "g")
                            Text("per \(Int(item.gramsPerServing))g").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture { selected = item }
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $selected) { item in
            BuiltInFoodUseSheet(food: item, targetDate: targetDate, targetMeal: targetMeal)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(library)
        }
    }
}

struct BuiltInFoodUseSheet: View {
    let food: LibraryFood
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: FoodLibraryStore
    var targetDate: Date? = nil
    var targetMeal: MealEntity? = nil

    @State private var grams: String = ""
    @State private var servings: String = "1"
    @State private var useMode: Int = 0 // 0 grams, 1 servings
    @State private var entryDate: Date = Date()

    init(food: LibraryFood, targetDate: Date? = nil, targetMeal: MealEntity? = nil) {
        self.food = food
        self.targetDate = targetDate
        self.targetMeal = targetMeal
        // If targetDate is provided (e.g. from History), use its date but current time
        // If targetMeal is provided, use its date/time
        if let mealDate = targetMeal?.date {
            _entryDate = State(initialValue: mealDate)
        } else if let tDate = targetDate {
            let now = Date()
            let calendar = Calendar.current
            let combined = calendar.date(bySettingHour: calendar.component(.hour, from: now),
                                       minute: calendar.component(.minute, from: now),
                                       second: calendar.component(.second, from: now),
                                       of: tDate) ?? tDate
            _entryDate = State(initialValue: combined)
        } else {
            _entryDate = State(initialValue: Date())
        }
    }

    private func computedGrams() -> Double {
        switch useMode {
        case 0:
            return Double(grams) ?? 0
        default:
            let s = Double(servings) ?? 0
            return s * food.gramsPerServing
        }
    }

    private var computedMacros: (cal: Double, p: Double, f: Double, c: Double, fi: Double) {
        let g = computedGrams()
        let m = food.macrosFor(grams: g)
        return (m.calories, m.protein, m.fat, m.carbs, m.fiber)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    DatePicker("Time", selection: $entryDate)
                }

                Section(header: Text("Use As")) {
                    Picker("Mode", selection: $useMode) {
                        Text("Grams").tag(0)
                        Text("Servings").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                if useMode == 0 {
                    HStack { Text("Grams"); Spacer(); TextField("0", text: $grams).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
                } else {
                    HStack { Text("Servings (\(Int(food.gramsPerServing))g ea)"); Spacer(); TextField("1", text: $servings).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
                }

                Section(header: Text("Macros")) {
                    let m = computedMacros
                    HStack { Text("Calories"); Spacer(); Text("\(Int(m.cal)) kcal") }
                    HStack { Text("Protein"); Spacer(); Text("\(Int(m.p)) g") }
                    HStack { Text("Fat"); Spacer(); Text("\(Int(m.f)) g") }
                    HStack { Text("Carbs"); Spacer(); Text("\(Int(m.c)) g") }
                    HStack { Text("Fiber"); Spacer(); Text("\(Int(m.fi)) g") }
                }

                Section {
                    Button("Add to Log") { saveEntry(); dismiss() }
                        .frame(maxWidth: .infinity)
                    Button("Save to My Library") { saveToLibrary() }
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func saveEntry() {
        let grams = computedGrams()
        let m = food.macrosFor(grams: grams)
        let entry = FoodEntryEntity(context: viewContext)
        entry.id = UUID()
        entry.name = food.name
        entry.calories = m.calories
        entry.protein = m.protein
        entry.fat = m.fat
        entry.carbs = m.carbs
        entry.fiber = m.fiber
        entry.quantityGrams = grams
        entry.source = "built-in"
        entry.date = entryDate
        entry.meal = targetMeal
        entry.micronutrients = food.micronutrientsFor(grams: grams)
        do { try viewContext.save() } catch { print("Save error: \(error)") }
    }

    private func saveToLibrary() {
        library.addFood(food)
    }
}

// MARK: - Meal Library Tab

struct MealLibraryTabView: View {
    @ObservedObject var library: MealLibraryStore
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    var targetDate: Date? = nil
    var targetMeal: MealEntity? = nil

    @State private var query: String = ""

    private var filteredMeals: [LibraryMeal] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return library.meals.sorted { $0.name < $1.name } }
        return library.meals.filter { $0.name.lowercased().contains(q) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search meals...", text: $query)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            if filteredMeals.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.largeTitle).foregroundColor(.secondary)
                    Text(query.isEmpty ? "No meals in your library yet" : "No matches").foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(filteredMeals) { meal in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(meal.name).font(.headline)
                            Text("\(meal.items.count) items").font(.caption).foregroundColor(.secondary)
                            let totals = calculateTotals(for: meal)
                            HStack(spacing: 12) {
                                MacroChip(label: "Cal", value: String(Int(totals.cal)), unit: "kcal")
                                MacroChip(label: "P", value: String(Int(totals.p)), unit: "g")
                                MacroChip(label: "F", value: String(Int(totals.f)), unit: "g")
                                MacroChip(label: "C", value: String(Int(totals.c)), unit: "g")
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            useMeal(meal)
                            dismiss()
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { library.deleteMeal(id: meal.id) } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func calculateTotals(for meal: LibraryMeal) -> (cal: Double, p: Double, f: Double, c: Double) {
        let cal = meal.items.reduce(0) { $0 + $1.calories }
        let p = meal.items.reduce(0) { $0 + $1.protein }
        let f = meal.items.reduce(0) { $0 + $1.fat }
        let c = meal.items.reduce(0) { $0 + $1.carbs }
        return (cal, p, f, c)
    }

    private func useMeal(_ libraryMeal: LibraryMeal) {
        let mealToUse: MealEntity
        if let target = targetMeal {
            mealToUse = target
        } else {
            // Find how many meals exist for this day to name it Meal #X
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: targetDate ?? Date())
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            
            let request = NSFetchRequest<MealEntity>(entityName: "MealEntity")
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
            let existingMealCount = (try? viewContext.count(for: request)) ?? 0
            
            mealToUse = MealEntity(context: viewContext)
            mealToUse.id = UUID()
            mealToUse.name = "Meal #\(existingMealCount + 1)"
            mealToUse.date = targetDate ?? Date()
        }

        for item in libraryMeal.items {
            let entry = FoodEntryEntity(context: viewContext)
            entry.id = UUID()
            entry.name = item.foodName
            entry.calories = item.calories
            entry.protein = item.protein
            entry.fat = item.fat
            entry.carbs = item.carbs
            entry.fiber = item.fiber
            entry.quantityGrams = item.grams
            entry.source = "meal-library"
            entry.date = mealToUse.date
            entry.meal = mealToUse
            entry.micronutrients = item.micronutrients ?? MicronutrientData()
        }

        do {
            try viewContext.save()
        } catch {
            print("Error using meal from library: \(error)")
        }
    }
}

struct FoodLibraryTabView: View {
    @ObservedObject var library: FoodLibraryStore
    @Environment(\.managedObjectContext) private var viewContext
    var targetDate: Date? = nil
    var targetMeal: MealEntity? = nil

    @State private var query: String = ""
    @State private var selected: LibraryFood? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search your library...", text: $query)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            let items = library.search(query: query)
            if items.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.largeTitle).foregroundColor(.secondary)
                    Text(query.isEmpty ? "No foods in your library yet" : "No matches").foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name).font(.headline)
                            HStack(spacing: 12) {
                                MacroChip(label: "Cal", value: String(Int(item.caloriesPerServing)), unit: "kcal")
                                MacroChip(label: "P", value: String(Int(item.proteinPerServing)), unit: "g")
                                MacroChip(label: "F", value: String(Int(item.fatPerServing)), unit: "g")
                                MacroChip(label: "C", value: String(Int(item.carbsPerServing)), unit: "g")
                                Text("per \(Int(item.gramsPerServing))g").font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture { selected = item }
                        .contextMenu {
                            NavigationLink(destination: FoodLibraryEditor(library: library, editing: item)) { Text("Edit") }
                            Button(role: .destructive) { library.deleteFood(id: item.id) } label: { Text("Delete") }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { library.deleteFood(id: item.id) } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { library.deleteFood(id: items[index].id) }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $selected) { item in
            LibraryFoodUseSheet(food: item, library: library, targetDate: targetDate, targetMeal: targetMeal)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

// MARK: - Editor
struct FoodLibraryEditor: View {
    @ObservedObject var library: FoodLibraryStore
    var editing: LibraryFood? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var gramsPerServing: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var fat: String = ""
    @State private var carbs: String = ""
    @State private var fiber: String = ""

    var body: some View {
        Form {
            Section(header: Text("Food")) {
                TextField("Name", text: $name)
                HStack { Text("Grams per serving"); Spacer(); TextField("0", text: $gramsPerServing).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
            }
            Section(header: Text("Macros per serving")) {
                HStack { Text("Calories"); Spacer(); TextField("0", text: $calories).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
                HStack { Text("Protein (g)"); Spacer(); TextField("0", text: $protein).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
                HStack { Text("Fat (g)"); Spacer(); TextField("0", text: $fat).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
                HStack { Text("Carbs (g)"); Spacer(); TextField("0", text: $carbs).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
                HStack { Text("Fiber (g)"); Spacer(); TextField("0", text: $fiber).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
            }
            // Presets removed
            Section {
                Button(editing == nil ? "Save Food" : "Save Changes") { save() }
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(editing == nil ? "New Library Food" : "Edit Library Food")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    private func load() {
        guard let e = editing else { return }
        name = e.name
        gramsPerServing = e.gramsPerServing > 0 ? String(Int(e.gramsPerServing)) : ""
        calories = String(Int(e.caloriesPerServing))
        protein = String(Int(e.proteinPerServing))
        fat = String(Int(e.fatPerServing))
        carbs = String(Int(e.carbsPerServing))
        fiber = String(Int(e.fiberPerServing))
    }

    // Preset editor removed

    private func save() {
        let gps = Double(gramsPerServing) ?? 0
        let c = Double(calories) ?? 0
        let p = Double(protein) ?? 0
        let f = Double(fat) ?? 0
        let cbs = Double(carbs) ?? 0
        let fi = Double(fiber) ?? 0
        var food = LibraryFood(
            name: name,
            gramsPerServing: gps,
            caloriesPerServing: c,
            proteinPerServing: p,
            fatPerServing: f,
            carbsPerServing: cbs,
            fiberPerServing: fi
        )
        if let editing = editing {
            food = LibraryFood(
                id: editing.id,
                name: name,
                gramsPerServing: gps,
                caloriesPerServing: c,
                proteinPerServing: p,
                fatPerServing: f,
                carbsPerServing: cbs,
                fiberPerServing: fi
            )
            library.updateFood(food)
        } else {
            library.addFood(food)
        }
        dismiss()
    }
}

// MARK: - Use Sheet
struct LibraryFoodUseSheet: View {
    let food: LibraryFood
    @ObservedObject var library: FoodLibraryStore
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    var targetDate: Date? = nil
    var targetMeal: MealEntity? = nil

    @State private var grams: String = ""
    @State private var servings: String = "1"
    @State private var useMode: Int = 0 // 0 grams, 1 servings
    @State private var entryDate: Date = Date()

    init(food: LibraryFood, library: FoodLibraryStore, targetDate: Date? = nil, targetMeal: MealEntity? = nil) {
        self.food = food
        self.library = library
        self.targetDate = targetDate
        self.targetMeal = targetMeal
        
        if let mealDate = targetMeal?.date {
            _entryDate = State(initialValue: mealDate)
        } else if let tDate = targetDate {
            let now = Date()
            let calendar = Calendar.current
            let combined = calendar.date(bySettingHour: calendar.component(.hour, from: now),
                                       minute: calendar.component(.minute, from: now),
                                       second: calendar.component(.second, from: now),
                                       of: tDate) ?? tDate
            _entryDate = State(initialValue: combined)
        } else {
            _entryDate = State(initialValue: Date())
        }
    }

    private func computedGrams() -> Double {
        switch useMode {
        case 0:
            return Double(grams) ?? 0
        default:
            let s = Double(servings) ?? 0
            return s * food.gramsPerServing
        }
    }

    private var computedMacros: (cal: Double, p: Double, f: Double, c: Double, fi: Double) {
        let g = computedGrams()
        let m = food.macrosFor(grams: g)
        return (m.calories, m.protein, m.fat, m.carbs, m.fiber)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    DatePicker("Time", selection: $entryDate)
                }

                Section(header: Text("Use As")) {
                    Picker("Mode", selection: $useMode) {
                        Text("Grams").tag(0)
                        Text("Servings").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                if useMode == 0 {
                    HStack { Text("Grams"); Spacer(); TextField("0", text: $grams).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
                } else {
                    HStack { Text("Servings (\(Int(food.gramsPerServing))g ea)"); Spacer(); TextField("1", text: $servings).keyboardType(.decimalPad).multilineTextAlignment(.trailing).autoSelectText() }
                }

                Section(header: Text("Macros")) {
                    let m = computedMacros
                    HStack { Text("Calories"); Spacer(); Text("\(Int(m.cal)) kcal") }
                    HStack { Text("Protein"); Spacer(); Text("\(Int(m.p)) g") }
                    HStack { Text("Fat"); Spacer(); Text("\(Int(m.f)) g") }
                    HStack { Text("Carbs"); Spacer(); Text("\(Int(m.c)) g") }
                    HStack { Text("Fiber"); Spacer(); Text("\(Int(m.fi)) g") }
                }

                Section {
                    Button("Add to Log") { saveEntry(); dismiss() }
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { NavigationLink("Edit", destination: FoodLibraryEditor(library: library, editing: food)) } }
        }
    }

    private func saveEntry() {
        let grams = computedGrams()
        let m = food.macrosFor(grams: grams)
        let entry = FoodEntryEntity(context: viewContext)
        entry.id = UUID()
        entry.name = food.name
        entry.calories = m.calories
        entry.protein = m.protein
        entry.fat = m.fat
        entry.carbs = m.carbs
        entry.fiber = m.fiber
        entry.quantityGrams = grams
        entry.source = "library"
        entry.date = entryDate
        entry.meal = targetMeal
        entry.micronutrients = food.micronutrientsFor(grams: grams)
        do { try viewContext.save() } catch { print("Save error: \(error)") }
    }
}

struct USDASearchView: View {
    @ObservedObject var viewModel: AddFoodViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedFoodDetails: USDAFood?
    var targetDate: Date? = nil
    var targetMeal: MealEntity? = nil

    var body: some View {
        VStack(spacing: 0) {
            // ... (search bar part) ...
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search USDA database...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.webSearch)
                    .onChange(of: searchText) { _, newValue in
                        debounceSearch(newValue)
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            if let error = viewModel.errorMessage, !error.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            // Results
            if viewModel.isLoading {
                Spacer()
                ProgressView("Searching...")
                Spacer()
            } else if viewModel.results.isEmpty && !searchText.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(viewModel.errorMessage == nil ? "No results found" : "")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(viewModel.results) { food in
                    Button(action: { selectFood(food) }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(food.description)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            if let nutrients = food.foodNutrients {
                                HStack(spacing: 12) {
                                    MacroChip(label: "Cal", value: nutrientValue(nutrients, name: "Energy"), unit: "kcal")
                                    MacroChip(label: "P", value: nutrientValue(nutrients, name: "Protein"), unit: "g")
                                    MacroChip(label: "F", value: nutrientValue(nutrients, name: "Total lipid"), unit: "g")
                                    MacroChip(label: "C", value: nutrientValue(nutrients, name: "Carbohydrate"), unit: "g")
                                }
                            }
                            
                            if let dataType = food.dataType {
                                Text("Source: USDA \(dataType)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .sheet(item: $selectedFoodDetails) { food in
            FoodDetailSheet(food: food, targetDate: targetDate, targetMeal: targetMeal)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private func debounceSearch(_ query: String) {
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300 * 1_000_000)
            if !Task.isCancelled {
                viewModel.search(query)
            }
        }
    }

    private func nutrientValue(_ nutrients: [USDANutrient], name: String) -> String {
        if let nutrient = nutrients.first(where: { 
            $0.nutrientName.lowercased().contains(name.lowercased()) 
        }) {
            return String(format: "%.0f", (nutrient.value ?? 0).sanitizedNonNegativeFinite)
        }
        return "-"
    }

    private func selectFood(_ food: USDAFood) {
        // Dismiss keyboard and set selection; details will be fetched inside sheet
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        selectedFoodDetails = food
    }
}

struct MacroChip: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(.systemGray5))
        .cornerRadius(4)
    }
}

struct ManualEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var library: FoodLibraryStore
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var fiber = ""
    @State private var entryDate: Date = Date()
    var targetDate: Date? = nil
    var targetMeal: MealEntity? = nil

    let onSave: () -> Void

    init(targetDate: Date? = nil, targetMeal: MealEntity? = nil, onSave: @escaping () -> Void) {
        self.targetDate = targetDate
        self.targetMeal = targetMeal
        self.onSave = onSave
        
        if let mealDate = targetMeal?.date {
            _entryDate = State(initialValue: mealDate)
        } else if let tDate = targetDate {
            let now = Date()
            let calendar = Calendar.current
            let combined = calendar.date(bySettingHour: calendar.component(.hour, from: now),
                                       minute: calendar.component(.minute, from: now),
                                       second: calendar.component(.second, from: now),
                                       of: tDate) ?? tDate
            _entryDate = State(initialValue: combined)
        } else {
            _entryDate = State(initialValue: Date())
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                DatePicker("Time", selection: $entryDate)
            }

            Section(header: Text("Food Information")) {
                TextField("Food Name", text: $name)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }

            Section(header: Text("Macronutrients")) {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("0", text: $calories)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.trailing)
                        .autoSelectText()
                }

                HStack {
                    Text("Protein (g)")
                    Spacer()
                    TextField("0", text: $protein)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.trailing)
                        .autoSelectText()
                }

                HStack {
                    Text("Fat (g)")
                    Spacer()
                    TextField("0", text: $fat)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.trailing)
                        .autoSelectText()
                }

                HStack {
                    Text("Carbs (g)")
                    Spacer()
                    TextField("0", text: $carbs)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.trailing)
                        .autoSelectText()
                }

                HStack {
                    Text("Fiber (g)")
                    Spacer()
                    TextField("0", text: $fiber)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.trailing)
                        .autoSelectText()
                }
            }

            Section {
                Button("Save Food") {
                    saveManualEntry()
                    onSave()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
                .disabled(name.isEmpty)

                Button("Save to My Library") {
                    presentSaveToLibrary()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
        }
    }

    private func saveManualEntry() {
        let entry = FoodEntryEntity(context: viewContext)
        entry.id = UUID()
        entry.name = name
        entry.calories = Double(calories) ?? 0
        entry.protein = Double(protein) ?? 0
        entry.fat = Double(fat) ?? 0
        entry.carbs = Double(carbs) ?? 0
        entry.fiber = Double(fiber) ?? 0
        entry.quantityGrams = 0
        entry.source = "manual"
        entry.date = entryDate
        entry.meal = targetMeal

        do {
            try viewContext.save()
        } catch {
            print("Save error: \(error)")
        }
    }

    private func presentSaveToLibrary() {
        let alert = UIAlertController(title: "Save to Library", message: "Enter grams per serving for this food.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Grams per serving"
            tf.keyboardType = .decimalPad
            tf.text = "100"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let gramsText = alert.textFields?.first?.text ?? "100"
            let gps = Double(gramsText) ?? 100
            let item = LibraryFood(
                name: name.isEmpty ? "Untitled" : name,
                gramsPerServing: max(gps, 1),
                caloriesPerServing: Double(calories) ?? 0,
                proteinPerServing: Double(protein) ?? 0,
                fatPerServing: Double(fat) ?? 0,
                carbsPerServing: Double(carbs) ?? 0,
                fiberPerServing: Double(fiber) ?? 0
            )
            library.addFood(item)
        }))
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
}

#Preview {
    AddFoodView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
