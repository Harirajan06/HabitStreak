
import Foundation

struct WidgetData {
    // Shared Group ID - MUST match the capabilities in Xcode
    static let suiteName = "group.com.harirajan.streakly"
    static let keyHabitsData = "habits_data"
    static let keyWidgetMapping = "widget_habit_map"
    static let keyPendingActions = "pending_actions"

    static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: suiteName)
    }

    static func getWidgetMapping() -> [String: String] {
        if let jsonString = sharedDefaults?.string(forKey: keyWidgetMapping),
           let data = jsonString.data(using: .utf8),
           let mapping = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
            return mapping
        }
        return [:]
    }

    static func setWidgetMapping(appWidgetId: String, habitId: String) {
        var mapping = getWidgetMapping()
        mapping[appWidgetId] = habitId
        if let data = try? JSONSerialization.data(withJSONObject: mapping, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            sharedDefaults?.set(jsonString, forKey: keyWidgetMapping)
        }
    }
    
    // Clear mappings
    static func clearWidgetMapping(appWidgetId: String) {
        var mapping = getWidgetMapping()
        mapping.removeValue(forKey: appWidgetId)
        if let data = try? JSONSerialization.data(withJSONObject: mapping, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            sharedDefaults?.set(jsonString, forKey: keyWidgetMapping)
        }
    }

    static func saveHabitData(habitId: String, json: String) {
        var allData = getAllHabitsData()
        // Determine if we need to parse the JSON string or store it as is
        // Android stored it as a big JSON Blob.
        // Let's store a dictionary of [HabitID : JSONString] for simplicity
        allData[habitId] = json
        
        if let data = try? JSONSerialization.data(withJSONObject: allData, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            sharedDefaults?.set(jsonString, forKey: keyHabitsData)
        }
    }
    
    static func getAllHabitsData() -> [String: String] {
        if let jsonString = sharedDefaults?.string(forKey: keyHabitsData),
           let data = jsonString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
            return dict
        }
        return [:]
    }
    
    static func addPendingAction(habitId: String) {
        var actions = getPendingActions()
        actions.append(habitId)
        sharedDefaults?.set(actions, forKey: keyPendingActions)
    }
    
    static func getPendingActions() -> [String] {
        return sharedDefaults?.stringArray(forKey: keyPendingActions) ?? []
    }
    
    static func clearPendingActions() {
        sharedDefaults?.removeObject(forKey: keyPendingActions)
    }
}
