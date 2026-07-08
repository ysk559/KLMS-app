/// KLMS (Keio LMS, Canvas) related constants.
class KlmsConstants {
  KlmsConstants._();

  static const String baseUrl = 'https://lms.keio.jp';
  static const String loginUrl = '$baseUrl/login';
  static const String apiBase = '$baseUrl/api/v1';

  /// Cookies that indicate an authenticated Canvas session (the name
  /// differs between Canvas versions/configurations).
  static const Set<String> sessionCookieNames = {
    'canvas_session',
    '_normandy_session',
    '_legacy_normandy_session',
  };
  static const String csrfCookieName = '_csrf_token';

  /// Placeholder until the real contact destination is decided
  /// (see docs/QUESTIONS.md #6).
  static const String contactUrl = 'mailto:yoshiki36g@gmail.com';
}
