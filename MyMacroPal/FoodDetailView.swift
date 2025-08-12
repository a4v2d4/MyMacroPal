import SwiftUI
import CoreData

struct FoodDetailView: View {
    @ObservedObject var viewModel: FoodDetailViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: FoodLibraryStore
    var targetDate: Date? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Food title and source
                    VStack(spacing: 8) {
                        Text(viewModel.food.description)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if let dataType = viewModel.food.dataType {
                            Text("Source: USDA \(dataType)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Serving size selection
                    VStack(spacing: 16) {
                        Text("Serving Size")
                            .font(.headline)
                        
                        HStack {
                            TextField("100", value: $viewModel.chosenGrams, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .onChange(of: viewModel.chosenGrams) { _, newValue in
                                    viewModel.calculate(for: newValue)
                                }
                            
                            Text("grams")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Quick portion buttons
                            if let portions = viewModel.food.foodPortions {
                                Menu("Quick Portions") {
                                    ForEach(portions.prefix(5), id: \.measureUnitName) { portion in
                                        if let unitName = portion.measureUnitName,
                                           let gramWeight = portion.gramWeight {
                                            Button("\(unitName) (\(Int(gramWeight))g)") {
                                                let safeWeight = max(0, (gramWeight.isFinite ? gramWeight : 0))
                                                viewModel.chosenGrams = safeWeight
                                                viewModel.calculate(for: safeWeight)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Macro display
                    VStack(spacing: 16) {
                        Text("Macronutrients")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            MacroDetailRow(
                                label: "Calories",
                                value: viewModel.calculatedCalories,
                                unit: "kcal",
                                color: .blue
                            )
                            
                            MacroDetailRow(
                                label: "Protein",
                                value: viewModel.calculatedProtein,
                                unit: "g",
                                color: .green
                            )
                            
                            MacroDetailRow(
                                label: "Fat",
                                value: viewModel.calculatedFat,
                                unit: "g",
                                color: .orange
                            )
                            
                            MacroDetailRow(
                                label: "Carbs",
                                value: viewModel.calculatedCarbs,
                                unit: "g",
                                color: .purple
                            )
                            
                            MacroDetailRow(
                                label: "Fiber",
                                value: viewModel.calculatedFiber,
                                unit: "g",
                                color: .brown
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Primary save to log button
                    Button(action: {
                        saveEntry()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(targetDate == nil ? "Add to Today's Log" : "Add to Selected Day")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Secondary save to library button
                    Button(action: { saveToLibrary() }) {
                        HStack {
                            Image(systemName: "books.vertical")
                            Text("Save to My Library")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding([.horizontal, .bottom])
                }
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveEntry() {
        let entry = FoodEntryEntity(context: viewContext)
        entry.id = UUID()
        entry.name = viewModel.food.description
        entry.calories = viewModel.calculatedCalories
        entry.protein = viewModel.calculatedProtein
        entry.fat = viewModel.calculatedFat
        entry.carbs = viewModel.calculatedCarbs
        entry.fiber = viewModel.calculatedFiber
        entry.quantityGrams = viewModel.chosenGrams
        entry.source = "usda"
        entry.fdcId = Int64(viewModel.food.fdcId)
        entry.date = targetDate ?? Date()

        do {
            try viewContext.save()
        } catch {
            print("Save error: \(error)")
        }
    }

    private func saveToLibrary() {
        let servingGrams = max(viewModel.chosenGrams, 1)
        let item = LibraryFood(
            name: viewModel.food.description,
            gramsPerServing: servingGrams,
            caloriesPerServing: viewModel.calculatedCalories,
            proteinPerServing: viewModel.calculatedProtein,
            fatPerServing: viewModel.calculatedFat,
            carbsPerServing: viewModel.calculatedCarbs,
            fiberPerServing: viewModel.calculatedFiber
        )
        library.addFood(item)
    }
}

struct MacroDetailRow: View {
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

#Preview {
    let sampleFood = USDAFood(
        fdcId: 123,
        description: "Chicken breast, cooked, skinless",
        dataType: "SR Legacy",
        foodNutrients: [
            USDANutrient(nutrientName: "Energy", value: 165, unitName: "KCAL"),
            USDANutrient(nutrientName: "Protein", value: 31.02, unitName: "G"),
            USDANutrient(nutrientName: "Total lipid (fat)", value: 3.57, unitName: "G"),
            USDANutrient(nutrientName: "Carbohydrate, by difference", value: 0.00, unitName: "G"),
            USDANutrient(nutrientName: "Fiber, total dietary", value: 0.00, unitName: "G")
        ],
        foodPortions: [
            USDAPortion(measureUnitName: "gram", gramWeight: 1),
            USDAPortion(measureUnitName: "cup, chopped or diced", gramWeight: 140)
        ]
    )
    
    FoodDetailView(viewModel: FoodDetailViewModel(food: sampleFood))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(FoodLibraryStore())
}
