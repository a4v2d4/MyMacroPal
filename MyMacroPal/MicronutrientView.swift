import SwiftUI

// MARK: - Micronutrient Display View
struct MicronutrientView: View {
    let micronutrients: MicronutrientData
    @State private var expandedCategories: Set<MicronutrientCategory> = []
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(MicronutrientCategory.allCases, id: \.self) { category in
                MicronutrientCategorySection(
                    category: category,
                    micronutrients: micronutrients,
                    isExpanded: expandedCategories.contains(category),
                    onToggle: {
                        if expandedCategories.contains(category) {
                            expandedCategories.remove(category)
                        } else {
                            expandedCategories.insert(category)
                        }
                    }
                )
            }
        }
    }
}

struct MicronutrientCategorySection: View {
    let category: MicronutrientCategory
    let micronutrients: MicronutrientData
    let isExpanded: Bool
    let onToggle: () -> Void
    
    private var nutrients: [Micronutrient] {
        Micronutrient.allCases.filter { $0.category == category }
    }
    
    private var categoryProgress: Double {
        let percentages = nutrients.map { micronutrients.percentage(for: $0) }
        let totalPercentages = percentages.reduce(0, +)
        let averagePercentage = percentages.isEmpty ? 0 : totalPercentages / Double(percentages.count)
        return min(averagePercentage / 100.0, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category header
            Button(action: onToggle) {
                HStack {
                    Text(category.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(categoryProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Expanded nutrient list
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(nutrients) { nutrient in
                        MicronutrientRow(
                            nutrient: nutrient,
                            value: micronutrients[nutrient],
                            percentage: micronutrients.percentage(for: nutrient)
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct MicronutrientRow: View {
    let nutrient: Micronutrient
    let value: Double
    let percentage: Double
    
    private var progress: Double {
        min(percentage / 100.0, 1.0)
    }
    
    private var barColor: Color {
        if nutrient.isLimitNutrient {
            // For limit nutrients (sodium, sugar, etc), show warning colors
            if percentage > 100 { return .red }
            if percentage > 80 { return .orange }
            return .green
        } else {
            // For goal nutrients, show encouraging colors
            if percentage >= 100 { return .green }
            if percentage >= 50 { return .blue }
            return .orange
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(nutrient.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", value))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(nutrient.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(Int(percentage))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(barColor)
                    .frame(width: 50, alignment: .trailing)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(barColor)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
    }
}

// MARK: - Compact Summary View
struct MicronutrientSummaryView: View {
    let micronutrients: MicronutrientData
    let highlights: [Micronutrient]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Key Micronutrients")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(highlights) { nutrient in
                MicronutrientRow(
                    nutrient: nutrient,
                    value: micronutrients[nutrient],
                    percentage: micronutrients.percentage(for: nutrient)
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    var sampleData = MicronutrientData()
    sampleData[.vitaminA] = 450 // 50% DV
    sampleData[.vitaminC] = 90 // 100% DV
    sampleData[.calcium] = 650 // 50% DV
    sampleData[.iron] = 9 // 50% DV
    sampleData[.sodium] = 2760 // 120% DV (over limit)
    
    return ScrollView {
        VStack(spacing: 20) {
            MicronutrientView(micronutrients: sampleData)
                .padding()
            
            MicronutrientSummaryView(
                micronutrients: sampleData,
                highlights: [.vitaminC, .calcium, .iron, .sodium]
            )
            .padding()
        }
    }
}

