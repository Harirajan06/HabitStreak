
import AppIntents
import WidgetKit
import Foundation

@available(iOS 16.0, *)
struct ToggleCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit Completion"
    static var description = IntentDescription("Completes the habit for today.")

    @Parameter(title: "Habit ID")
    var habitId: String

    init() {}
    
    init(habitId: String) {
        self.habitId = habitId
    }

    func perform() async throws -> some IntentResult {
        // Logic similar to Android's "optimistic update"
        let allDataString = WidgetData.getAllHabitsData()
        
        if let jsonString = allDataString[habitId],
           let data = jsonString.data(using: .utf8),
           var json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            
            let remindersPerDay = json["remindersPerDay"] as? Int ?? 1
            var dailyCompletions = json["dailyCompletions"] as? Int ?? 0
            
            if dailyCompletions < remindersPerDay {
                dailyCompletions += 1
                
                json["dailyCompletions"] = dailyCompletions
                let isCompletedNow = dailyCompletions >= remindersPerDay
                let wasCompleted = json["isCompletedToday"] as? Bool ?? false
                
                json["isCompletedToday"] = isCompletedNow
                
                if isCompletedNow && !wasCompleted {
                    let currentStreak = json["currentStreak"] as? Int ?? 0
                    json["currentStreak"] = currentStreak + 1
                }
                
                // Progress
                if remindersPerDay > 0 {
                    let progress = Double(dailyCompletions) / Double(remindersPerDay)
                    json["progressPercent"] = progress
                }
                
                // Save back to UserDefaults
                if let newData = try? JSONSerialization.data(withJSONObject: json, options: []),
                   let newString = String(data: newData, encoding: .utf8) {
                    WidgetData.saveHabitData(habitId: habitId, json: newString)
                }
                
                // Pending Action for Flutter Sync
                WidgetData.addPendingAction(habitId: habitId)
                
                // Trigger Reload
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
        return .result()
    }
}
