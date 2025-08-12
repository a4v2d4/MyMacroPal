import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: HomeViewModel
    @State private var showAddFood = false
    @FetchRequest private var todayEntries: FetchedResults<FoodEntryEntity>

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: PersistenceController.shared.container.viewContext))
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        _todayEntries = FetchRequest(
            entity: FoodEntryEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \FoodEntryEntity.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Today's date header
                VStack {
                    Text("TODAY")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(dateString(Date()))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top)

                // Macro progress section
                VStack(spacing: 16) {
                    MacroRow(
                        label: "Calories",
                        value: viewModel.totalCalories,
                        goal: UserDefaults.standard.double(forKey: "goalCalories", default: 2000),
                        color: .blue
                    )
                    
                    MacroRow(
                        label: "Protein (g)",
                        value: viewModel.totalProtein,
                        goal: UserDefaults.standard.double(forKey: "goalProtein", default: 150),
                        color: .green
                    )
                    
                    MacroRow(
                        label: "Fat (g)",
                        value: viewModel.totalFat,
                        goal: UserDefaults.standard.double(forKey: "goalFat", default: 70),
                        color: .orange
                    )
                    
                    MacroRow(
                        label: "Carbs (g)",
                        value: viewModel.totalCarbs,
                        goal: UserDefaults.standard.double(forKey: "goalCarbs", default: 250),
                        color: .purple
                    )
                    
                    MacroRow(
                        label: "Fiber (g)",
                        value: viewModel.totalFiber,
                        goal: UserDefaults.standard.double(forKey: "goalFiber", default: 30),
                        color: .brown
                    )
                }
                .padding(.horizontal)

                // Today's foods list (like history day view)
                List {
                    Section("Today's Foods") {
                        if todayEntries.isEmpty {
                            Text("No food items yet").foregroundColor(.secondary).italic()
                        }
                        ForEach(todayEntries, id: \.id) { entry in
                            EditableFoodEntryRow(entry: entry)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: { showAddFood = true }) {
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
                AddFoodView(targetDate: Calendar.current.startOfDay(for: Date()))
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                viewModel.calculateTotalsForToday()
            }
            .onChange(of: todayEntries.count) {
                viewModel.calculateTotalsForToday()
            }
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

extension HomeView {
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets { viewContext.delete(todayEntries[index]) }
        do { try viewContext.save() } catch { print("Delete error: \(error)") }
        viewModel.calculateTotalsForToday()
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
