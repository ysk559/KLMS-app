package jp.keio.klms.klms_app.widgets

import android.app.PendingIntent
import android.content.Context
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import jp.keio.klms.klms_app.MainActivity
import org.json.JSONObject
import java.util.Calendar

data class TimetableEntry(
    val day: Int,
    val period: Int,
    val name: String,
    val room: String?,
    val courseId: Int,
)

data class PeriodTime(val startMinutes: Int, val endMinutes: Int) {
    fun label(m: Int): String = "%d:%02d".format(m / 60, m % 60)
    val startLabel get() = label(startMinutes)
    val endLabel get() = label(endMinutes)
}

/** Result of the next-class search. */
data class NextClass(
    val entry: TimetableEntry,
    val dayOffset: Int,
    val period: Int,
    val time: PeriodTime?,
    val ongoing: Boolean,
)

/** Parses the timetable JSON written by the Flutter side (WidgetBridge). */
class Timetable(json: String?) {
    var firstDay = Calendar.MONDAY // ISO: 1=Mon ... 7=Sun
    var lastDay = 5
    var periods = 6
    val times = mutableListOf<PeriodTime>()
    val entries = mutableListOf<TimetableEntry>()

    init {
        if (json != null) {
            try {
                val root = JSONObject(json)
                firstDay = root.optInt("firstDay", 1)
                lastDay = root.optInt("lastDay", 5)
                periods = root.optInt("periods", 6)
                val timesArr = root.optJSONArray("times")
                if (timesArr != null) {
                    for (i in 0 until timesArr.length()) {
                        val t = timesArr.getJSONObject(i)
                        times.add(PeriodTime(t.optInt("s"), t.optInt("e")))
                    }
                }
                val entriesArr = root.optJSONArray("entries")
                if (entriesArr != null) {
                    for (i in 0 until entriesArr.length()) {
                        val e = entriesArr.getJSONObject(i)
                        entries.add(
                            TimetableEntry(
                                day = e.optInt("d"),
                                period = e.optInt("p"),
                                name = e.optString("n"),
                                room = if (e.has("r")) e.optString("r") else null,
                                courseId = e.optInt("id"),
                            )
                        )
                    }
                }
            } catch (_: Exception) {
            }
        }
    }

    fun entriesFor(day: Int, period: Int): List<TimetableEntry> =
        entries.filter { it.day == day && it.period == period }

    fun timeFor(period: Int): PeriodTime? = times.getOrNull(period - 1)

    /** Next (or ongoing) class from now, searching up to a week ahead. */
    fun nextClass(now: Calendar): NextClass? {
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        for (offset in 0..6) {
            val day = ((isoWeekday(now) - 1 + offset) % 7) + 1
            for (p in 1..periods) {
                val t = timeFor(p) ?: continue
                if (offset == 0 && t.endMinutes <= nowMinutes) continue
                val list = entriesFor(day, p)
                if (list.isNotEmpty()) {
                    val ongoing = offset == 0 && nowMinutes >= t.startMinutes
                    return NextClass(list.first(), offset, p, t, ongoing)
                }
            }
        }
        return null
    }

    companion object {
        val DAY_LABELS = arrayOf("月", "火", "水", "木", "金", "土", "日")

        fun isoWeekday(cal: Calendar): Int {
            val d = cal.get(Calendar.DAY_OF_WEEK)
            return if (d == Calendar.SUNDAY) 7 else d - 1
        }

        fun dayLabel(isoDay: Int): String = DAY_LABELS.getOrElse(isoDay - 1) { "?" }

        /**
         * PendingIntent that opens the app on a specific destination.
         * The `homeWidget` query parameter is required by the home_widget
         * plugin so the Flutter side receives the URI.
         */
        fun launchIntent(context: Context, destination: String): PendingIntent {
            return HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("klmsapp://$destination?homeWidget"),
            )
        }
    }
}
