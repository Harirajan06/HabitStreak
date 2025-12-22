package com.example.Streakly.widget

import com.example.Streakly.MainActivity

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent


class WidgetUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            HabitWidgetProvider.ACTION_COMPLETE -> {
                val habitId = intent.getStringExtra(HabitWidgetProvider.EXTRA_HABIT_ID) ?: ""
                val appWidgetId = intent.getIntExtra(HabitWidgetProvider.EXTRA_APPWIDGET_ID, -1)
                if (habitId.isNotEmpty() && appWidgetId != -1) {
                    android.util.Log.d("WidgetUpdateReceiver", "Received ACTION_COMPLETE for habit: $habitId (Widget: $appWidgetId)")
                    
                    // Immediate Update (No Worker latency)
                    WidgetStorage.toggleHabitCompletion(context, habitId)
                    
                    val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(context)
                    // Update specific widget
                    HabitWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
                    
                    // Also update any others mapped to this habit (good practice)
                    val mapping = WidgetStorage.getWidgetMapping(context)
                    val idsToUpdate = mapping.filterValues { it == habitId }.keys
                    for (id in idsToUpdate) {
                        if (id != appWidgetId) {
                             HabitWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                        }
                    }
                    
                    // Notify Flutter app if running!
                    try {
                        android.util.Log.d("WidgetUpdateReceiver", "Notifying Flutter app...")
                        MainActivity.notifyFlutter(habitId)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                } else {
                     android.util.Log.e("WidgetUpdateReceiver", "Invalid habitId or appWidgetId")
                }
            }
        }
    }
}
