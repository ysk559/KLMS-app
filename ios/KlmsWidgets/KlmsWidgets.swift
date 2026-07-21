import SwiftUI
import UIKit
import WidgetKit

// Data is written by the Flutter side (lib/data/widgets/widget_bridge.dart)
// through the shared App Group container.
private let appGroupId = "group.jp.keio.klms.klmsApp"
private let accentLight = Color(red: 0x02 / 255, green: 0x19 / 255, blue: 0x51 / 255)
private let accentDark = Color(red: 0xAE / 255, green: 0xC6 / 255, blue: 0xFF / 255)

// MARK: - Shared models (mirror of the JSON produced by WidgetBridge)

struct TaskData: Decodable {
  let id: Int?
  let t: String
  let c: String?
  let d: String?

  var due: Date? {
    guard let d = d else { return nil }
    return parseLocalIso(d)
  }

  /// Course label truncated so the task title keeps room, wrapped in
  /// brackets: "[prg]", "[情報工学…]". iOS doesn't implement tap-to-complete
  /// (see docs/ROADMAP.md — needs iOS 17 AppIntents + an active App Group),
  /// so `id` is currently unused here beyond tolerant decoding.
  var courseLabel: String {
    guard let c = c, !c.isEmpty else { return "" }
    let truncated = c.count > 7 ? String(c.prefix(6)) + "…" : c
    return "[\(truncated)]"
  }
}

struct PeriodTimeData: Decodable {
  let s: Int
  let e: Int

  func label(_ minutes: Int) -> String {
    String(format: "%d:%02d", minutes / 60, minutes % 60)
  }

  var startLabel: String { label(s) }
  var endLabel: String { label(e) }
}

struct TimetableEntryData: Decodable {
  let d: Int
  let p: Int
  let n: String
  let r: String?
  let id: Int?
}

struct TimetableData: Decodable {
  let firstDay: Int
  let lastDay: Int
  let periods: Int
  let times: [PeriodTimeData]
  let entries: [TimetableEntryData]

  func entriesFor(day: Int, period: Int) -> [TimetableEntryData] {
    entries.filter { $0.d == day && $0.p == period }
  }

  func time(of period: Int) -> PeriodTimeData? {
    period >= 1 && period <= times.count ? times[period - 1] : nil
  }

  struct NextClass {
    let entry: TimetableEntryData
    let dayOffset: Int
    let period: Int
    let time: PeriodTimeData?
    let ongoing: Bool
  }

  func nextClass(from now: Date) -> NextClass? {
    let cal = Calendar.current
    let nowMinutes = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
    let todayIso = isoWeekday(now)
    for offset in 0...6 {
      let day = ((todayIso - 1 + offset) % 7) + 1
      for p in 1...max(periods, 1) {
        guard let t = time(of: p) else { continue }
        if offset == 0 && t.e <= nowMinutes { continue }
        if let entry = entriesFor(day: day, period: p).first {
          let ongoing = offset == 0 && nowMinutes >= t.s
          return NextClass(entry: entry, dayOffset: offset, period: p, time: t, ongoing: ongoing)
        }
      }
    }
    return nil
  }
}

private func isoWeekday(_ date: Date) -> Int {
  // Calendar: 1=Sun ... 7=Sat → ISO: 1=Mon ... 7=Sun
  let d = Calendar.current.component(.weekday, from: date)
  return d == 1 ? 7 : d - 1
}

private let dayLabels = ["月", "火", "水", "木", "金", "土", "日"]

private func dayLabel(_ isoDay: Int) -> String {
  (1...7).contains(isoDay) ? dayLabels[isoDay - 1] : "?"
}

private func parseLocalIso(_ s: String) -> Date? {
  let trimmed = s.split(separator: "+").first.map(String.init) ?? s
  let formats = [
    "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
    "yyyy-MM-dd'T'HH:mm:ss.SSS",
    "yyyy-MM-dd'T'HH:mm:ss",
  ]
  for f in formats {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = f
    if let date = df.date(from: trimmed) { return date }
  }
  return nil
}

// MARK: - Styling helpers

private struct HighlightColor: ViewModifier {
  @Environment(\.colorScheme) var scheme
  let active: Bool
  let inactive: Color?

  @ViewBuilder
  func body(content: Content) -> some View {
    if active {
      content.foregroundColor(scheme == .dark ? accentDark : accentLight)
    } else if let color = inactive {
      content.foregroundColor(color)
    } else {
      content
    }
  }
}

extension View {
  /// Accent color when [active], otherwise the optional fallback color.
  fileprivate func highlight(_ active: Bool, inactive: Color? = nil) -> some View {
    modifier(HighlightColor(active: active, inactive: inactive))
  }

  @ViewBuilder
  fileprivate func widgetContainer() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    } else {
      padding(4)
    }
  }
}

// MARK: - Timeline

struct KlmsEntry: TimelineEntry {
  let date: Date
  let tasks: [TaskData]
  let timetable: TimetableData?
}

struct KlmsProvider: TimelineProvider {
  private func load(at date: Date) -> KlmsEntry {
    let defaults = UserDefaults(suiteName: appGroupId)
    var tasks: [TaskData] = []
    var timetable: TimetableData? = nil
    if let raw = defaults?.string(forKey: "widget_tasks")?.data(using: .utf8) {
      tasks = (try? JSONDecoder().decode([TaskData].self, from: raw)) ?? []
    }
    if let raw = defaults?.string(forKey: "widget_timetable")?.data(using: .utf8) {
      timetable = try? JSONDecoder().decode(TimetableData.self, from: raw)
    }
    return KlmsEntry(date: date, tasks: tasks, timetable: timetable)
  }

  func placeholder(in context: Context) -> KlmsEntry {
    KlmsEntry(date: Date(), tasks: [], timetable: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (KlmsEntry) -> Void) {
    completion(load(at: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<KlmsEntry>) -> Void) {
    // Re-render every 15 minutes so "next class" and the current-period
    // highlight stay fresh even without a data push from the app.
    var entries: [KlmsEntry] = []
    let now = Date()
    for i in 0..<8 {
      entries.append(load(at: now.addingTimeInterval(Double(i) * 15 * 60)))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

// MARK: - Views

struct NextClassView: View {
  let entry: KlmsEntry

  private var destination: URL {
    if let id = entry.timetable?.nextClass(from: entry.date)?.entry.id {
      return URL(string: "klmsapp://course/\(id)?homeWidget")!
    }
    return URL(string: "klmsapp://timetable?homeWidget")!
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      if let next = entry.timetable?.nextClass(from: entry.date) {
        Text(next.ongoing ? "今の授業" : "次の授業")
          .font(.caption2.bold()).highlight(true)
        Text(next.entry.n)
          .font(.headline.bold())
          .lineLimit(2)
          .minimumScaleFactor(0.8)
        let prefix = next.dayOffset == 0
          ? "" : (next.dayOffset == 1 ? "明日 " : dayLabel(next.entry.d) + " ")
        if let t = next.time {
          Text("\(prefix)\(next.period)限 \(t.startLabel)–\(t.endLabel)")
            .font(.caption2).foregroundColor(.secondary)
        }
        if let room = next.entry.r {
          Text(room).font(.caption2).foregroundColor(.secondary).lineLimit(1)
        }
      } else {
        Text("次の授業").font(.caption2.bold()).highlight(true)
        Text("予定なし").font(.subheadline).foregroundColor(.secondary)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(destination)
    .widgetContainer()
  }
}

struct TodayView: View {
  let entry: KlmsEntry

  var body: some View {
    let today = isoWeekday(entry.date)
    let cal = Calendar.current
    let nowMinutes =
      cal.component(.hour, from: entry.date) * 60 + cal.component(.minute, from: entry.date)

    VStack(alignment: .leading, spacing: 3) {
      Text("今日の時間割(\(dayLabel(today)))")
        .font(.caption2.bold()).highlight(true)
      if let tt = entry.timetable {
        let rows: [(Int, PeriodTimeData?, [TimetableEntryData])] =
          (1...max(tt.periods, 1)).compactMap { p in
            let list = tt.entriesFor(day: today, period: p)
            return list.isEmpty ? nil : (p, tt.time(of: p), list)
          }
        if rows.isEmpty {
          Text("今日の授業はありません").font(.caption).foregroundColor(.secondary)
        } else {
          ForEach(rows.prefix(6), id: \.0) { row in
            let (p, time, list) = row
            let ongoing = time.map { nowMinutes >= $0.s && nowMinutes <= $0.e } ?? false
            HStack(spacing: 4) {
              Text("\(p)限 \(time?.startLabel ?? "")")
                .font(.caption2.monospacedDigit())
                .highlight(ongoing, inactive: .secondary)
              Text(list.map { $0.n + ($0.r.map { "［\($0)］" } ?? "") }.joined(separator: " / "))
                .font(.caption2)
                .lineLimit(1)
            }
          }
        }
      } else {
        Text("アプリで同期してください").font(.caption).foregroundColor(.secondary)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(URL(string: "klmsapp://timetable?homeWidget"))
    .widgetContainer()
  }
}

struct WeekGridView: View {
  let entry: KlmsEntry

  private let timeColumnWidth: CGFloat = 24

  var body: some View {
    if let tt = entry.timetable {
      let days = Array(tt.firstDay...max(tt.lastDay, tt.firstDay))
      let today = isoWeekday(entry.date)
      let cal = Calendar.current
      let nowMinutes =
        cal.component(.hour, from: entry.date) * 60 + cal.component(.minute, from: entry.date)

      grid(tt: tt, days: days, today: today, nowMinutes: nowMinutes)
        .widgetURL(URL(string: "klmsapp://timetable?homeWidget"))
        .widgetContainer()
    } else {
      Text("アプリで同期してください")
        .font(.caption).foregroundColor(.secondary)
        .widgetContainer()
    }
  }

  private func courseText(_ s: String, lines: Int = 2) -> some View {
    Text(s)
      .font(.system(size: 8, weight: .semibold))
      .lineLimit(lines)
      .multilineTextAlignment(.center)
      .minimumScaleFactor(0.6)
      .truncationMode(.tail)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  /// One timetable cell. Empty → a faint box so the grid still reads as a
  /// table. One class → name (+ room). Two classes → the cell is split into
  /// top/bottom halves, one class each. Three or more → the second half shows
  /// "…". Long names are truncated with an ellipsis.
  @ViewBuilder
  private func cell(_ list: [TimetableEntryData]) -> some View {
    Group {
      if list.isEmpty {
        Color.clear
      } else if list.count == 1 {
        VStack(spacing: 1) {
          courseText(list[0].n)
          if let room = list[0].r {
            Text(room)
              .font(.system(size: 7)).foregroundColor(.secondary)
              .lineLimit(1).minimumScaleFactor(0.6)
          }
        }
      } else {
        VStack(spacing: 0) {
          courseText(list[0].n, lines: 1)
          Divider().opacity(0.4)
          courseText(list.count == 2 ? list[1].n : "…", lines: 1)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(1)
    .background(
      RoundedRectangle(cornerRadius: 3)
        .fill(Color.primary.opacity(list.isEmpty ? 0.03 : 0.08))
    )
  }

  @ViewBuilder
  private func timeCell(_ tt: TimetableData, _ p: Int, ongoing: Bool) -> some View {
    VStack(spacing: 0) {
      Text("\(p)").font(.caption2.bold())
      if let t = tt.time(of: p) {
        Text(t.startLabel).font(.system(size: 7)).foregroundColor(.secondary)
      }
    }
    .frame(width: timeColumnWidth)
    .highlight(ongoing)
  }

  /// Uses SwiftUI `Grid` (iOS 16+) so every column is the same width across
  /// all rows regardless of course-name length; falls back to stacked HStacks
  /// on iOS 14/15.
  @ViewBuilder
  private func grid(tt: TimetableData, days: [Int], today: Int, nowMinutes: Int)
    -> some View
  {
    if #available(iOS 16.0, *) {
      Grid(horizontalSpacing: 2, verticalSpacing: 2) {
        GridRow {
          Text("").frame(width: timeColumnWidth)
          ForEach(days, id: \.self) { d in
            Text(dayLabel(d)).font(.caption2.bold()).highlight(d == today)
              .frame(maxWidth: .infinity)
          }
        }
        ForEach(1...max(tt.periods, 1), id: \.self) { p in
          let ongoing =
            tt.time(of: p).map { nowMinutes >= $0.s && nowMinutes <= $0.e } ?? false
          GridRow {
            timeCell(tt, p, ongoing: ongoing)
            ForEach(days, id: \.self) { d in
              cell(tt.entriesFor(day: d, period: p))
            }
          }
        }
      }
    } else {
      VStack(spacing: 2) {
        HStack(spacing: 2) {
          Text("").frame(width: timeColumnWidth)
          ForEach(days, id: \.self) { d in
            Text(dayLabel(d)).font(.caption2.bold())
              .frame(maxWidth: .infinity).highlight(d == today)
          }
        }
        ForEach(1...max(tt.periods, 1), id: \.self) { p in
          let ongoing =
            tt.time(of: p).map { nowMinutes >= $0.s && nowMinutes <= $0.e } ?? false
          HStack(alignment: .top, spacing: 2) {
            timeCell(tt, p, ongoing: ongoing)
            ForEach(days, id: \.self) { d in
              cell(tt.entriesFor(day: d, period: p))
            }
          }
          .frame(maxHeight: .infinity)
        }
      }
    }
  }
}

struct TasksView: View {
  @Environment(\.widgetFamily) var family
  let entry: KlmsEntry

  private static let dueFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "M/d HH:mm"
    return df
  }()

  // Fill the widget: the large family shows many rows, the medium a few.
  private var maxRows: Int { family == .systemLarge ? 14 : 5 }

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("課題").font(.caption2.bold()).highlight(true)
      if entry.tasks.isEmpty {
        Text("課題はありません").font(.caption).foregroundColor(.secondary)
      } else {
        // Format: 締切 → コース → 課題名 (e.g. "7/12 14:50 prg 第11回課題A問題")
        ForEach(Array(entry.tasks.prefix(maxRows).enumerated()), id: \.offset) { item in
          let task = item.element
          HStack(spacing: 4) {
            if let due = task.due {
              Text(Self.dueFormatter.string(from: due))
                .font(.caption2.monospacedDigit())
                .foregroundColor(due < entry.date ? .red : .secondary)
            }
            if !task.courseLabel.isEmpty {
              Text(task.courseLabel)
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .lineLimit(1)
                .layoutPriority(1)
            }
            Text(task.t).font(.caption2).lineLimit(1)
            Spacer(minLength: 0)
          }
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(URL(string: "klmsapp://tasks?homeWidget"))
    .widgetContainer()
  }
}

// MARK: - Widgets

struct TimetableWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: KlmsEntry

  var body: some View {
    switch family {
    case .systemSmall: NextClassView(entry: entry)
    case .systemMedium: TodayView(entry: entry)
    default: WeekGridView(entry: entry)
    }
  }
}

struct KlmsTimetableWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "KlmsWidgets", provider: KlmsProvider()) { entry in
      TimetableWidgetView(entry: entry)
    }
    .configurationDisplayName("時間割")
    .description("次の授業(小)/今日の時間割(中)/週の時間割(大)を表示します")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct KlmsTasksWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "KlmsTasksWidget", provider: KlmsProvider()) { entry in
      TasksView(entry: entry)
    }
    .configurationDisplayName("課題一覧")
    .description("未完了の課題と締切を表示します")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

@main
struct KlmsWidgetBundle: WidgetBundle {
  var body: some Widget {
    KlmsTimetableWidget()
    KlmsTasksWidget()
  }
}
