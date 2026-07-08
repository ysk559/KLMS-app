import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatting.dart';
import '../../data/providers.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/login_webview_page.dart';
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
    final tasks = ref.watch(tasksProvider);
    final announcements = ref.watch(announcementsProvider);
    final courseMap = ref.watch(courseMapProvider);

    final syncing = sync.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncControllerProvider.notifier).syncNow(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (auth.value == false) _LoginCard(l10n: l10n),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        syncing
                            ? l10n.syncing
                            : sync.hasError
                                ? l10n.syncFailed
                                : l10n.lastUpdated(
                                    settings.lastSyncedAt != null
                                        ? formatDateTimeShort(
                                            settings.lastSyncedAt!)
                                        : l10n.neverUpdated),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    syncing
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : TextButton.icon(
                            onPressed: () => ref
                                .read(syncControllerProvider.notifier)
                                .syncNow(),
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.refreshNow),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.upcomingTasks,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            tasks.when(
              data: (items) {
                final upcoming =
                    items.where((t) => !t.isCompleted).take(5).toList();
                if (upcoming.isEmpty) {
                  return _EmptyHint(text: l10n.noTasks);
                }
                return Card(
                  child: Column(
                    children: [
                      for (final t in upcoming)
                        TaskListTile(
                            task: t, course: courseMap[t.courseId], dense: true),
                    ],
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _EmptyHint(text: l10n.syncFailed),
            ),
            const SizedBox(height: 16),
            Text(l10n.recentAnnouncements,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            announcements.when(
              data: (items) {
                final recent = items.take(5).toList();
                if (recent.isEmpty) {
                  return _EmptyHint(text: l10n.noAnnouncements);
                }
                return Card(
                  child: Column(
                    children: [
                      for (final a in recent)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.campaign_outlined),
                          title: Text(a.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            [
                              if (a.courseId != null &&
                                  courseMap[a.courseId] != null)
                                courseMap[a.courseId]!.shortLabel,
                              if (a.postedAt != null)
                                formatDateTimeShort(a.postedAt!),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            if (a.message != null && a.message!.isNotEmpty) {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => HtmlContentPage(
                                      title: a.title, html: a.message!)));
                            } else if (a.url != null) {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => LmsWebViewPage(
                                      url: a.url!, title: a.title)));
                            }
                          },
                        ),
                    ],
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _EmptyHint(text: l10n.syncFailed),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends ConsumerWidget {
  const _LoginCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.notLoggedIn,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: scheme.onPrimaryContainer)),
            const SizedBox(height: 8),
            Text(l10n.loginPrompt,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onPrimaryContainer)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LoginWebViewPage())),
              icon: const Icon(Icons.login),
              label: Text(l10n.loginButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text,
          style: TextStyle(color: Theme.of(context).colorScheme.outline)),
    );
  }
}
