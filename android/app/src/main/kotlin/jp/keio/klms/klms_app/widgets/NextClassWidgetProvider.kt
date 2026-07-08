package jp.keio.klms.klms_app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import jp.keio.klms.klms_app.R
import java.util.Calendar

/** Small widget showing the next (or ongoing) class. */
class NextClassWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val timetable = Timetable(widgetData.getString("widget_timetable", null))
        val next = timetable.nextClass(Calendar.getInstance())

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_next_class)
            if (next == null) {
                views.setTextViewText(R.id.next_label, context.getString(R.string.widget_next_class))
                views.setTextViewText(R.id.next_name, context.getString(R.string.widget_no_class))
                views.setTextViewText(R.id.next_sub, "")
            } else {
                val label = if (next.ongoing) context.getString(R.string.widget_now_class)
                else context.getString(R.string.widget_next_class)
                views.setTextViewText(R.id.next_label, label)
                views.setTextViewText(R.id.next_name, next.entry.name)
                val dayPrefix = when (next.dayOffset) {
                    0 -> ""
                    1 -> context.getString(R.string.widget_tomorrow) + " "
                    else -> Timetable.dayLabel(next.entry.day) + " "
                }
                val time = next.time
                val sub = buildString {
                    append(dayPrefix)
                    append(next.period).append(context.getString(R.string.widget_period_suffix))
                    if (time != null) append(" ").append(time.startLabel).append("–").append(time.endLabel)
                    next.entry.room?.let { append("\n").append(it) }
                }
                views.setTextViewText(R.id.next_sub, sub)
            }
            Timetable.launchIntent(context)?.let {
                views.setOnClickPendingIntent(R.id.widget_root, it)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
