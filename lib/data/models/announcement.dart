class Announcement {
  const Announcement({
    required this.id,
    this.courseId,
    required this.title,
    this.message,
    this.url,
    this.postedAt,
    this.isRead = false,
  });

  final int id;
  final int? courseId;
  final String title;

  /// HTML body.
  final String? message;
  final String? url;
  final DateTime? postedAt;
  final bool isRead;

  factory Announcement.fromApi(Map<String, dynamic> json) {
    // context_code is like "course_12345".
    int? courseId;
    final context = json['context_code'] as String?;
    if (context != null && context.startsWith('course_')) {
      courseId = int.tryParse(context.substring('course_'.length));
    }
    return Announcement(
      id: json['id'] as int,
      courseId: courseId,
      title: (json['title'] ?? '?') as String,
      message: json['message'] as String?,
      url: json['html_url'] as String?,
      postedAt: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'] as String)
          : null,
    );
  }

  factory Announcement.fromRow(Map<String, dynamic> row) => Announcement(
        id: row['id'] as int,
        courseId: row['course_id'] as int?,
        title: row['title'] as String,
        message: row['message'] as String?,
        url: row['url'] as String?,
        postedAt: row['posted_at'] != null
            ? DateTime.tryParse(row['posted_at'] as String)
            : null,
        isRead: (row['is_read'] as int? ?? 0) != 0,
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'course_id': courseId,
        'title': title,
        'message': message,
        'url': url,
        'posted_at': postedAt?.toIso8601String(),
        'is_read': isRead ? 1 : 0,
      };
}
