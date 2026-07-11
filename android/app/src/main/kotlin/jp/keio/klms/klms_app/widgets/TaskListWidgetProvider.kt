package jp.keio.klms.klms_app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import jp.keio.klms.klms_app.R
import org.json.JSONArray
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/** Widget listing the next incomplete tasks with their deadlines. */
class TaskListWidgetProvider : HomeWidgetProvider() {

    private val containerIds = intArrayOf(
        R.id.task_row_container0, R.id.task_row_container1, R.id.task_row_container2,
        R.id.task_row_container3, R.id.task_row_container4,
    )
    private val rowIds = intArrayOf(
        R.id.task_row0, R.id.task_row1, R.id.task_row2, R.id.task_row3, R.id.task_row4,
    )
    private val checkIds = intArrayOf(
        R.id.task_check0, R.id.task_check1, R.id.task_check2, R.id.task_check3, R.id.task_check4,
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
                val taskId = task.optInt("id", -1)
                // Course label, truncated so titles keep room ("心理学A" fits),
                // then wrapped in brackets: "[prg]", "[情報工学…]".
                var course = task.optString("c", "")
                if (course.length > 7) course = course.take(6) + "…"
                if (course.isNotEmpty()) course = "[$course]"
                var dueLabel = ""
                var overdue = false
                val dueRaw = task.optString("d", "")
                if (dueRaw.isNotEmpty()) {
                    try {
                        val due = LocalDateTime.parse(dueRaw.substringBefore("+").substringBefore("Z"))
                        dueLabel = due.format(dueFormat)
                        overdue = due.isBefore(now)
                    } catch (_: Exception) {
                    }
                }
                // Format: 締切 → [コース] → 課題名 (e.g. "7/12 14:50 [prg] 第11回課題A問題")
                val text = listOf(dueLabel, course, title)
                    .filter { it.isNotEmpty() }
                    .joinToString(" ")
                val containerId = containerIds[row]
                val textId = rowIds[row]
                val checkId = checkIds[row]
                views.setTextViewText(textId, text)
                views.setTextColor(textId, if (overdue) overdueColor else normal)
                views.setViewVisibility(containerId, View.VISIBLE)
                views.setViewVisibility(checkId, View.VISIBLE)
                if (taskId >= 0) {
                    views.setOnClickPendingIntent(
                        checkId,
                        HomeWidgetBackgroundIntent.getBroadcast(
                            context, Uri.parse("klmsapp://complete-task/$taskId?homeWidget")))
                }
                row++
            }
            for (i in row until containerIds.size) {
                views.setViewVisibility(containerIds[i], View.GONE)
            }
            if (row == 0) {
                views.setTextViewText(rowIds[0], context.getString(R.string.widget_no_tasks))
                views.setTextColor(rowIds[0], sub)
                views.setViewVisibility(containerIds[0], View.VISIBLE)
                views.setViewVisibility(checkIds[0], View.GONE)
            }
            // Tapping anywhere else (including the row text) opens the tasks
            // tab; the check icon above overrides this within its own bounds.
            views.setOnClickPendingIntent(
                R.id.widget_root, Timetable.launchIntent(context, "tasks"))
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
