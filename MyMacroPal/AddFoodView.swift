import SwiftUI
import CoreData
import UIKit

struct AddFoodView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddFoodViewModel()
    @State private var selectedTab = 0
    var targetDate: Date? = nil

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
                    USDASearchView(viewModel: viewModel, targetDate: targetDate)
                } else {
                    ManualEntryView(targetDate: targetDate) {
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

struct FoodDetailSheet: View {
    let food: USDAFood
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var detailViewModel: FoodDetailViewModel?
    @State private var loadError: String?
    @State private var isFetchingDetails = false
    var targetDate: Date? = nil

    var body: some View {
        ZStack {
            Group {
                if let vm = detailViewModel {
                    FoodDetailView(viewModel: vm, targetDate: targetDate)
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

struct USDASearchView: View {
    @ObservedObject var viewModel: AddFoodViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedFoodDetails: USDAFood?
    var targetDate: Date? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search USDA database...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.webSearch)
                    .onChange(of: searchText) { newValue in
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
            FoodDetailSheet(food: food, targetDate: targetDate)
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
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var fiber = ""
    var targetDate: Date? = nil

    let onSave: () -> Void

    var body: some View {
        Form {
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
                }

                HStack {
                    Text("Protein (g)")
                    Spacer()
                    TextField("0", text: $protein)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Fat (g)")
                    Spacer()
                    TextField("0", text: $fat)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Carbs (g)")
                    Spacer()
                    TextField("0", text: $carbs)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Fiber (g)")
                    Spacer()
                    TextField("0", text: $fiber)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled(true)
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
        entry.date = targetDate ?? Date()

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
