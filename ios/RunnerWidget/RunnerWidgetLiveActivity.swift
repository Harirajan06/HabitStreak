//
//  RunnerWidgetLiveActivity.swift
//  RunnerWidget
//
//  Created by APPLE on 24/12/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RunnerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RunnerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunnerWidgetAttributes.self) { context in
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

extension RunnerWidgetAttributes {
    fileprivate static var preview: RunnerWidgetAttributes {
        RunnerWidgetAttributes(name: "World")
    }
}

extension RunnerWidgetAttributes.ContentState {
    fileprivate static var smiley: RunnerWidgetAttributes.ContentState {
        RunnerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RunnerWidgetAttributes.ContentState {
         RunnerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RunnerWidgetAttributes.preview) {
   RunnerWidgetLiveActivity()
} contentStates: {
    RunnerWidgetAttributes.ContentState.smiley
    RunnerWidgetAttributes.ContentState.starEyes
}
