import SwiftUI
import CoreData

struct AddFoodView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddFoodViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Mode", selection: $selectedTab) {
                    Text("USDA Search").tag(0)
                    Text("Manual Entry").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected tab
                if selectedTab == 0 {
                    USDASearchView(viewModel: viewModel)
                } else {
                    ManualEntryView {
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
            }
        }
    }
}

struct USDASearchView: View {
    @ObservedObject var viewModel: AddFoodViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search USDA database...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { newValue in
                        debounceSearch(newValue)
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

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
                    Text("No results found")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(viewModel.results, id: \.fdcId) { food in
                    Button(action: {
                        showFoodDetail(food)
                    }) {
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
            }
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
            return String(format: "%.0f", nutrient.value ?? 0)
        }
        return "-"
    }

    private func showFoodDetail(_ food: USDAFood) {
        Task {
            do {
                let service = USDAService()
                let detailedFood = try await service.getFoodDetails(fdcId: food.fdcId)
                await MainActor.run {
                    let detailViewModel = FoodDetailViewModel(food: detailedFood)
                    let detailView = FoodDetailView(viewModel: detailViewModel)
                        .environment(\.managedObjectContext, viewContext)
                    
                    let hostingController = UIHostingController(rootView: detailView)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(hostingController, animated: true)
                    }
                }
            } catch {
                print("Error fetching food details: \(error)")
            }
        }
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
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var fiber = ""

    let onSave: () -> Void

    var body: some View {
        Form {
            Section(header: Text("Food Information")) {
                TextField("Food Name", text: $name)
            }

            Section(header: Text("Macronutrients")) {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("0", text: $calories)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Protein (g)")
                    Spacer()
                    TextField("0", text: $protein)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Fat (g)")
                    Spacer()
                    TextField("0", text: $fat)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Carbs (g)")
                    Spacer()
                    TextField("0", text: $carbs)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Fiber (g)")
                    Spacer()
                    TextField("0", text: $fiber)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
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
        entry.date = Date()

        do {
            try viewContext.save()
        } catch {
            print("Save error: \(error)")
        }
    }
}

#Preview {
    AddFoodView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
