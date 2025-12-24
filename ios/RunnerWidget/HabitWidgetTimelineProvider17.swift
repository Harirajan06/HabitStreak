//
//  HabitWidgetTimelineProvider17.swift
//  RunnerWidget
//
//  Timeline provider for iOS 17+ with HabitSelectionAppIntent
//

import WidgetKit
import SwiftUI

@available(iOS 17.0, *)
struct HabitWidgetTimelineProvider17: AppIntentTimelineProvider {
    typealias Entry = HabitEntry
    typealias Intent = HabitSelectionAppIntent
    
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habitData: nil, isConfigured: false)
    }

    func snapshot(for configuration: HabitSelectionAppIntent, in context: Context) async -> HabitEntry {
        return getEntry(for: configuration)
    }

    func timeline(for configuration: HabitSelectionAppIntent, in context: Context) async -> Timeline<HabitEntry> {
        let entry = getEntry(for: configuration)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        return timeline
    }
    
    private func getEntry(for configuration: HabitSelectionAppIntent) -> HabitEntry {
        // Check if user selected a habit in widget configuration
        if let habitEntity = configuration.habit {
            let habitId = habitEntity.id
            print("📱 iOS 17+ widget using habit: \(habitEntity.displayString) (ID: \(habitId))")
            
            // Load habit data from shared UserDefaults
            if let allData = WidgetData.getAllHabitsData()[habitId],
               let data = allData.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("✅ Loaded habit data for: \(habitId)")
                return HabitEntry(date: Date(), habitData: json, isConfigured: true)
            } else {
                print("⚠️ Habit data not found for: \(habitId)")
            }
        }
        
        // No habit selected - show empty state
        print("📱 iOS 17+ widget: No habit selected, showing empty state")
        return HabitEntry(date: Date(), habitData: nil, isConfigured: false)
    }
}
