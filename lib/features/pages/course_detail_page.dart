import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../data/models/course.dart';
import '../../data/models/course_module.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'lms_webview_page.dart';
import 'module_item_page.dart';

/// Course page mirroring the LMS layout: collapsible modules with their
/// items underneath.
class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final modules = ref.watch(modulesProvider(course.id));
    final courseUrl = '${KlmsConstants.baseUrl}/courses/${course.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text(course.parsed.displayName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: l10n.openOnLms,
            icon: const Icon(Icons.open_in_new),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LmsWebViewPage(
                    url: courseUrl, title: course.parsed.displayName))),
          ),
        ],
      ),
      body: modules.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.noModules));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(modulesProvider(course.id)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                for (final m in items)
                  ExpansionTile(
                    title: Text(m.name),
                    initiallyExpanded: items.length <= 3,
                    children: [
                      for (final item in m.items)
                        _ModuleItemTile(item: item, course: course),
                    ],
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.syncFailed),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.invalidate(modulesProvider(course.id)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleItemTile extends StatelessWidget {
  const _ModuleItemTile({required this.item, required this.course});

  final ModuleItem item;
  final Course course;

  static const _icons = <String, IconData>{
    'File': Icons.insert_drive_file_outlined,
    'Page': Icons.article_outlined,
    'Discussion': Icons.forum_outlined,
    'Assignment': Icons.assignment_outlined,
    'Quiz': Icons.quiz_outlined,
    'ExternalUrl': Icons.link,
    'ExternalTool': Icons.extension_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (item.isHeader) {
      return Padding(
        padding: EdgeInsets.only(left: 16.0 + item.indent * 12, top: 12, bottom: 4, right: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(item.title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ),
      );
    }
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: 16.0 + item.indent * 12, right: 16),
      leading: Icon(_icons[item.type] ?? Icons.circle_outlined, size: 20),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _handleTap(context),
    );
  }

  void _handleTap(BuildContext context) {
    switch (item.type) {
      case 'ExternalUrl':
      case 'ExternalTool':
        // These point off-LMS: open in the user's regular browser instead of
        // the in-app WebView.
        if (item.htmlUrl != null) {
          launchUrl(Uri.parse(item.htmlUrl!), mode: LaunchMode.externalApplication);
        }
        return;
      case 'Assignment':
      case 'Quiz':
        // Submission flows need the real LMS UI.
        _openLms(context);
        return;
      case 'Page':
        if (item.pageUrl != null) {
          _openModuleItem(context);
        } else {
          _openLms(context);
        }
        return;
      case 'Discussion':
      case 'File':
        if (item.contentId != null) {
          _openModuleItem(context);
        } else {
          _openLms(context);
        }
        return;
      default:
        _openLms(context);
    }
  }

  void _openModuleItem(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ModuleItemPage(course: course, item: item)));
  }

  void _openLms(BuildContext context) {
    if (item.htmlUrl == null) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LmsWebViewPage(url: item.htmlUrl!, title: item.title)));
  }
}
