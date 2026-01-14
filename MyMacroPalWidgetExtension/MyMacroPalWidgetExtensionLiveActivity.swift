//
//  MyMacroPalWidgetExtensionLiveActivity.swift
//  MyMacroPalWidgetExtension
//
//  Created by Aaron Van Doren on 1/14/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MyMacroPalWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MyMacroPalWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyMacroPalWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MyMacroPalWidgetExtensionAttributes {
    fileprivate static var preview: MyMacroPalWidgetExtensionAttributes {
        MyMacroPalWidgetExtensionAttributes(name: "World")
    }
}

extension MyMacroPalWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: MyMacroPalWidgetExtensionAttributes.ContentState {
        MyMacroPalWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MyMacroPalWidgetExtensionAttributes.ContentState {
         MyMacroPalWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MyMacroPalWidgetExtensionAttributes.preview) {
   MyMacroPalWidgetExtensionLiveActivity()
} contentStates: {
    MyMacroPalWidgetExtensionAttributes.ContentState.smiley
    MyMacroPalWidgetExtensionAttributes.ContentState.starEyes
}
