import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'course_detail_page.dart';

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final courses = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.courses)),
      body: courses.when(
        data: (items) {
          final visible = items.where((c) => !c.hidden).toList();
          if (visible.isEmpty) {
            return Center(child: Text(l10n.noTasks));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(syncControllerProvider.notifier).syncNow(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final course = visible[i];
                final parsed = course.parsed;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      course.shortLabel.characters.first,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                    ),
                  ),
                  title: Text(parsed.displayName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      if (course.nickname != null &&
                          course.nickname!.isNotEmpty)
                        '[${course.nickname}]',
                      if (parsed.teacher != null) parsed.teacher!,
                      if (parsed.room != null) parsed.room!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CourseDetailPage(course: course))),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.syncFailed)),
      ),
    );
  }
}
