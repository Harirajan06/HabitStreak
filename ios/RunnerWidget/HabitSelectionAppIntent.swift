//
//  HabitSelectionAppIntent.swift
//  RunnerWidget
//
//  iOS 17+ App Intent for widget configuration
//

import WidgetKit
import AppIntents

// MARK: - App Intent for iOS 17+

@available(iOS 17.0, *)
struct HabitSelectionAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Habit"
    static var description = IntentDescription("Choose which habit to track on this widget")
    
    @Parameter(title: "Habit")
    var habit: HabitEntity?
}

// MARK: - Habit Entity

@available(iOS 17.0, *)
struct HabitEntity: AppEntity {
    var id: String
    var displayString: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Habit")
    }
    
    static var defaultQuery = HabitQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }
}

// MARK: - Habit Query

@available(iOS 17.0, *)
struct HabitQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        let allHabits = loadHabitsFromUserDefaults()
        return allHabits.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [HabitEntity] {
        return loadHabitsFromUserDefaults()
    }
    
    // Helper to load habits from shared UserDefaults
    private func loadHabitsFromUserDefaults() -> [HabitEntity] {
        // Use WidgetData helper to ensure correct suite and keys are used
        let habitsDict = WidgetData.getAllHabitsData()
        print("📱 AppIntent: Loaded \(habitsDict.count) raw habits from WidgetData")
        
        var habits: [HabitEntity] = []
        
        for (habitId, habitJson) in habitsDict {
            if let habitData = habitJson.data(using: .utf8),
               let habitDict = try? JSONSerialization.jsonObject(with: habitData) as? [String: Any],
               let name = habitDict["name"] as? String {
                
                let entity = HabitEntity(id: habitId, displayString: name)
                habits.append(entity)
            }
        }
        
        print("✅ AppIntent: Prepared \(habits.count) habit entities")
        return habits.sorted { $0.displayString < $1.displayString }
    }
}
