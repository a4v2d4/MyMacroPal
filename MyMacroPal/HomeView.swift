import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: HomeViewModel
    @State private var showAddFood = false

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: PersistenceController.shared.container.viewContext))
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

                Spacer()

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
                AddFoodView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
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

struct MacroRow: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(value))/\(Int(goal))")
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
