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
                    var color = habitData.optInt("color", -1)
                    if (color == -1) color = android.graphics.Color.parseColor("#9B5DE5")
                    
                    val iconBase64 = habitData.optString("iconBase64", "")
                    val remindersPerDay = habitData.optInt("remindersPerDay", 1)
                    val dailyCompletions = habitData.optInt("dailyCompletions", 0)

                    views.setTextViewText(R.id.tv_habit_name, name)
                    views.setTextViewText(R.id.tv_habit_status, "$streak day streak")
                    
                    // Draw Progress Ring
                    val progressBitmap = drawProgressBitmap(context, 200, color, dailyCompletions, remindersPerDay, isCompleted)
                    views.setImageViewBitmap(R.id.img_ring, progressBitmap)
                    // Reset any color filter that might interfere
                    views.setInt(R.id.img_ring, "setColorFilter", 0)

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

        private fun drawProgressBitmap(
            context: Context,
            size: Int,
            color: Int,
            currentCount: Int,
            totalRequired: Int,
            isCompleted: Boolean
        ): android.graphics.Bitmap {
            val bitmap = android.graphics.Bitmap.createBitmap(size, size, android.graphics.Bitmap.Config.ARGB_8888)
            val canvas = android.graphics.Canvas(bitmap)
            val center = size / 2f
            val radius = (size - 22f) / 2f // Adjust for stroke width (20f) + padding

            val paint = android.graphics.Paint().apply {
                isAntiAlias = true
                this.color = color
                strokeCap = android.graphics.Paint.Cap.ROUND
                style = android.graphics.Paint.Style.STROKE
                strokeWidth = 20f
            }

            // Draw greyish background ring (optional, but good for visibility)
            val bgPaint = android.graphics.Paint().apply {
                 isAntiAlias = true
                 this.color = android.graphics.Color.parseColor("#33FFFFFF") 
                 style = android.graphics.Paint.Style.STROKE
                 strokeWidth = 20f
            }
            canvas.drawCircle(center, center, radius, bgPaint)

            // If effectiveCompleted, ensure we draw full ring
            val effectiveCount = if (isCompleted && currentCount < totalRequired) totalRequired else currentCount
            
            if (totalRequired <= 1) {
                 if (effectiveCount > 0) {
                    canvas.drawCircle(center, center, radius, paint)
                 }
            } else {
                // Segmented Arcs
                val rectF = android.graphics.RectF(center - radius, center - radius, center + radius, center + radius)
                val sweepAngle = 360f / totalRequired
                val gap = 6f // degrees gap
                
                for (i in 0 until effectiveCount) {
                    val startAngle = (i * sweepAngle) - 90f
                    // If it's a full circle (no gaps needed if fully complete? No, user likes segments probably)
                    // Actually, if it's strictly segmented, let's keep gaps.
                    canvas.drawArc(rectF, startAngle, sweepAngle - gap, false, paint)
                }
            }
            return bitmap
        }
    }
}
