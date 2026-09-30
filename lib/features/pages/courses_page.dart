import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/glass.dart';
import '../../data/models/course.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'course_detail_page.dart';

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final courses = ref.watch(coursesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.courses)),
      body: courses.when(
        data: (items) {
          final visible = items.where((c) => !c.hidden).toList();
          if (visible.isEmpty) {
            return Center(
              child: Text(l10n.noTasks,
                  style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.55))),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(syncControllerProvider.notifier).syncNow(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < visible.length; i++) ...[
                        if (i > 0) const Divider(indent: 68),
                        _CourseRow(course: visible[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.syncFailed)),
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course});

  final Course course;

  /// A stable per-course hue, so the list stays scannable by colour without
  /// asking the user to configure anything.
  static const _palette = [
    Color(0xFF3A6BD6),
    Color(0xFF2F9E7E),
    Color(0xFFB4632E),
    Color(0xFF7A57C7),
    Color(0xFF2E7FA6),
    Color(0xFFB33F6B),
  ];

  @override
  Widget build(BuildContext context) {
    final parsed = course.parsed;
    final color = _palette[course.id.abs() % _palette.length];
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      if (course.nickname != null && course.nickname!.isNotEmpty)
        '[${course.nickname}]',
      if (parsed.teacher != null) parsed.teacher!,
      if (parsed.room != null) parsed.room!,
    ].join(' · ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          course.shortLabel.characters.first,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      title: Text(parsed.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.chevron_right,
          color: scheme.onSurface.withValues(alpha: 0.3)),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CourseDetailPage(course: course))),
    );
  }
}
