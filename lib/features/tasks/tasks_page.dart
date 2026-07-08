import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'task_list_tile.dart';

enum _TaskFilter { all, incomplete, completed }

final _filterProvider = StateProvider<_TaskFilter>((_) => _TaskFilter.incomplete);

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(_filterProvider);
    final tasks = ref.watch(tasksProvider);
    final courseMap = ref.watch(courseMapProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabTasks)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<_TaskFilter>(
              segments: [
                ButtonSegment(
                    value: _TaskFilter.incomplete,
                    label: Text(l10n.filterIncomplete)),
                ButtonSegment(
                    value: _TaskFilter.completed,
                    label: Text(l10n.filterCompleted)),
                ButtonSegment(
                    value: _TaskFilter.all, label: Text(l10n.filterAll)),
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
                };
                if (filtered.isEmpty) {
                  return Center(child: Text(l10n.noTasks));
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(syncControllerProvider.notifier).syncNow(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => TaskListTile(
                      task: filtered[i],
                      course: courseMap[filtered[i].courseId],
                    ),
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
