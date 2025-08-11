//
//  ContentView.swift
//  MyMacroPal
//
//  Created by Aaron Van Doren on 8/9/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "house")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environment(\.managedObjectContext, viewContext)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
