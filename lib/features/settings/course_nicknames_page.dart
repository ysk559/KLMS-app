import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';

class CourseNicknamesPage extends ConsumerWidget {
  const CourseNicknamesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final courses = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.courseNicknames)),
      body: courses.when(
        data: (items) => ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final course = items[i];
            return ListTile(
              title: Text(course.parsed.displayName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(course.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(
                course.nickname ?? '—',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final controller =
                    TextEditingController(text: course.nickname ?? '');
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(course.parsed.displayName,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration:
                          InputDecoration(hintText: l10n.nicknameHint),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancel)),
                      FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.save)),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref
                      .read(courseRepositoryProvider)
                      .setNickname(course.id, controller.text.trim());
                  ref.read(dbVersionProvider.notifier).state++;
                }
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.syncFailed)),
      ),
    );
  }
}
