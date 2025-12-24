
import WidgetKit
import SwiftUI

struct HabitEntry: TimelineEntry {
    let date: Date
    let habitData: [String: Any]?
    let isConfigured: Bool
    
    // Parsed properties for ease of use in View
    var name: String { habitData?["name"] as? String ?? "Habit" }
    var streak: Int { habitData?["currentStreak"] as? Int ?? 0 }
    var isCompleted: Bool { habitData?["isCompletedToday"] as? Bool ?? false }
    var colorHex: String {
        if let colorInt = habitData?["color"] as? Int {
            return String(format: "%06X", colorInt & 0xFFFFFF) // Use RGB part
        }
        return habitData?["color"] as? String ?? "#9B5DE5"
    }
    var iconBase64: String? { habitData?["iconBase64"] as? String }
    var remindersPerDay: Int { habitData?["remindersPerDay"] as? Int ?? 1 }
    var dailyCompletions: Int { habitData?["dailyCompletions"] as? Int ?? 0 }
    var isDarkMode: Bool { habitData?["isDarkMode"] as? Bool ?? true }
}

// Provider for iOS 16+ with AppIntentConfiguration
@available(iOS 16.0, *)
struct HabitWidgetTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = HabitEntry
    typealias Intent = HabitSelectionIntent
    
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habitData: nil, isConfigured: false)
    }

    func snapshot(for configuration: HabitSelectionIntent, in context: Context) async -> HabitEntry {
        return getEntry(for: configuration)
    }

    func timeline(for configuration: HabitSelectionIntent, in context: Context) async -> Timeline<HabitEntry> {
        let entry = getEntry(for: configuration)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        return timeline
    }
    
    private func getEntry(for configuration: HabitSelectionIntent) -> HabitEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.harirajan.streakly")
        
        // Check if widget was recently configured (within last 5 seconds)
        // This helps detect if this is a newly added widget vs an existing one
        let lastConfigTime = sharedDefaults?.double(forKey: "widget_last_config_time") ?? 0
        let currentTime = Date().timeIntervalSince1970
        let timeSinceConfig = currentTime - lastConfigTime
        
        // For single widget system: Check if a habit has been configured
        var habitId: String? = nil
        
        // First, try intent configuration (for manual ID entry)
        if let intentHabitId = configuration.habitId, !intentHabitId.isEmpty {
            habitId = intentHabitId
            print("📱 Using intent habitId: \(intentHabitId)")
        }
        
        // Second, try single widget storage (app-based configuration)
        // Only use stored habit if widget was configured recently OR if we have a stored habit
        if habitId == nil {
            habitId = sharedDefaults?.string(forKey: "current_widget_habit_id")
            
            if let id = habitId {
                // Check if this is a fresh widget (timeline called right after widget added)
                // If more than 10 seconds since last config, this might be a new widget
                if timeSinceConfig > 10 {
                    print("📱 Widget appears to be newly added (no recent config), showing empty state")
                    return HabitEntry(date: Date(), habitData: nil, isConfigured: false)
                }
                
                print("📱 Using current_widget_habit_id: \(id)")
            }
        }
        
        // If we have a habit ID, try to load its data
        if let habitId = habitId {
            if let allData = WidgetData.getAllHabitsData()[habitId],
               let data = allData.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("✅ Loaded habit data for: \(habitId)")
                return HabitEntry(date: Date(), habitData: json, isConfigured: true)
            } else {
                print("⚠️ Habit data not found for: \(habitId)")
            }
        }
        
        // No habit configured - show empty state
        print("📱 No habit configured, showing empty state")
        return HabitEntry(date: Date(), habitData: nil, isConfigured: false)
    }
}

// Legacy provider for iOS < 16 with StaticConfiguration
struct HabitWidgetLegacyProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habitData: nil, isConfigured: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> ()) {
        let entry = getEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
    
    private func getEntry() -> HabitEntry {
        // Fallback for iOS < 16: use first mapped habit (old behavior)
        let mapping = WidgetData.getWidgetMapping()
        
        if let firstHabitId = mapping.values.first,
           let allData = WidgetData.getAllHabitsData()[firstHabitId],
           let data = allData.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            
            return HabitEntry(date: Date(), habitData: json, isConfigured: true)
        }
        
        return HabitEntry(date: Date(), habitData: nil, isConfigured: false)
    }
}
