package com.example.Streakly.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class HabitCompleteWorker(appContext: Context, params: WorkerParameters) : CoroutineWorker(appContext, params) {

    companion object {
        const val KEY_HABIT_ID = "habit_id"
        const val KEY_APPWIDGET_ID = "appwidget_id"
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val habitId = inputData.getString(KEY_HABIT_ID) ?: ""
        val appWidgetId = inputData.getInt(KEY_APPWIDGET_ID, -1)

        try {
            if (habitId.isNotEmpty()) {
                // Optimistic Update
                WidgetStorage.toggleHabitCompletion(applicationContext, habitId)

                // Refresh Widgets
                val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
                val mapping = WidgetStorage.getWidgetMapping(applicationContext)
                val idsToUpdate = mapping.filterValues { it == habitId }.keys
                
                for (id in idsToUpdate) {
                    HabitWidgetProvider.updateAppWidget(applicationContext, appWidgetManager, id)
                }
                
                // Fallback if appWidgetId passed but not in mapping (edge case)
                if (idsToUpdate.isEmpty() && appWidgetId != -1) {
                     HabitWidgetProvider.updateAppWidget(applicationContext, appWidgetManager, appWidgetId)
                }
            }
            Result.success()
        } catch (e: Exception) {
            Result.failure()
        }
    }
}
