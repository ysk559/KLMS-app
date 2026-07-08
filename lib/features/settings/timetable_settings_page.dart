import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/settings/app_settings.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';

/// Configures the timetable frame: day range, number of periods, and the
/// start/end time of each period.
class TimetableSettingsPage extends ConsumerWidget {
  const TimetableSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final locale = Localizations.localeOf(context).toString();

    String dayName(int weekday) =>
        DateFormat.E(locale).format(DateTime(2024, 1, weekday));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.timetableSettings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.timetableDays),
            subtitle: Text(l10n.timetableDaysValue(
                dayName(settings.timetableFirstDay),
                dayName(settings.timetableLastDay))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: settings.timetableFirstDay,
                  items: [
                    for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                      DropdownMenuItem(value: d, child: Text(dayName(d))),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    notifier.update((s) => s.copyWith(
                          timetableFirstDay: v,
                          timetableLastDay:
                              v > s.timetableLastDay ? v : s.timetableLastDay,
                        ));
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('〜'),
                ),
                DropdownButton<int>(
                  value: settings.timetableLastDay,
                  items: [
                    for (var d = settings.timetableFirstDay;
                        d <= DateTime.sunday;
                        d++)
                      DropdownMenuItem(value: d, child: Text(dayName(d))),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    notifier.update((s) => s.copyWith(timetableLastDay: v));
                  },
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.periodsPerDay),
            trailing: DropdownButton<int>(
              value: settings.periodsPerDay,
              items: [
                for (var n = 1; n <= 10; n++)
                  DropdownMenuItem(value: n, child: Text('$n')),
              ],
              onChanged: (v) {
                if (v == null) return;
                notifier.update((s) {
                  final times = [...s.periodTimes];
                  // Extend the list if the user adds more periods.
                  while (times.length < v) {
                    final last = times.isNotEmpty
                        ? times.last
                        : kDefaultPeriodTimes.first;
                    times.add(PeriodTime(
                      startMinutes: last.endMinutes + 10,
                      endMinutes: last.endMinutes + 100,
                    ));
                  }
                  return s.copyWith(periodsPerDay: v, periodTimes: times);
                });
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.periodTimes,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          for (var p = 1;
              p <= settings.periodsPerDay && p <= settings.periodTimes.length;
              p++)
            _PeriodTimeTile(period: p, time: settings.periodTimes[p - 1]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PeriodTimeTile extends ConsumerWidget {
  const _PeriodTimeTile({required this.period, required this.time});

  final int period;
  final PeriodTime time;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> pick(bool isStart) async {
      final initial = isStart ? time.start : time.end;
      final result =
          await showTimePicker(context: context, initialTime: initial);
      if (result == null) return;
      final minutes = result.hour * 60 + result.minute;
      ref.read(settingsProvider.notifier).update((s) {
        final times = [...s.periodTimes];
        final current = times[period - 1];
        times[period - 1] = PeriodTime(
          startMinutes: isStart ? minutes : current.startMinutes,
          endMinutes: isStart ? current.endMinutes : minutes,
        );
        return s.copyWith(periodTimes: times);
      });
    }

    return ListTile(
      dense: true,
      leading: CircleAvatar(radius: 14, child: Text('$period')),
      title: Row(
        children: [
          TextButton(
              onPressed: () => pick(true), child: Text(time.startLabel)),
          const Text('〜'),
          TextButton(onPressed: () => pick(false), child: Text(time.endLabel)),
        ],
      ),
    );
  }
}
