import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';

/// Selects courses whose assignments never trigger deadline reminders.
class ExcludeCoursesPage extends ConsumerWidget {
  const ExcludeCoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final courses = ref.watch(coursesProvider);
    final excluded = ref.watch(settingsProvider).excludedCourseIds;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.excludeCourses)),
      body: courses.when(
        data: (items) => ListView(
          children: [
            for (final course in items)
              CheckboxListTile(
                title: Text(course.parsed.displayName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: course.nickname != null
                    ? Text('[${course.nickname}]')
                    : null,
                value: excluded.contains(course.id),
                onChanged: (v) {
                  final updated = {...excluded};
                  if (v == true) {
                    updated.add(course.id);
                  } else {
                    updated.remove(course.id);
                  }
                  ref
                      .read(settingsProvider.notifier)
                      .update((s) => s.copyWith(excludedCourseIds: updated));
                },
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.syncFailed)),
      ),
    );
  }
}
