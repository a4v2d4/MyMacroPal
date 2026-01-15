import SwiftUI

struct SettingsView: View {
    @State private var calories = UserDefaults.shared.double(forKey: "goalCalories", default: 2000)
    @State private var protein = UserDefaults.shared.double(forKey: "goalProtein", default: 150)
    @State private var fat = UserDefaults.shared.double(forKey: "goalFat", default: 70)
    @State private var carbs = UserDefaults.shared.double(forKey: "goalCarbs", default: 250)
    @State private var fiber = UserDefaults.shared.double(forKey: "goalFiber", default: 30)
    @State private var showingSaveAlert = false

    var body: some View {
        Form {
            Section(header: Text("Daily Macro Goals")) {
                VStack(spacing: 16) {
                    MacroGoalRow(
                        label: "Calories",
                        value: $calories,
                        unit: "kcal",
                        color: .blue,
                        icon: "flame.fill"
                    )
                    
                    MacroGoalRow(
                        label: "Protein",
                        value: $protein,
                        unit: "g",
                        color: .green,
                        icon: "dumbbell.fill"
                    )
                    
                    MacroGoalRow(
                        label: "Fat",
                        value: $fat,
                        unit: "g",
                        color: .orange,
                        icon: "drop.fill"
                    )
                    
                    MacroGoalRow(
                        label: "Carbs",
                        value: $carbs,
                        unit: "g",
                        color: .purple,
                        icon: "leaf.fill"
                    )
                    
                    MacroGoalRow(
                        label: "Fiber",
                        value: $fiber,
                        unit: "g",
                        color: .brown,
                        icon: "leaf.circle.fill"
                    )
                }
                .padding(.vertical, 8)
            }

            Section {
                Button(action: saveGoals) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Goals")
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .listRowBackground(Color.clear)
            }
            
            Section(header: Text("Micronutrient Daily Values"), 
                    footer: Text("Based on FDA Daily Value standards for adults. These values are used to calculate % Daily Value (DV) for each micronutrient.")) {
                NavigationLink(destination: MicronutrientDailyValuesView()) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("View Daily Values Reference")
                        Spacer()
                    }
                }
            }

            Section(header: Text("About"), footer: Text("MyMacroPal - Simple macro tracking without subscriptions")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("USDA API")
                        Spacer()
                        Text("FoodData Central")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Data Storage")
                        Spacer()
                        Text("Local (Core Data)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Goals Saved", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text("Your daily macro goals have been updated.")
        }
    }

    private func saveGoals() {
        UserDefaults.shared.set(calories, forKey: "goalCalories")
        UserDefaults.shared.set(protein, forKey: "goalProtein")
        UserDefaults.shared.set(fat, forKey: "goalFat")
        UserDefaults.shared.set(carbs, forKey: "goalCarbs")
        UserDefaults.shared.set(fiber, forKey: "goalFiber")
        
        showingSaveAlert = true
    }
}

struct MacroGoalRow: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let color: Color
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            TextField("0", value: $value, formatter: NumberFormatter())
                .keyboardType(.decimalPad)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .textFieldStyle(.roundedBorder)
                .autoSelectText()
            
            Text(unit)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

struct MicronutrientDailyValuesView: View {
    var body: some View {
        List {
            ForEach(MicronutrientCategory.allCases, id: \.self) { category in
                Section(header: Text(category.rawValue)) {
                    ForEach(Micronutrient.allCases.filter { $0.category == category }) { nutrient in
                        HStack {
                            Text(nutrient.rawValue)
                                .font(.subheadline)
                            Spacer()
                            Text("\(formatValue(nutrient.dailyValue)) \(nutrient.unit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if nutrient.isLimitNutrient {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Daily Value Standards")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0f", value)
        } else if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
