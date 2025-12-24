package com.harirajan.streakly

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.harirajan.streakly.widget.HabitWidgetProvider
import com.harirajan.streakly.widget.WidgetStorage

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.harirajan.streakly/widget_v2"

    companion object {
        var channel: MethodChannel? = null
        fun notifyFlutter(habitId: String) {
            channel?.invokeMethod("onWidgetAction", habitId)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        android.util.Log.d("StreaklyNative", "Configuring Flutter Engine with Channel: $CHANNEL")
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getWidgetConfig" -> {
                    // Start from widget config?
                    val mode = intent.getBooleanExtra("WIDGET_CONFIG_MODE", false)
                    val appWidgetId = intent.getIntExtra("APPWIDGET_ID", -1)
                    val map = HashMap<String, Any>()
                    map["mode"] = mode
                    map["appWidgetId"] = appWidgetId
                    result.success(map)
                }
                "finishWithSelectedHabit" -> {
                    val habitId = call.argument<String>("habitId")
                    val appWidgetId = call.argument<Int>("appWidgetId")
                    val habitJson = call.argument<String>("habit")
                    if (appWidgetId != null && appWidgetId != -1) {
                        if (habitId.isNullOrEmpty()) {
                            setResult(RESULT_CANCELED)
                        } else {
                            // Save mapping directly here as we have the data
                            if (habitJson != null) {
                                WidgetStorage.saveHabitData(context, habitId, habitJson)
                                WidgetStorage.setWidgetMapping(context, appWidgetId, habitId)
                            }
                            
                            val resultValue = Intent()
                            resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                            // Crucial: Pass back the habit ID so calling activity knows it succeeded
                            resultValue.putExtra("selectedHabitId", habitId)
                            setResult(RESULT_OK, resultValue)
                            
                            updateWidget(appWidgetId)
                        }
                        finish()
                    }
                    result.success(true)
                }
                "setWidgetMapping" -> {
                    val appWidgetId = call.argument<Int>("appWidgetId")
                    val habitJson = call.argument<String>("habit")
                    if (appWidgetId != null && habitJson != null) {
                        try {
                             // Parse minimal to get ID
                             // We trust passed JSON has ID.
                             val jsonObject = org.json.JSONObject(habitJson)
                             val habitId = jsonObject.optString("id")
                             
                             if (habitId.isNotEmpty()) {
                                 WidgetStorage.setWidgetMapping(context, appWidgetId, habitId)
                                 WidgetStorage.saveHabitData(context, habitId, habitJson)
                                 updateWidget(appWidgetId)
                             }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    result.success(null)
                }
                "updateWidgetForHabit" -> {
                    val habitId = call.argument<String>("habitId")
                    val habitJson = call.argument<String>("habit")
                    if (habitId != null && habitJson != null) {
                         WidgetStorage.saveHabitData(context, habitId, habitJson)
                         // Find all widgets with this habit
                         val mapping = WidgetStorage.getWidgetMapping(context)
                         val idsToUpdate = mapping.filterValues { it == habitId }.keys
                         for (id in idsToUpdate) {
                             updateWidget(id)
                         }
                    }
                    result.success(null)
                }
                "clearWidgetMapping" -> {
                    val appWidgetId = call.argument<Int>("appWidgetId")
                    if (appWidgetId != null) {
                        WidgetStorage.removeStartAppWidgetId(context, appWidgetId)
                        updateWidget(appWidgetId)
                    }
                    result.success(null)
                }
                 "notifyHabitDeleted" -> {
                    val habitId = call.argument<String>("habitId")
                    if (habitId != null) {
                        WidgetStorage.removeHabitData(context, habitId)
                        val affectedIds = WidgetStorage.clearMappingsForHabit(context, habitId)
                        for (id in affectedIds) {
                            updateWidget(id)
                        }
                    }
                    result.success(null)
                }
                "getPendingActions" -> {
                    val actions = WidgetStorage.getPendingActions(context)
                    result.success(actions)
                }
                "clearPendingActions" -> {
                    WidgetStorage.clearPendingActions(context)
                    result.success(null)
                }
                "syncValidHabitIds" -> {
                    val validIds = call.argument<List<String>>("validIds")
                    if (validIds != null) {
                        // 1. Get all stored habits
                        val storedHabits = WidgetStorage.getAllStoredHabitIds(context)
                        
                        // 2. Identify stale IDs (Stored but not in Valid list)
                        val staleIds = storedHabits.filter { !validIds.contains(it) }
                        
                        // 3. Cleanup stale data and mappings
                        val affectedWidgetIds = HashSet<Int>()
                        for (staleId in staleIds) {
                            WidgetStorage.removeHabitData(context, staleId)
                             val ids = WidgetStorage.clearMappingsForHabit(context, staleId)
                             affectedWidgetIds.addAll(ids)
                        }
                        
                        // 4. Update widgets that were displaying stale habits
                        for (id in affectedWidgetIds) {
                            updateWidget(id)
                        }
                    }
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun updateWidget(appWidgetId: Int) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        HabitWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
    }
}
