//
//  HabitSelectionIntent.swift
//  RunnerWidget
//
//  Created for multi-widget support
//

import WidgetKit
import AppIntents

@available(iOS 16.0, *)
struct HabitSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Habit" }
    static var description: IntentDescription { 
        IntentDescription("Choose which habit to display on this widget. You can find the Habit ID in the app by tapping on the habit.")
    }

    @Parameter(title: "Habit ID", 
               default: "",
               inputOptions: .init(
                   keyboardType: .default,
                   capitalizationType: .none,
                   autocorrect: false,
                   smartQuotes: false,
                   smartDashes: false
               ))
    var habitId: String?
    
    init() {}
    
    init(habitId: String) {
        self.habitId = habitId
    }
}
