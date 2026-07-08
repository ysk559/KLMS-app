import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatting.dart';
import '../../data/models/course.dart';
import '../../data/models/task_item.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../pages/lms_webview_page.dart';

class TaskListTile extends ConsumerWidget {
  const TaskListTile(
      {super.key, required this.task, this.course, this.dense = false});

  final TaskItem task;
  final Course? course;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueAt?.toLocal();
    final overdue =
        due != null && !task.isCompleted && due.isBefore(DateTime.now());

    return ListTile(
      dense: dense,
      leading: Checkbox(
        value: task.isCompleted,
        // A submission that exists on the LMS cannot be "un-done" locally.
        onChanged: task.lmsCompleted
            ? null
            : (v) => setTaskCompleted(ref, task.id, v ?? false),
      ),
      title: Text(
        decorateTaskTitle(task.title, course),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: task.isCompleted
            ? TextStyle(
                decoration: TextDecoration.lineThrough, color: scheme.outline)
            : null,
      ),
      subtitle: Row(
        children: [
          if (task.hasConflict) ...[
            Tooltip(
              message: l10n.conflictWarning,
              child: Icon(Icons.warning_amber_rounded,
                  size: 16, color: scheme.error),
            ),
            const SizedBox(width: 4),
          ],
          if (task.lmsCompleted) ...[
            Icon(Icons.cloud_done_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              due != null ? l10n.dueAt(formatDateTimeShort(due)) : l10n.noDueDate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: overdue ? scheme.error : null),
            ),
          ),
        ],
      ),
      onTap: task.htmlUrl != null
          ? () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  LmsWebViewPage(url: task.htmlUrl!, title: task.title)))
          : null,
    );
  }
}
