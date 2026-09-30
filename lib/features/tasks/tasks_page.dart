import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/glass.dart';
import '../../data/models/task_item.dart';
import '../../data/providers.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import 'task_list_tile.dart';

enum _TaskFilter { all, incomplete, completed, hidden }

final _filterProvider = StateProvider<_TaskFilter>((_) => _TaskFilter.incomplete);

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(_filterProvider);
    final settings = ref.watch(settingsProvider);
    // The "hidden" segment intentionally reads from the full unfiltered list
    // (tasksProvider) since visibleTasksProvider already strips those tasks.
    final tasks = filter == _TaskFilter.hidden
        ? ref.watch(tasksProvider)
        : ref.watch(visibleTasksProvider);
    final courseMap = ref.watch(courseMapProvider);

    Future<void> refresh() =>
        ref.read(syncControllerProvider.notifier).syncNow();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabTasks)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<_TaskFilter>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 6)),
              ),
              segments: [
                ButtonSegment(
                    value: _TaskFilter.incomplete,
                    label: Text(l10n.filterIncomplete)),
                ButtonSegment(
                    value: _TaskFilter.completed,
                    label: Text(l10n.filterCompleted)),
                ButtonSegment(
                    value: _TaskFilter.all, label: Text(l10n.filterAll)),
                ButtonSegment(
                    value: _TaskFilter.hidden, label: Text(l10n.filterHidden)),
              ],
              selected: {filter},
              onSelectionChanged: (s) =>
                  ref.read(_filterProvider.notifier).state = s.first,
            ),
          ),
          Expanded(
            child: tasks.when(
              data: (items) {
                final filtered = switch (filter) {
                  _TaskFilter.all => items,
                  _TaskFilter.incomplete =>
                    items.where((t) => !t.isCompleted).toList(),
                  _TaskFilter.completed =>
                    items.where((t) => t.isCompleted).toList(),
                  _TaskFilter.hidden => items
                      .where((t) => settings.excludesTask(t.title, t.courseId))
                      .toList(),
                };
                if (filtered.isEmpty) {
                  return _EmptyState(text: l10n.noTasks, onRefresh: refresh);
                }
                final groups = _groupByDeadline(filtered, l10n);
                return RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      for (final g in groups) ...[
                        SectionLabel(g.label),
                        AppCard(
                          child: Column(
                            children: [
                              for (var i = 0; i < g.tasks.length; i++) ...[
                                if (i > 0) const Divider(indent: 56),
                                TaskListTile(
                                  task: g.tasks[i],
                                  course: courseMap[g.tasks[i].courseId],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.syncFailed)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group {
  const _Group(this.label, this.tasks);
  final String label;
  final List<TaskItem> tasks;
}

/// Buckets tasks by deadline urgency so the list answers "what do I have to do
/// now" before "what exists".
List<_Group> _groupByDeadline(List<TaskItem> tasks, AppLocalizations l10n) {
  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final endOfWeek = endOfToday.add(const Duration(days: 7));

  final overdue = <TaskItem>[];
  final today = <TaskItem>[];
  final week = <TaskItem>[];
  final later = <TaskItem>[];
  final undated = <TaskItem>[];

  for (final t in tasks) {
    final due = t.dueAt?.toLocal();
    if (due == null) {
      undated.add(t);
    } else if (due.isBefore(now)) {
      overdue.add(t);
    } else if (!due.isAfter(endOfToday)) {
      today.add(t);
    } else if (!due.isAfter(endOfWeek)) {
      week.add(t);
    } else {
      later.add(t);
    }
  }

  int byDue(TaskItem a, TaskItem b) {
    final x = a.dueAt, y = b.dueAt;
    if (x == null || y == null) return 0;
    return x.compareTo(y);
  }

  for (final list in [overdue, today, week, later]) {
    list.sort(byDue);
  }

  return [
    if (overdue.isNotEmpty) _Group(l10n.groupOverdue, overdue),
    if (today.isNotEmpty) _Group(l10n.groupToday, today),
    if (week.isNotEmpty) _Group(l10n.groupThisWeek, week),
    if (later.isNotEmpty) _Group(l10n.groupLater, later),
    if (undated.isNotEmpty) _Group(l10n.groupNoDue, undated),
  ];
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text, required this.onRefresh});

  final String text;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        children: [
          Icon(Icons.check_circle_outline,
              size: 44, color: scheme.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 15)),
        ],
      ),
    );
  }
}
