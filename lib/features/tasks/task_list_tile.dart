import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatting.dart';
import '../../data/models/course.dart';
import '../../data/models/task_item.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../pages/lms_webview_page.dart';

class TaskListTile extends ConsumerStatefulWidget {
  const TaskListTile(
      {super.key, required this.task, this.course, this.dense = false});

  final TaskItem task;
  final Course? course;
  final bool dense;

  @override
  ConsumerState<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends ConsumerState<TaskListTile> {
  // Delay before the fade starts, and the fade duration itself. The task is
  // only persisted as completed once the fade has finished, so the list
  // refresh (which removes it) lands right as it becomes invisible.
  static const _fadeDelay = Duration(milliseconds: 250);
  static const _fadeDuration = Duration(milliseconds: 400);

  /// True once the user has checked a not-yet-completed task: shown as
  /// completed immediately, ahead of the actual persisted state.
  bool _completingLocally = false;
  bool _fadedOut = false;
  bool _busy = false;

  Future<void> _onChanged(bool? value) async {
    if (_busy) return;
    final checked = value ?? false;
    if (!checked) {
      // Unchecking is immediate: no fade, no local pre-state.
      await setTaskCompleted(ref, widget.task.id, false);
      return;
    }
    if (widget.task.isCompleted) return;

    _busy = true;
    setState(() => _completingLocally = true);

    await Future.delayed(_fadeDelay);
    if (!mounted) return;
    setState(() => _fadedOut = true);

    await Future.delayed(_fadeDuration);
    if (!mounted) return;

    await setTaskCompleted(ref, widget.task.id, true);
    // In tabs that keep showing completed tasks (すべて/完了/非表示) this same
    // element stays in the list, so reset the local animation state — the
    // tile fades back in as a checked row instead of staying invisible.
    if (mounted) {
      setState(() {
        _completingLocally = false;
        _fadedOut = false;
        _busy = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant TaskListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // List elements get reused for different tasks after a refresh.
    if (oldWidget.task.id != widget.task.id) {
      _completingLocally = false;
      _fadedOut = false;
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final task = widget.task;
    final due = task.dueAt?.toLocal();
    final displayCompleted = _completingLocally || task.isCompleted;
    final overdue =
        due != null && !displayCompleted && due.isBefore(DateTime.now());

    return AnimatedOpacity(
      opacity: _fadedOut ? 0 : 1,
      duration: _fadeDuration,
      curve: Curves.easeOut,
      child: ListTile(
        dense: widget.dense,
        leading: Checkbox(
          value: displayCompleted,
          // A submission that exists on the LMS cannot be "un-done" locally.
          onChanged: task.lmsCompleted ? null : _onChanged,
        ),
        title: Text(
          decorateTaskTitle(task.title, widget.course),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: displayCompleted
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
      ),
    );
  }
}
