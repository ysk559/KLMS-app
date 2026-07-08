/// Canvas module (the "dropdown" sections on a course page).
class CourseModule {
  const CourseModule({
    required this.id,
    required this.name,
    this.items = const [],
  });

  final int id;
  final String name;
  final List<ModuleItem> items;

  factory CourseModule.fromApi(Map<String, dynamic> json) => CourseModule(
        id: json['id'] as int,
        name: (json['name'] ?? '?') as String,
        items: (json['items'] as List? ?? const [])
            .map((e) => ModuleItem.fromApi(e as Map<String, dynamic>))
            .toList(),
      );
}

class ModuleItem {
  const ModuleItem({
    required this.id,
    required this.title,
    required this.type,
    this.htmlUrl,
    this.pageUrl,
    this.contentId,
    this.indent = 0,
  });

  final int id;
  final String title;

  /// File / Page / Discussion / Assignment / Quiz / SubHeader / ExternalUrl...
  final String type;
  final String? htmlUrl;
  final String? pageUrl;
  final int? contentId;
  final int indent;

  bool get isHeader => type == 'SubHeader';

  factory ModuleItem.fromApi(Map<String, dynamic> json) => ModuleItem(
        id: json['id'] as int,
        title: (json['title'] ?? '?') as String,
        type: (json['type'] ?? 'ExternalUrl') as String,
        htmlUrl: (json['html_url'] ?? json['external_url']) as String?,
        pageUrl: json['page_url'] as String?,
        contentId: json['content_id'] as int?,
        indent: json['indent'] as int? ?? 0,
      );
}
