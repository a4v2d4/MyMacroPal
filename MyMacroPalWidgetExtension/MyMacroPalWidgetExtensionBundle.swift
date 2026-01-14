//
//  MyMacroPalWidgetExtensionBundle.swift
//  MyMacroPalWidgetExtension
//
//  Created by Aaron Van Doren on 1/14/26.
//

import WidgetKit
import SwiftUI

@main
struct MyMacroPalWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        // Legacy widget for backward compatibility
        MyMacroPalWidget()
        
        // All macros widgets
        AllMacrosWidget()          // Medium size - 4 macros
        AllMacrosSmallWidget()     // Small size - 4 macros compact
        
        // Individual macro widgets (Small size)
        CaloriesWidget()
        ProteinWidget()
        CarbsWidget()
        FatWidget()
        
        // Dual macro widget (Small size)
        CaloriesProteinWidget()
    }
}
