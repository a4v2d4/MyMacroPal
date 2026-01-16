import SwiftUI

struct MacroBreakdownView: View {
    let entries: [FoodEntryEntity]
    
    var body: some View {
        List {
            breakdownSection(
                title: "Protein",
                unit: "g",
                total: entries.reduce(0) { $0 + $1.protein },
                valueProvider: { $0.protein },
                color: .green
            )
            
            breakdownSection(
                title: "Fat",
                unit: "g",
                total: entries.reduce(0) { $0 + $1.fat },
                valueProvider: { $0.fat },
                color: .orange
            )
            
            breakdownSection(
                title: "Carbs",
                unit: "g",
                total: entries.reduce(0) { $0 + $1.carbs },
                valueProvider: { $0.carbs },
                color: .purple
            )
            
            breakdownSection(
                title: "Calories",
                unit: "kcal",
                total: entries.reduce(0) { $0 + $1.calories },
                valueProvider: { $0.calories },
                color: .blue
            )
            
            breakdownSection(
                title: "Fiber",
                unit: "g",
                total: entries.reduce(0) { $0 + $1.fiber },
                valueProvider: { $0.fiber },
                color: .brown
            )
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Daily Breakdown")
    }
    
    @ViewBuilder
    private func breakdownSection(
        title: String,
        unit: String,
        total: Double,
        valueProvider: @escaping (FoodEntryEntity) -> Double,
        color: Color
    ) -> some View {
        let contributingEntries = entries
            .filter { valueProvider($0) > 0 }
            .sorted { valueProvider($0) > valueProvider($1) }
        
        Section {
            if contributingEntries.isEmpty {
                Text("No contributions for \(title.lowercased())")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(contributingEntries, id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name ?? "Unknown Food")
                                .font(.body)
                                .lineLimit(1)
                            
                            if total > 0 {
                                let percent = (valueProvider(entry) / total) * 100
                                Text("\(Int(percent))% of total")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(Int(valueProvider(entry)))\(unit)")
                            .font(.body)
                            .monospacedDigit()
                            .foregroundColor(color)
                    }
                }
            }
        } header: {
            HStack {
                Text(title)
                Spacer()
                Text("Total: \(Int(total))\(unit)")
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
    }
}

