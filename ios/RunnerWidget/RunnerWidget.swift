import WidgetKit
import SwiftUI

// iOS 17+ Widget with native habit picker
@available(iOS 17.0, *)
struct RunnerWidget17: Widget {
    let kind: String = "RunnerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: HabitSelectionAppIntent.self,
            provider: HabitWidgetTimelineProvider17()
        ) { entry in
            HabitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Widget")
        .description("Track your daily habits. Long-press to edit.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// iOS 16 Widget with manual configuration
@available(iOS 16.0, *)
struct RunnerWidget16: Widget {
    let kind: String = "RunnerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: HabitSelectionIntent.self,
            provider: HabitWidgetTimelineProvider()
        ) { entry in
            HabitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Widget")
        .description("Track your daily habits.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// iOS < 16 Widget with static configuration
struct RunnerWidgetLegacy: Widget {
    let kind: String = "RunnerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: HabitWidgetLegacyProvider()
        ) { entry in
            HabitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Widget")
        .description("Track your daily habits.")
        .supportedFamilies([.systemSmall])
    }
}
