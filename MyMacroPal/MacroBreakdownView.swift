import SwiftUI

struct MacroBreakdownView: View {
    let entries: [FoodEntryEntity]
    
    var body: some View {
        List {
            Section("Macros") {
                macroSummaryRow(
                    title: "Protein",
                    total: entries.reduce(0) { $0 + $1.protein },
                    unit: "g",
                    color: .green,
                    valueProvider: { $0.protein }
                )
                macroSummaryRow(
                    title: "Fat",
                    total: entries.reduce(0) { $0 + $1.fat },
                    unit: "g",
                    color: .orange,
                    valueProvider: { $0.fat }
                )
                macroSummaryRow(
                    title: "Carbs",
                    total: entries.reduce(0) { $0 + $1.carbs },
                    unit: "g",
                    color: .purple,
                    valueProvider: { $0.carbs }
                )
                macroSummaryRow(
                    title: "Calories",
                    total: entries.reduce(0) { $0 + $1.calories },
                    unit: "kcal",
                    color: .blue,
                    valueProvider: { $0.calories }
                )
                macroSummaryRow(
                    title: "Fiber",
                    total: entries.reduce(0) { $0 + $1.fiber },
                    unit: "g",
                    color: .brown,
                    valueProvider: { $0.fiber }
                )
            }
            
            ForEach(MicronutrientCategory.allCases) { category in
                let categoryNutrients = Micronutrient.allCases.filter { $0.category == category }
                let activeNutrients = categoryNutrients.filter { nutrient in
                    entries.contains { $0.micronutrients[nutrient] > 0 }
                }
                
                if !activeNutrients.isEmpty {
                    Section(category.rawValue) {
                        ForEach(activeNutrients) { nutrient in
                            macroSummaryRow(
                                title: nutrient.rawValue,
                                total: entries.reduce(0) { $0 + $1.micronutrients[nutrient] },
                                unit: nutrient.unit,
                                color: nutrient.isLimitNutrient ? .red : .blue,
                                valueProvider: { $0.micronutrients[nutrient] }
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Daily Breakdown")
    }
    
    @ViewBuilder
    private func macroSummaryRow(
        title: String,
        total: Double,
        unit: String,
        color: Color,
        valueProvider: @escaping (FoodEntryEntity) -> Double
    ) -> some View {
        DisclosureGroup {
            let contributingEntries = entries
                .filter { valueProvider($0) > 0 }
                .sorted { valueProvider($0) > valueProvider($1) }
            
            if contributingEntries.isEmpty {
                Text("No contributions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(contributingEntries, id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name ?? "Unknown Food")
                                .font(.caption)
                                .lineLimit(1)
                            
                            HStack(spacing: 4) {
                                Text("\(Int(entry.quantityGrams))g")
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                if total > 0 {
                                    let percent = (valueProvider(entry) / total) * 100
                                    Text("• \(Int(percent))% of total")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(valueProvider(entry) >= 10 ? String(format: "%.0f", valueProvider(entry)) : String(format: "%.1f", valueProvider(entry)))\(unit)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(color)
                    }
                    .padding(.vertical, 2)
                }
            }
        } label: {
            HStack {
                Text(title)
                    .font(.body)
                Spacer()
                Text("\(Int(total))\(unit)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
        }
    }
}

