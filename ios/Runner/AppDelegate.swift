import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    if let url = launchOptions?[.url] as? URL, url.absoluteString == "streakly://configure" {
        self.isConfiguringWidget = true
    }
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.harirajan.streakly/widget",
                                              binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
        let sharedDefaults = UserDefaults(suiteName: "group.com.harirajan.streakly")
        let keyHabitsData = "habits_data"
        let keyWidgetMapping = "widget_habit_map"
        let keyPendingActions = "pending_actions"

      if call.method == "setWidgetMapping" || call.method == "updateWidgetForHabit" {
          // Both do roughly the same: Save data.
          if let args = call.arguments as? [String: Any],
             let habitId = args["habitId"] as? String ?? (args["habit"] as? String).flatMap { try? JSONSerialization.jsonObject(with: $0.data(using: .utf8)!, options: []) as? [String: Any] }?["id"] as? String,
             let habitJson = args["habit"] as? String {
              
              // 1. Save Habit Data
              var allData: [String: String] = [:]
              if let jsonString = sharedDefaults?.string(forKey: keyHabitsData),
                 let data = jsonString.data(using: .utf8) {
                  allData = (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]) ?? [:]
              }
              allData[habitId] = habitJson
              if let outData = try? JSONSerialization.data(withJSONObject: allData, options: []),
                 let outString = String(data: outData, encoding: .utf8) {
                  sharedDefaults?.set(outString, forKey: keyHabitsData)
              }
              
              // 2. Set Mapping (if appWidgetId provided) - On iOS 'appWidgetId' is essentially the 'kind' family or specific instance if configurable.
              // Logic check: iOS Widgets pull their own configuration via Intent. MethodChannel "setWidgetMapping" is primarily Android concept.
              // However, "updateWidgetForHabit" is crucial.
              
              if #available(iOS 14.0, *) {
                  WidgetCenter.shared.reloadAllTimelines()
              }
          }
          result(nil)
          return
      } else if call.method == "getPendingActions" {
          let actions = sharedDefaults?.stringArray(forKey: keyPendingActions) ?? []
          result(actions)
          return
      } else if call.method == "clearPendingActions" {
          sharedDefaults?.removeObject(forKey: keyPendingActions)
          result(nil)
          return
      } else if call.method == "finishWithSelectedHabit" {
          if let args = call.arguments as? [String: Any],
             let habitId = args["habitId"] as? String,
             let habitJson = args["habit"] as? String {
              
              print("📱 finishWithSelectedHabit called with habitId: \(habitId)")
              
              // 1. Save Habit Data
              var allData: [String: String] = [:]
              if let jsonString = sharedDefaults?.string(forKey: keyHabitsData),
                 let data = jsonString.data(using: .utf8) {
                  allData = (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]) ?? [:]
              }
              allData[habitId] = habitJson
              
              if let outData = try? JSONSerialization.data(withJSONObject: allData, options: []),
                 let outString = String(data: outData, encoding: .utf8) {
                  sharedDefaults?.set(outString, forKey: keyHabitsData)
                  print("✅ Saved habit data for: \(habitId)")
              }
              
              // 2. Save as current widget habit (single widget system)
              sharedDefaults?.set(habitId, forKey: "current_widget_habit_id")
              print("✅ Saved current_widget_habit_id: \(habitId)")
              
              // 3. Save configuration timestamp (to detect new widgets)
              let currentTime = Date().timeIntervalSince1970
              sharedDefaults?.set(currentTime, forKey: "widget_last_config_time")
              print("✅ Saved widget_last_config_time: \(currentTime)")
              
              // 4. Also save to mapping for backward compatibility
              let dummyWidgetId = "1001"
              var mapping: [String: String] = [:]
               if let jsonString = sharedDefaults?.string(forKey: keyWidgetMapping),
                  let data = jsonString.data(using: .utf8) {
                   mapping = (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]) ?? [:]
               }
              mapping[dummyWidgetId] = habitId
              
              if let outData = try? JSONSerialization.data(withJSONObject: mapping, options: []),
                 let outString = String(data: outData, encoding: .utf8) {
                  sharedDefaults?.set(outString, forKey: keyWidgetMapping)
                  print("✅ Saved widget mapping: \(dummyWidgetId) -> \(habitId)")
              }
              
              // 5. Force synchronization to disk
              sharedDefaults?.synchronize()
              print("💾 Synchronized UserDefaults")
              
              // 6. Reload widgets immediately
              if #available(iOS 14.0, *) {
                  WidgetCenter.shared.reloadAllTimelines()
                  print("🔄 Reloaded all widget timelines")
              }
              result(true)
          } else {
              result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
          }
          return
      }
      
      else if call.method == "notifyHabitDeleted" {
          if let args = call.arguments as? [String: Any],
             let habitId = args["habitId"] as? String {
              
              // 1. Remove habit data
              if let jsonString = sharedDefaults?.string(forKey: keyHabitsData),
                 let data = jsonString.data(using: .utf8),
                 var allData = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                  
                  allData.removeValue(forKey: habitId)
                  
                  if let outData = try? JSONSerialization.data(withJSONObject: allData),
                     let outString = String(data: outData, encoding: .utf8) {
                      sharedDefaults?.set(outString, forKey: keyHabitsData)
                  }
              }
              
              // 2. Remove mappings to this habit
              if let jsonString = sharedDefaults?.string(forKey: keyWidgetMapping),
                 let data = jsonString.data(using: .utf8),
                 var mapping = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                  
                  mapping = mapping.filter { $0.value != habitId }
                  
                  if let outData = try? JSONSerialization.data(withJSONObject: mapping),
                     let outString = String(data: outData, encoding: .utf8) {
                      sharedDefaults?.set(outString, forKey: keyWidgetMapping)
                  }
              }
              
              // 3. Reload widgets
              if #available(iOS 14.0, *) {
                  WidgetCenter.shared.reloadAllTimelines()
              }
          }
          result(nil)
          return
      }
      
      else if call.method == "getWidgetConfig" {
          print("📱 getWidgetConfig called, isConfiguringWidget: \(self.isConfiguringWidget)")
          
          // Check if we're in widget configuration mode
          if self.isConfiguringWidget {
              // Reset flag to avoid repeated triggers
              self.isConfiguringWidget = false
              
              // Return configuration mode with dummy widget ID (single widget system)
              result(["mode": true, "appWidgetId": 1001])
              print("✅ Returned config mode: true, appWidgetId: 1001, flag reset")
          } else {
              // Not in configuration mode
              result(["mode": false])
              print("✅ Returned config mode: false")
          }
          return
      }
      
      else if call.method == "clearWidgetConfig" {
          print("📱 clearWidgetConfig called")
          
          // Clear current widget habit ID
          sharedDefaults?.removeObject(forKey: "current_widget_habit_id")
          sharedDefaults?.synchronize()
          print("✅ Cleared current_widget_habit_id")
          
          // Reload widgets to show empty state
          if #available(iOS 14.0, *) {
              WidgetCenter.shared.reloadAllTimelines()
              print("🔄 Reloaded widget timelines")
          }
          
          result(true)
          return
      }
      
      result(FlutterMethodNotImplemented)
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  var isConfiguringWidget = false

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      print("📱 App opened with URL: \(url.absoluteString)")
      if url.absoluteString == "streakly://configure" {
          isConfiguringWidget = true
          print("✅ Set isConfiguringWidget = true")
          
          // Notify Flutter immediately if app is already active
          if UIApplication.shared.applicationState == .active {
              notifyFlutterOfWidgetConfig()
          }
          return true
      }
      return super.application(app, open: url, options: options)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
      print("📱 App became active, isConfiguringWidget: \(isConfiguringWidget)")
      
      // Always check for pending widget configuration when app becomes active
      if isConfiguringWidget {
          // Trigger immediately - flag will be reset in getWidgetConfig
          notifyFlutterOfWidgetConfig()
      }
  }
  
  private func notifyFlutterOfWidgetConfig() {
      guard let controller = window?.rootViewController as? FlutterViewController else {
          print("⚠️ Could not get FlutterViewController")
          return
      }
      
      let channel = FlutterMethodChannel(
          name: "com.harirajan.streakly/widget",
          binaryMessenger: controller.binaryMessenger
      )
      
      print("🔔 Invoking triggerWidgetConfig on Flutter side")
      channel.invokeMethod("triggerWidgetConfig", arguments: nil)
  }
}
