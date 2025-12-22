package com.example.Streakly.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.Streakly.R
import android.app.PendingIntent
import android.content.Intent

class HabitWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val ACTION_COMPLETE = "com.example.Streakly.widget.ACTION_COMPLETE"
        const val EXTRA_HABIT_ID = "habit_id"
        const val EXTRA_APPWIDGET_ID = AppWidgetManager.EXTRA_APPWIDGET_ID

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Use WidgetStorage to get mapping
            val mapping = WidgetStorage.getWidgetMapping(context)
            val habitId = mapping[appWidgetId]
            
            val views = RemoteViews(context.packageName, R.layout.widget_habit)
            
            if (habitId.isNullOrEmpty()) {
                // State A: Not configured
                views.setViewVisibility(R.id.container_state_a, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.container_state_b, android.view.View.GONE)
                
                // Clicking launches WidgetConfigureActivity
                val intent = Intent(context, WidgetConfigureActivity::class.java)
                intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                
                val pendingIntent = PendingIntent.getActivity(
                    context, 
                    appWidgetId, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                views.setOnClickPendingIntent(R.id.container_state_a, pendingIntent)
                views.setOnClickPendingIntent(R.id.btn_add_habit, pendingIntent)
            } else {
                // State B: Configured - Load Data
                views.setViewVisibility(R.id.container_state_a, android.view.View.GONE)
                views.setViewVisibility(R.id.container_state_b, android.view.View.VISIBLE)

                val habitData = WidgetStorage.getHabitData(context, habitId)
                if (habitData != null) {
                    val name = habitData.optString("name", "Habit")
                    val streak = habitData.optInt("currentStreak", 0)
                    val isCompleted = habitData.optBoolean("isCompletedToday", false)
                    val color = habitData.optInt("color", -1)
                    val iconBase64 = habitData.optString("iconBase64", "")

                    views.setTextViewText(R.id.tv_habit_name, name)
                    views.setTextViewText(R.id.tv_habit_status, "$streak day streak")
                    
                    // Apply Color to Ring
                    // Logic: If NOT completed -> GRAY. If completed -> Habit Color.
                    if (color != -1 && color != 0) {
                        if (isCompleted) {
                             views.setInt(R.id.img_ring, "setColorFilter", color)
                        } else {
                             // Use Gray for incomplete state
                             views.setInt(R.id.img_ring, "setColorFilter", android.graphics.Color.parseColor("#444444"))
                        }
                    }

                    // Set Icon
                    if (iconBase64.isNotEmpty()) {
                        try {
                            val decodedBytes = android.util.Base64.decode(iconBase64, android.util.Base64.DEFAULT)
                            val bitmap = android.graphics.BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
                            views.setImageViewBitmap(R.id.btn_complete_icon, bitmap)
                            views.setViewVisibility(R.id.btn_complete_icon, android.view.View.VISIBLE)
                            
                        } catch (e: Exception) {
                            e.printStackTrace()
                            views.setViewVisibility(R.id.btn_complete_icon, android.view.View.GONE)
                        }
                    } else {
                        // Fallback if no icon
                         views.setViewVisibility(R.id.btn_complete_icon, android.view.View.GONE)
                    }
                } else {
                    views.setTextViewText(R.id.tv_habit_name, "Error loading")
                    views.setTextViewText(R.id.tv_habit_status, "")
                }
                
                // Clicking "Complete" button sends broadcast
                val intent = Intent(context, WidgetUpdateReceiver::class.java).apply {
                    action = ACTION_COMPLETE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    putExtra(EXTRA_HABIT_ID, habitId) // IMPORTANT: Send habitId
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    appWidgetId,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_complete_frame, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
