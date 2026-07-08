package jp.keio.klms.klms_app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetProvider
import jp.keio.klms.klms_app.R
import java.util.Calendar

/** Medium widget listing today's classes, highlighting the current period. */
class TodayTimetableWidgetProvider : HomeWidgetProvider() {

    private val rowIds = intArrayOf(
        R.id.tt_row0, R.id.tt_row1, R.id.tt_row2, R.id.tt_row3,
        R.id.tt_row4, R.id.tt_row5, R.id.tt_row6, R.id.tt_row7,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val timetable = Timetable(widgetData.getString("widget_timetable", null))
        val now = Calendar.getInstance()
        val today = Timetable.isoWeekday(now)
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

        val accent = ContextCompat.getColor(context, R.color.widgetAccent)
        val normal = ContextCompat.getColor(context, R.color.widgetText)
        val sub = ContextCompat.getColor(context, R.color.widgetSubText)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_today_timetable)
            views.setTextViewText(
                R.id.tt_title,
                context.getString(R.string.widget_today_title, Timetable.dayLabel(today))
            )

            var row = 0
            var hasAny = false
            for (p in 1..timetable.periods) {
                if (row >= rowIds.size) break
                val entries = timetable.entriesFor(today, p)
                if (entries.isEmpty()) continue
                hasAny = true
                val time = timetable.timeFor(p)
                val ongoing =
                    time != null && nowMinutes >= time.startMinutes && nowMinutes <= time.endMinutes
                val names = entries.joinToString(" / ") { e ->
                    e.name + (e.room?.let { "［$it］" } ?: "")
                }
                val text = buildString {
                    append(p)
                    append(context.getString(R.string.widget_period_suffix))
                    if (time != null) append(" ").append(time.startLabel)
                    append("  ").append(names)
                }
                val id = rowIds[row]
                views.setTextViewText(id, text)
                views.setTextColor(id, if (ongoing) accent else normal)
                views.setViewVisibility(id, View.VISIBLE)
                row++
            }
            for (i in row until rowIds.size) {
                views.setViewVisibility(rowIds[i], View.GONE)
            }
            if (!hasAny) {
                views.setTextViewText(rowIds[0], context.getString(R.string.widget_no_class_today))
                views.setTextColor(rowIds[0], sub)
                views.setViewVisibility(rowIds[0], View.VISIBLE)
            }
            views.setOnClickPendingIntent(
                R.id.widget_root, Timetable.launchIntent(context, "timetable"))
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
