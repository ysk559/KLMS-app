import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/glass.dart';
import '../../core/utils/formatting.dart';
import '../../data/models/course.dart';
import '../../data/settings/app_settings.dart';
import '../../data/providers.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/login_webview_page.dart';
import '../pages/course_detail_page.dart';
import '../pages/lms_webview_page.dart';
import '../tasks/task_list_tile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authStatusProvider);
    final sync = ref.watch(syncControllerProvider);
    final tasks = ref.watch(visibleTasksProvider);
    final announcements = ref.watch(announcementsProvider);
    final courseMap = ref.watch(courseMapProvider);
    final theme = Theme.of(context);

    final next = _findNextClass(courseMap.values, settings, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabHome),
        actions: [
          if (sync.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 18),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              tooltip: l10n.refreshNow,
              icon: const Icon(Icons.refresh, size: 22),
              onPressed: () =>
                  ref.read(syncControllerProvider.notifier).syncNow(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncControllerProvider.notifier).syncNow(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (auth.value == false) ...[
              _LoginCard(l10n: l10n),
              const SizedBox(height: 20),
            ],

            // Next / current class hero.
            _NextClassHero(next: next, l10n: l10n),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                sync.hasError
                    ? l10n.syncFailed
                    : l10n.lastUpdated(settings.lastSyncedAt != null
                        ? formatDateTimeShort(settings.lastSyncedAt!)
                        : l10n.neverUpdated),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 20),

            // Upcoming tasks.
            SectionLabel(l10n.upcomingTasks),
            tasks.when(
              data: (items) {
                final upcoming =
                    items.where((t) => !t.isCompleted).take(5).toList();
                if (upcoming.isEmpty) return _EmptyHint(text: l10n.noTasks);
                return AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < upcoming.length; i++) ...[
                        if (i > 0) const Divider(indent: 16),
                        TaskListTile(
                            task: upcoming[i],
                            course: courseMap[upcoming[i].courseId],
                            dense: true),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const _LoadingCard(),
              error: (e, _) => _EmptyHint(text: l10n.syncFailed),
            ),
            const SizedBox(height: 20),

            // Recent announcements.
            SectionLabel(l10n.recentAnnouncements),
            announcements.when(
              data: (items) {
                final recent = items.take(5).toList();
                if (recent.isEmpty) {
                  return _EmptyHint(text: l10n.noAnnouncements);
                }
                return AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < recent.length; i++) ...[
                        if (i > 0) const Divider(indent: 56),
                        _AnnouncementRow(
                            a: recent[i], courseMap: courseMap, l10n: l10n),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const _LoadingCard(),
              error: (e, _) => _EmptyHint(text: l10n.syncFailed),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted hero showing the current or next class.
class _NextClassHero extends StatelessWidget {
  const _NextClassHero({required this.next, required this.l10n});

  final _NextClass? next;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final ink2 = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    if (next == null) {
      return GlassCard(
        child: Row(
          children: [
            Icon(Icons.event_available_outlined, color: ink2, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(l10n.homeNoClass,
                    style: theme.textTheme.bodyLarge?.copyWith(color: ink2))),
          ],
        ),
      );
    }

    final n = next!;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(n.ongoing ? l10n.homeCurrentClass : l10n.homeNextClass,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: accent)),
            const Spacer(),
            if (n.ongoing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(999)),
                child: Text('NOW',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimary)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(n.course.parsed.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${l10n.period(n.period)}  ${_hm(n.startMin)}–${_hm(n.endMin)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: ink2),
            ),
            if (n.course.parsed.room != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(n.course.parsed.room!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: ink2)),
              ),
            ],
          ],
        ),
      ],
    );

    return GlassCard(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CourseDetailPage(course: n.course))),
      child: content,
    );
  }

  static String _hm(int minutes) =>
      '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';
}

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow(
      {required this.a, required this.courseMap, required this.l10n});

  final dynamic a;
  final Map<int, Course> courseMap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final course = a.courseId != null ? courseMap[a.courseId] : null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(Icons.campaign_outlined,
          color: Theme.of(context).colorScheme.primary),
      title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (course != null) course.shortLabel,
          if (a.postedAt != null) formatDateTimeShort(a.postedAt!),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (a.message != null && a.message!.isNotEmpty) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => HtmlContentPage(
                  title: course?.parsed.displayName ?? l10n.announcements,
                  heading: a.title,
                  html: a.message!)));
        } else if (a.url != null) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LmsWebViewPage(url: a.url!, title: a.title)));
        }
      },
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.notLoggedIn, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(l10n.loginPrompt,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginWebViewPage())),
            icon: const Icon(Icons.login, size: 18),
            label: Text(l10n.loginButton),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const AppCard(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Text(text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
    );
  }
}

// ---- Next-class computation ---------------------------------------------

class _NextClass {
  const _NextClass({
    required this.course,
    required this.period,
    required this.startMin,
    required this.endMin,
    required this.dayOffset,
    required this.ongoing,
  });

  final Course course;
  final int period;
  final int startMin;
  final int endMin;
  final int dayOffset;
  final bool ongoing;
}

_NextClass? _findNextClass(
    Iterable<Course> courses, AppSettings s, DateTime now) {
  final times = s.periodTimes;
  final nowMin = now.hour * 60 + now.minute;
  final todayIso = now.weekday; // 1 = Mon … 7 = Sun
  for (var offset = 0; offset <= 6; offset++) {
    final day = ((todayIso - 1 + offset) % 7) + 1;
    for (var p = 1; p <= s.periodsPerDay; p++) {
      if (p - 1 >= times.length) continue;
      final t = times[p - 1];
      if (offset == 0 && t.endMinutes <= nowMin) continue;
      for (final c in courses) {
        if (c.hidden) continue;
        if (c.parsed.slots
            .any((sl) => sl.weekday == day && sl.period == p)) {
          return _NextClass(
            course: c,
            period: p,
            startMin: t.startMinutes,
            endMin: t.endMinutes,
            dayOffset: offset,
            ongoing: offset == 0 && nowMin >= t.startMinutes,
          );
        }
      }
    }
  }
  return null;
}
