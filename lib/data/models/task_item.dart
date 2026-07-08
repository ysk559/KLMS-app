/// An actionable LMS task (assignment, quiz, ...).
class TaskItem {
  const TaskItem({
    required this.id,
    required this.courseId,
    required this.title,
    this.type = 'assignment',
    this.dueAt,
    this.htmlUrl,
    this.pointsPossible,
    this.lmsCompleted = false,
    this.userCompleted = false,
    this.conflictNotified = false,
    this.description,
  });

  final int id;
  final int courseId;
  final String title;
  final String type;

  /// Due date in UTC (as returned by Canvas); convert with `.toLocal()`.
  final DateTime? dueAt;
  final String? htmlUrl;
  final double? pointsPossible;

  /// Completed according to the LMS (submitted / graded).
  final bool lmsCompleted;

  /// Completed manually inside the app.
  final bool userCompleted;

  /// Whether the "done in app but not on LMS" conflict has been notified.
  final bool conflictNotified;
  final String? description;

  bool get isCompleted => lmsCompleted || userCompleted;

  /// User marked it done, but a fresh sync says the LMS disagrees.
  bool get hasConflict => userCompleted && !lmsCompleted;

  TaskItem copyWith({
    bool? lmsCompleted,
    bool? userCompleted,
    bool? conflictNotified,
  }) =>
      TaskItem(
        id: id,
        courseId: courseId,
        title: title,
        type: type,
        dueAt: dueAt,
        htmlUrl: htmlUrl,
        pointsPossible: pointsPossible,
        lmsCompleted: lmsCompleted ?? this.lmsCompleted,
        userCompleted: userCompleted ?? this.userCompleted,
        conflictNotified: conflictNotified ?? this.conflictNotified,
        description: description,
      );

  /// Builds a task from a Canvas assignment JSON (with `include[]=submission`).
  factory TaskItem.fromAssignmentApi(Map<String, dynamic> json) {
    final submission = json['submission'] as Map<String, dynamic>?;
    final workflow = submission?['workflow_state'] as String?;
    const doneStates = {'submitted', 'graded', 'pending_review', 'complete'};
    // A graded submission with no actual attempt (e.g. grade of 0 entered by
    // the teacher for a missed assignment) still counts as "handled" on the
    // LMS side, so doneStates is intentionally broad.
    final lmsDone = workflow != null &&
        doneStates.contains(workflow) &&
        (submission?['submitted_at'] != null || workflow == 'graded' || workflow == 'complete');
    return TaskItem(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      title: (json['name'] ?? '?') as String,
      type: 'assignment',
      dueAt: json['due_at'] != null
          ? DateTime.tryParse(json['due_at'] as String)
          : null,
      htmlUrl: json['html_url'] as String?,
      pointsPossible: (json['points_possible'] as num?)?.toDouble(),
      lmsCompleted: lmsDone,
      description: json['description'] as String?,
    );
  }

  factory TaskItem.fromRow(Map<String, dynamic> row) => TaskItem(
        id: row['id'] as int,
        courseId: row['course_id'] as int,
        title: row['title'] as String,
        type: row['type'] as String? ?? 'assignment',
        dueAt: row['due_at'] != null
            ? DateTime.tryParse(row['due_at'] as String)
            : null,
        htmlUrl: row['html_url'] as String?,
        pointsPossible: row['points_possible'] as double?,
        lmsCompleted: (row['lms_completed'] as int? ?? 0) != 0,
        userCompleted: (row['user_completed'] as int? ?? 0) != 0,
        conflictNotified: (row['conflict_notified'] as int? ?? 0) != 0,
        description: row['description'] as String?,
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'course_id': courseId,
        'title': title,
        'type': type,
        'due_at': dueAt?.toIso8601String(),
        'html_url': htmlUrl,
        'points_possible': pointsPossible,
        'lms_completed': lmsCompleted ? 1 : 0,
        'user_completed': userCompleted ? 1 : 0,
        'conflict_notified': conflictNotified ? 1 : 0,
        'description': description,
      };
}
