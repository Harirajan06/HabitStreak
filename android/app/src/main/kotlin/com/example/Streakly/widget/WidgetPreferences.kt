package com.example.Streakly.widget

import android.content.Context

object WidgetPreferences {
    private const val PREFS_NAME = "habit_widget_prefs"
    private const val KEY_PREFIX = "widget_"

    fun saveMapping(context: Context, appWidgetId: Int, habitId: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_PREFIX + appWidgetId, habitId).apply()
    }

    fun removeMapping(context: Context, appWidgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY_PREFIX + appWidgetId).apply()
    }

    fun getHabitId(context: Context, appWidgetId: Int): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_PREFIX + appWidgetId, "") ?: ""
    }

    fun getAllMappings(context: Context): Map<Int, Long> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val map = mutableMapOf<Int, Long>()
        for ((k, v) in prefs.all) {
            if (k.startsWith(KEY_PREFIX)) {
                val id = k.removePrefix(KEY_PREFIX).toIntOrNull()
                if (id != null && v is Long) map[id] = v
            }
        }
        return map
    }
}
