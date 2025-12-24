package com.harirajan.streakly.widget

import android.content.Context
import org.json.JSONObject

object WidgetStorage {
    private const val PREFS_NAME = "habit_widget_prefs"
    private const val KEY_WIDGET_HABIT_MAP = "widget_habit_map"
    private const val KEY_HABITS_DATA = "habits_data"

    // Map<AppWidgetId, HabitId>
    fun getWidgetMapping(context: Context): Map<Int, String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonString = prefs.getString(KEY_WIDGET_HABIT_MAP, "{}") ?: "{}"
        val map = mutableMapOf<Int, String>()
        try {
            val json = JSONObject(jsonString)
            val keys = json.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                map[key.toInt()] = json.getString(key)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return map
    }

    fun setWidgetMapping(context: Context, appWidgetId: Int, habitId: String) {
        val map = getWidgetMapping(context).toMutableMap()
        map[appWidgetId] = habitId
        saveWidgetMapping(context, map)
    }

    fun removeStartAppWidgetId(context: Context, appWidgetId: Int) {
        val map = getWidgetMapping(context).toMutableMap()
        if (map.containsKey(appWidgetId)) {
            map.remove(appWidgetId)
            saveWidgetMapping(context, map)
        }
    }
    
    // Clear mappings for a deleted habit
    fun clearMappingsForHabit(context: Context, habitId: String): List<Int> {
        val map = getWidgetMapping(context).toMutableMap()
        val affectedWidgets = mutableListOf<Int>()
        val it = map.entries.iterator()
        while (it.hasNext()) {
            val entry = it.next()
            if (entry.value == habitId) {
                affectedWidgets.add(entry.key)
                it.remove()
            }
        }
        saveWidgetMapping(context, map)
        return affectedWidgets
    }

    private fun saveWidgetMapping(context: Context, map: Map<Int, String>) {
        val json = JSONObject()
        for ((k, v) in map) {
            json.put(k.toString(), v)
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_WIDGET_HABIT_MAP, json.toString())
            .apply()
    }

    // Habit Data Storage (JSON Blob)
    fun saveHabitData(context: Context, habitId: String, habitJson: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val allData = getHabitsData(context)
        allData.put(habitId, JSONObject(habitJson))
        prefs.edit().putString(KEY_HABITS_DATA, allData.toString()).apply()
    }

    fun getHabitData(context: Context, habitId: String): JSONObject? {
        val allData = getHabitsData(context)
        return if (allData.has(habitId)) allData.getJSONObject(habitId) else null
    }
    
    fun removeHabitData(context: Context, habitId: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val allData = getHabitsData(context)
        if (allData.has(habitId)) {
            allData.remove(habitId)
             prefs.edit().putString(KEY_HABITS_DATA, allData.toString()).apply()
        }
    }

    // Toggle completion status in local JSON for optimistic UI updates
    fun toggleHabitCompletion(context: Context, habitId: String) {
        val allData = getHabitsData(context)
        if (!allData.has(habitId)) return

        val habit = allData.getJSONObject(habitId)
        val wasCompleted = habit.optBoolean("isCompletedToday", false)
        val currentStreak = habit.optInt("currentStreak", 0)

        val remindersPerDay = habit.optInt("remindersPerDay", 1)
        var dailyCompletions = habit.optInt("dailyCompletions", 0)
        
        // Logic: Increment until Target, then Stop. No cycling.
        if (dailyCompletions < remindersPerDay) {
            dailyCompletions++
        } else {
            // Already maxed out. Do nothing.
            // Optional: You could log this or trigger a specific "Already Done" broadcast if needed, 
            // but for now, we just don't update the state which effectively ignores the click.
            return 
        }

        val isCompletedNow = dailyCompletions >= remindersPerDay
        
        // Update Streak only if we just transitioned to completed
        if (isCompletedNow && !wasCompleted) {
            habit.put("currentStreak", currentStreak + 1)
        }
        
        habit.put("isCompletedToday", isCompletedNow)
        habit.put("dailyCompletions", dailyCompletions)
        
        val progress = if (remindersPerDay > 0) (dailyCompletions.toDouble() / remindersPerDay).coerceIn(0.0, 1.0) else 0.0
        habit.put("progressPercent", progress)

        // Save Data
        allData.put(habitId, habit)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_HABITS_DATA, allData.toString()).apply()

        // Add Pending Action
        android.util.Log.d("WidgetStorage", "Toggled completion for $habitId. Saving pending action.")
        addPendingAction(context, habitId)
    }

    private fun addPendingAction(context: Context, habitId: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val actions = getPendingActions(context).toMutableList()
        actions.add(habitId)
        val joined = actions.joinToString(",")
        android.util.Log.d("WidgetStorage", "Saving pending actions: $joined")
        // Use commit() to ensure data is written immediately before app might resume
        prefs.edit().putString("pending_actions", joined).commit()
    }

    fun getPendingActions(context: Context): List<String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString("pending_actions", "") ?: ""
        android.util.Log.d("WidgetStorage", "Reading pending actions: $raw")
        return if (raw.isEmpty()) emptyList() else raw.split(",")
    }

    fun clearPendingActions(context: Context) {
        android.util.Log.d("WidgetStorage", "Clearing pending actions")
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove("pending_actions").apply()
    }

    private fun getHabitsData(context: Context): JSONObject {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonString = prefs.getString(KEY_HABITS_DATA, "{}") ?: "{}"
        return try {
            JSONObject(jsonString)
        } catch (e: Exception) {
            JSONObject()
        }
    }

    fun getAllStoredHabitIds(context: Context): List<String> {
        val allData = getHabitsData(context)
        val keysIterator = allData.keys()
        val ids = mutableListOf<String>()
        while (keysIterator.hasNext()) {
            ids.add(keysIterator.next())
        }
        return ids
    }
}
