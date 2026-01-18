import SwiftUI
import CoreData

struct MealEditView: View {
    @ObservedObject var meal: MealEntity
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var date: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meal Details")) {
                    TextField("Meal Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    DatePicker("Time", selection: $date)
                }
            }
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                name = meal.name ?? ""
                date = meal.date ?? Date()
            }
        }
    }
    
    private func save() {
        meal.name = name
        meal.date = date
        
        // Also update the date of all entries in this meal to match the meal date
        // This ensures they stay grouped correctly if the user changes the meal day
        for entry in meal.foodEntries {
            entry.date = date
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving meal edits: \(error)")
        }
    }
}
