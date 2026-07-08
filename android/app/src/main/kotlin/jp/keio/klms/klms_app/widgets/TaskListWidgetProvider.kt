package jp.keio.klms.klms_app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetProvider
import jp.keio.klms.klms_app.R
import org.json.JSONArray
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/** Widget listing the next incomplete tasks with their deadlines. */
class TaskListWidgetProvider : HomeWidgetProvider() {

    private val rowIds = intArrayOf(
        R.id.task_row0, R.id.task_row1, R.id.task_row2, R.id.task_row3, R.id.task_row4,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val sub = ContextCompat.getColor(context, R.color.widgetSubText)
        val normal = ContextCompat.getColor(context, R.color.widgetText)
        val overdueColor = ContextCompat.getColor(context, R.color.widgetOverdue)
        val dueFormat = DateTimeFormatter.ofPattern("M/d HH:mm")
        val now = LocalDateTime.now()

        val tasks = try {
            JSONArray(widgetData.getString("widget_tasks", null) ?: "[]")
        } catch (_: Exception) {
            JSONArray()
        }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_task_list)
            views.setTextViewText(R.id.task_title, context.getString(R.string.widget_tasks_title))

            var row = 0
            for (i in 0 until tasks.length()) {
                if (row >= rowIds.size) break
                val task = tasks.optJSONObject(i) ?: continue
                val title = task.optString("t")
                var dueLabel = ""
                var overdue = false
                val dueRaw = task.optString("d", "")
                if (dueRaw.isNotEmpty()) {
                    try {
                        val due = LocalDateTime.parse(dueRaw.substringBefore("+").substringBefore("Z"))
                        dueLabel = "  " + due.format(dueFormat)
                        overdue = due.isBefore(now)
                    } catch (_: Exception) {
                    }
                }
                val id = rowIds[row]
                views.setTextViewText(id, "・$title$dueLabel")
                views.setTextColor(id, if (overdue) overdueColor else normal)
                views.setViewVisibility(id, View.VISIBLE)
                row++
            }
            for (i in row until rowIds.size) {
                views.setViewVisibility(rowIds[i], View.GONE)
            }
            if (row == 0) {
                views.setTextViewText(rowIds[0], context.getString(R.string.widget_no_tasks))
                views.setTextColor(rowIds[0], sub)
                views.setViewVisibility(rowIds[0], View.VISIBLE)
            }
            Timetable.launchIntent(context)?.let {
                views.setOnClickPendingIntent(R.id.widget_root, it)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
