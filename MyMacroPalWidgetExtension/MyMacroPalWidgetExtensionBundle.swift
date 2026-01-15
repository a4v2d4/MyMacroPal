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
        // Compact widget showing all 4 macros
        AllMacrosSmallWidget()
        
        // Individual macro widgets
        ProteinWidget()
        CaloriesWidget()
        CarbsWidget()
        FatWidget()
    }
}
