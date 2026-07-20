import 'package:dio/dio.dart';

import '../../core/constants.dart';
import '../auth/auth_service.dart';
import '../models/announcement.dart';
import '../models/course.dart';
import '../models/course_module.dart';
import '../models/task_item.dart';

/// Thrown when the LMS answers 401/redirects to login: session expired.
class CanvasAuthException implements Exception {
  const CanvasAuthException([this.message = 'Not authenticated']);
  final String message;

  @override
  String toString() => 'CanvasAuthException: $message';
}

/// Thin client over the Canvas REST API (https://canvas.instructure.com/doc/api).
class CanvasClient {
  CanvasClient(this._auth, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: KlmsConstants.apiBase,
              headers: {'Accept': 'application/json'},
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              // We need to see 401s ourselves instead of throwing.
              validateStatus: (s) => s != null && s < 500,
            ));

  final AuthService _auth;
  final Dio _dio;

  static const int _maxPages = 15;

  Future<List<Map<String, dynamic>>> _getPaginated(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final results = <Map<String, dynamic>>[];
    final headers = await _auth.authHeaders();
    if (headers.isEmpty) throw const CanvasAuthException('No credentials');

    String? next = path;
    var pages = 0;
    Map<String, dynamic>? currentQuery = {'per_page': 100, ...?query};

    while (next != null && pages < _maxPages) {
      final response = await _dio.get<dynamic>(
        next,
        queryParameters: currentQuery,
        options: Options(headers: headers),
      );
      _checkAuth(response);
      final data = response.data;
      if (data is List) {
        results.addAll(data.cast<Map<String, dynamic>>());
      } else {
        break;
      }
      next = _nextLink(response);
      currentQuery = null; // the next link already carries the query string
      pages++;
    }
    return results;
  }

  Future<Map<String, dynamic>> _getObject(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final headers = await _auth.authHeaders();
    if (headers.isEmpty) throw const CanvasAuthException('No credentials');
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: query,
      options: Options(headers: headers),
    );
    _checkAuth(response);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response shape for $path');
  }

  void _checkAuth(Response response) {
    final status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      throw CanvasAuthException('HTTP $status');
    }
    // Cookie-mode with an expired session redirects to the HTML login page.
    if (response.data is String &&
        (response.data as String).contains('<html')) {
      throw const CanvasAuthException('Got login page instead of JSON');
    }
  }

  String? _nextLink(Response response) {
    final link = response.headers.value('link');
    if (link == null) return null;
    for (final part in link.split(',')) {
      final sections = part.split(';');
      if (sections.length < 2) continue;
      if (sections[1].contains('rel="next"')) {
        final url = sections[0].trim();
        return url.substring(1, url.length - 1); // strip <>
      }
    }
    return null;
  }

  /// Active courses of the current user.
  Future<List<Course>> getCourses() async {
    final rows = await _getPaginated('/courses', query: {
      'enrollment_state': 'active',
      'include[]': ['term'],
    });
    return rows
        .where((r) => r['access_restricted_by_date'] != true && r['name'] != null)
        .map(Course.fromApi)
        .toList();
  }

  /// All assignments of a course, including ones that never appear on the
  /// dashboard, with the user's submission state.
  Future<List<TaskItem>> getAssignments(int courseId) async {
    final rows = await _getPaginated(
      '/courses/$courseId/assignments',
      query: {
        'include[]': ['submission'],
        'order_by': 'due_at',
      },
    );
    return rows
        .map((r) => TaskItem.fromAssignmentApi({...r, 'course_id': courseId}))
        .toList();
  }

  /// Announcements of the given courses since [since].
  Future<List<Announcement>> getAnnouncements(
    List<int> courseIds, {
    DateTime? since,
  }) async {
    if (courseIds.isEmpty) return const [];
    final results = <Announcement>[];
    // Canvas accepts many context codes, but keep request URLs sane.
    for (var i = 0; i < courseIds.length; i += 10) {
      final chunk = courseIds.skip(i).take(10);
      final rows = await _getPaginated('/announcements', query: {
        'context_codes[]': chunk.map((id) => 'course_$id').toList(),
        if (since != null) 'start_date': since.toUtc().toIso8601String(),
        'active_only': true,
      });
      results.addAll(rows.map(Announcement.fromApi));
    }
    results.sort((a, b) {
      final ap = a.postedAt, bp = b.postedAt;
      if (ap == null || bp == null) return 0;
      return bp.compareTo(ap);
    });
    return results;
  }

  /// Assignment ids the user marked as done on the Canvas planner
  /// (the LMS "完了にする" checkmark), regardless of submission state.
  Future<Set<int>> getPlannerCompletedAssignmentIds({DateTime? since}) async {
    final rows = await _getPaginated('/planner/items', query: {
      'start_date': (since ?? DateTime.now().subtract(const Duration(days: 30)))
          .toUtc()
          .toIso8601String(),
    });
    final ids = <int>{};
    for (final r in rows) {
      final override = r['planner_override'];
      if (override is! Map || override['marked_complete'] != true) continue;
      // Quizzes/discussions surface their assignment via the plannable.
      final plannable = r['plannable'];
      final assignmentId = switch (r['plannable_type']) {
        'assignment' => r['plannable_id'] as int?,
        _ => plannable is Map ? plannable['assignment_id'] as int? : null,
      };
      if (assignmentId != null) ids.add(assignmentId);
    }
    return ids;
  }

  /// Modules (with items) of a course — the "dropdown" sections of the page.
  Future<List<CourseModule>> getModules(int courseId) async {
    final rows = await _getPaginated(
      '/courses/$courseId/modules',
      query: {
        'include[]': ['items'],
      },
    );
    return rows.map(CourseModule.fromApi).toList();
  }

  /// A single course wiki page (fields used: `title`, `body`).
  Future<Map<String, dynamic>> getPage(int courseId, String pageUrl) =>
      _getObject('/courses/$courseId/pages/$pageUrl');

  /// Metadata for a Canvas file: `display_name`, `content-type`, and a
  /// pre-signed `url` that needs no auth headers to download.
  Future<Map<String, dynamic>> getFileInfo(int fileId) =>
      _getObject('/files/$fileId');

  /// A discussion topic (fields used: `title`, `message`).
  Future<Map<String, dynamic>> getDiscussion(int courseId, int topicId) =>
      _getObject('/courses/$courseId/discussion_topics/$topicId');

  /// Downloads raw bytes from a Canvas file URL. Some Keio LMS file URLs still
  /// require the session cookie (they 302 to the login page otherwise), so we
  /// attach the same auth headers as the API and follow redirects. The cookie
  /// is harmless if the URL redirects to a pre-signed CDN link.
  Future<List<int>> downloadPublicBytes(String url) async {
    final headers = await _auth.authHeaders();
    final response = await Dio().get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: headers.isEmpty ? null : headers,
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    return response.data ?? const [];
  }
}
