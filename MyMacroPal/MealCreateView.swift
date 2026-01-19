import SwiftUI
import CoreData

struct MealCreateView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let mealNumber: Int
    
    @State private var selectedMealType: MealType = .custom
    @State private var customName: String = ""
    @State private var mealTime: Date = Date()
    @FocusState private var isTextFieldFocused: Bool
    
    enum MealType: String, CaseIterable, Identifiable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
        case preWorkout = "Pre-Workout"
        case postWorkout = "Post-Workout"
        case brunch = "Brunch"
        case lateNight = "Late Night"
        case custom = "Custom"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meal Name")) {
                    Picker("Meal Name", selection: $selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if selectedMealType == .custom {
                        TextField("Meal Name", text: $customName, prompt: Text("Meal #\(mealNumber)"))
                            .textInputAutocapitalization(.words)
                            .focused($isTextFieldFocused)
                    }
                }
                
                Section(header: Text("Time")) {
                    DatePicker("Meal Time", selection: $mealTime, displayedComponents: [.hourAndMinute])
                }
            }
            .navigationTitle("New Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createMeal()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // When custom is selected by default, focus the text field
                // and set the default value
                if selectedMealType == .custom {
                    customName = "Meal #\(mealNumber)"
                    // Delay focusing to ensure the view is fully rendered
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTextFieldFocused = true
                    }
                }
            }
            .onChange(of: selectedMealType) { oldValue, newValue in
                if newValue == .custom {
                    // When switching to custom, set default and focus
                    if customName.isEmpty {
                        customName = "Meal #\(mealNumber)"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }
            }
        }
    }
    
    private func createMeal() {
        let newMeal = MealEntity(context: viewContext)
        newMeal.id = UUID()
        
        // Set the meal name based on selection
        if selectedMealType == .custom {
            // Use custom name, or default if empty
            let trimmedName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
            newMeal.name = trimmedName.isEmpty ? "Meal #\(mealNumber)" : trimmedName
        } else {
            newMeal.name = selectedMealType.rawValue
        }
        
        // Combine today's date with the selected time
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let timeComponents = calendar.dateComponents([.hour, .minute], from: mealTime)
        newMeal.date = calendar.date(byAdding: timeComponents, to: todayStart) ?? mealTime
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error creating meal: \(error)")
        }
    }
}
