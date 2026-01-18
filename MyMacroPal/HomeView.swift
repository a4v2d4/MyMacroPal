import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var mealLibrary: MealLibraryStore
    @StateObject private var viewModel: HomeViewModel
    @State private var showAddFood = false
    @State private var selectedMeal: MealEntity?
    @State private var mealToEdit: MealEntity?
    @FetchRequest private var todayMeals: FetchedResults<MealEntity>
    @FetchRequest private var uncategorizedEntries: FetchedResults<FoodEntryEntity>
    @FetchRequest private var allTodayEntries: FetchedResults<FoodEntryEntity>

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: PersistenceController.shared.container.viewContext))
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        _todayMeals = FetchRequest(
            entity: MealEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \MealEntity.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        )
        
        _uncategorizedEntries = FetchRequest(
            entity: FoodEntryEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \FoodEntryEntity.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@ AND meal == nil", start as NSDate, end as NSDate)
        )

        _allTodayEntries = FetchRequest(
            entity: FoodEntryEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \FoodEntryEntity.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Put summary inside the list so it collapses to a pinned header when scrolling
                List {
                    Section {
                        NavigationLink(destination: MacroBreakdownView(entries: Array(allTodayEntries))) {
                            VStack(spacing: 12) {
                                MacroRow(
                                    label: "Calories",
                                    value: viewModel.totalCalories,
                                    goal: UserDefaults.shared.double(forKey: "goalCalories", default: 2000),
                                    color: .blue
                                )
                                MacroRow(
                                    label: "Protein (g)",
                                    value: viewModel.totalProtein,
                                    goal: UserDefaults.shared.double(forKey: "goalProtein", default: 150),
                                    color: .green
                                )
                                MacroRow(
                                    label: "Fat (g)",
                                    value: viewModel.totalFat,
                                    goal: UserDefaults.shared.double(forKey: "goalFat", default: 70),
                                    color: .orange
                                )
                                MacroRow(
                                    label: "Carbs (g)",
                                    value: viewModel.totalCarbs,
                                    goal: UserDefaults.shared.double(forKey: "goalCarbs", default: 250),
                                    color: .purple
                                )
                                MacroRow(
                                    label: "Fiber (g)",
                                    value: viewModel.totalFiber,
                                    goal: UserDefaults.shared.double(forKey: "goalFiber", default: 30),
                                    color: .brown
                                )
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TODAY")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(dateString(Date()))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }

                    Section {
                        NavigationLink(destination: ScrollView {
                            MicronutrientView(
                                micronutrients: viewModel.totalMicronutrients,
                                entries: Array(allTodayEntries)
                            )
                            .padding()
                        }
                        .navigationTitle("Micronutrients")
                        .navigationBarTitleDisplayMode(.inline)
                        ) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.blue)
                                Text("View Micronutrients")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    } header: {
                        Text("Vitamins & Minerals")
                    }
                    
                    ForEach(todayMeals) { meal in
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
                        } header: {
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
                                Text("Add Meal #\(todayMeals.count + 1)")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: { 
                        selectedMeal = nil
                        showAddFood = true 
                    }) {
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

                    HStack(spacing: 12) {
                        NavigationLink(destination: HistoryView()) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("History")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }

                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("MyMacroPal")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddFood) {
                AddFoodView(targetDate: Calendar.current.startOfDay(for: Date()), targetMeal: selectedMeal)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $mealToEdit) { meal in
                MealEditView(meal: meal)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                viewModel.calculateTotalsForToday()
            }
            .onChange(of: allTodayEntries.count) {
                viewModel.calculateTotalsForToday()
            }
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func addNextMeal() {
        let newMeal = MealEntity(context: viewContext)
        newMeal.id = UUID()
        newMeal.name = "Meal #\(todayMeals.count + 1)"
        newMeal.date = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error adding meal: \(error)")
        }
    }
}

extension HomeView {
    private func deleteEntries(at offsets: IndexSet, from meal: MealEntity) {
        let entries = meal.foodEntries
        for index in offsets {
            viewContext.delete(entries[index])
        }
        do { try viewContext.save() } catch { print("Delete error: \(error)") }
        viewModel.calculateTotalsForToday()
    }

    private func deleteUncategorizedItems(at offsets: IndexSet) {
        for index in offsets { viewContext.delete(uncategorizedEntries[index]) }
        do { try viewContext.save() } catch { print("Delete error: \(error)") }
        viewModel.calculateTotalsForToday()
    }
    
    private func deleteMeal(_ meal: MealEntity) {
        viewContext.delete(meal)
        do { try viewContext.save() } catch { print("Delete meal error: \(error)") }
        viewModel.calculateTotalsForToday()
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

struct MacroRow: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color

    private var progress: Double {
        let safeGoal = goal.sanitizedNonNegativeFinite
        guard safeGoal > 0 else { return 0 }
        let ratio = (value.sanitizedNonNegativeFinite) / safeGoal
        if ratio.isNaN || !ratio.isFinite { return 0 }
        return min(max(ratio, 0), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(value.sanitizedNonNegativeFinite))/\(Int(goal.sanitizedNonNegativeFinite))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("(\(Int(progress * 100))%)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
