package com.harirajan.streakly.widget

import com.harirajan.streakly.R
import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

/**
 * Configuration activity now delegates habit selection to the Flutter UI.
 * It starts `MainActivity` (the FlutterActivity) for result; the Flutter UI
 * must return an intent with extra `selectedHabitId` (String) when the user
 * picks a habit. That result is then saved and the widget updated.
 */
class WidgetConfigureActivity : AppCompatActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private val REQ_SELECT_HABIT = 1001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        }

        // Launch the Flutter activity for habit selection. The Flutter UI should detect
        // this launch and show a habit selection screen when it sees the extras below.
        val launch = Intent(this, Class.forName("com.example.Streakly.MainActivity"))
        launch.putExtra("WIDGET_CONFIG_MODE", true)
        launch.putExtra("APPWIDGET_ID", appWidgetId)
        // Note: Do NOT add FLAG_ACTIVITY_NEW_TASK when using startActivityForResult
        startActivityForResult(launch, REQ_SELECT_HABIT)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_SELECT_HABIT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val selectedHabitId = data.getStringExtra("selectedHabitId") ?: ""
                if (selectedHabitId.isNotEmpty() && appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    WidgetPreferences.saveMapping(this, appWidgetId, selectedHabitId)

                    val appWidgetManager = AppWidgetManager.getInstance(this)
                    HabitWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)

                    val resultValue = Intent().apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    setResult(Activity.RESULT_OK, resultValue)
                    finish()
                    return
                }
            }
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }
}
