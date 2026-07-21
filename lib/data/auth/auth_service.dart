import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';

/// Manages KLMS credentials.
///
/// Two modes, checked in this order:
///  1. Access token (user-generated in Canvas settings) stored in the
///     platform keychain — most stable.
///  2. Canvas session cookies captured by the in-app WebView login. The user's
///     ID/password are never stored; only session cookies are reused.
///
/// Cookies are mirrored into secure storage so they survive app restarts
/// (iOS WKWebView drops session-only cookies when the app is killed) and are
/// reachable from the background sync isolate, which cannot touch the WebView
/// cookie store.
class AuthService {
  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'canvas_access_token';
  static const _cookiesKey = 'lms_cookies_v1';

  final FlutterSecureStorage _storage;

  CookieManager get _cookieManager => CookieManager.instance();

  Future<String?> getAccessToken() => _storage.read(key: _tokenKey);

  Future<void> setAccessToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _storage.delete(key: _tokenKey);
    } else {
      await _storage.write(key: _tokenKey, value: token.trim());
    }
  }

  /// Live cookies from the WebView store (main isolate only).
  Future<List<Cookie>> _webViewCookies() async {
    try {
      return await _cookieManager.getCookies(url: WebUri(KlmsConstants.baseUrl));
    } catch (_) {
      // Platform channel unavailable (background isolate / tests).
      return const [];
    }
  }

  /// Cookies previously persisted to secure storage, as (name → value) pairs
  /// plus a synthetic list for CSRF lookup.
  Future<List<_StoredCookie>> _persistedCookies() async {
    try {
      final raw = await _storage.read(key: _cookiesKey);
      if (raw == null || raw.isEmpty) return const [];
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(_StoredCookie.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Snapshot the current WebView LMS cookies into secure storage. Call after a
  /// successful login and whenever the app returns to the foreground so any
  /// rotated cookies are captured.
  Future<void> saveSessionCookies() async {
    final cookies = await _webViewCookies();
    if (cookies.isEmpty) return;
    final hasSession =
        cookies.any((c) => KlmsConstants.sessionCookieNames.contains(c.name));
    if (!hasSession) return; // don't overwrite good data with a logged-out set
    final json = jsonEncode([
      for (final c in cookies)
        {
          'n': c.name,
          'v': c.value?.toString() ?? '',
          'd': c.domain,
          'p': c.path,
          'e': c.expiresDate,
          's': c.isSecure,
          'h': c.isHttpOnly,
        },
    ]);
    await _storage.write(key: _cookiesKey, value: json);
  }

  /// Push persisted cookies back into the WebView store on launch so in-app
  /// LMS browsing and silent SSO refresh keep working. Session cookies (no
  /// expiry) are given a persistent expiry so WKWebView keeps them on disk.
  Future<void> restoreCookies() async {
    final stored = await _persistedCookies();
    if (stored.isEmpty) return;
    final host = Uri.parse(KlmsConstants.baseUrl).host;
    final fallbackExpiry =
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
    for (final c in stored) {
      try {
        await _cookieManager.setCookie(
          url: WebUri(KlmsConstants.baseUrl),
          name: c.name,
          value: c.value,
          domain: c.domain ?? host,
          path: c.path ?? '/',
          expiresDate: c.expiresDate ?? fallbackExpiry,
          isSecure: c.isSecure ?? true,
          isHttpOnly: c.isHttpOnly ?? false,
        );
      } catch (_) {
        // best-effort
      }
    }
  }

  Future<bool> hasSessionCookie() async {
    final live = await _webViewCookies();
    if (live.any((c) => KlmsConstants.sessionCookieNames.contains(c.name))) {
      return true;
    }
    final stored = await _persistedCookies();
    return stored
        .any((c) => KlmsConstants.sessionCookieNames.contains(c.name));
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) return true;
    return hasSessionCookie();
  }

  /// Headers to authenticate an API request (token or cookie mode). Falls back
  /// to persisted cookies when the WebView store is empty (background isolate,
  /// or after the WebView dropped session cookies on restart).
  Future<Map<String, String>> authHeaders() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }

    final live = await _webViewCookies();
    final pairs = <String, String>{};
    if (live.isNotEmpty) {
      for (final c in live) {
        pairs[c.name] = c.value?.toString() ?? '';
      }
    } else {
      for (final c in await _persistedCookies()) {
        pairs[c.name] = c.value;
      }
    }
    if (pairs.isEmpty) return const {};

    final headers = <String, String>{
      'Cookie': pairs.entries.map((e) => '${e.key}=${e.value}').join('; '),
    };
    // Canvas requires the CSRF token (URL-encoded in its cookie) as a header
    // for non-GET requests authenticated by session cookies.
    final csrf = pairs[KlmsConstants.csrfCookieName];
    if (csrf != null) {
      headers['X-CSRF-Token'] = Uri.decodeComponent(csrf);
    }
    return headers;
  }

  /// Clears the stored token and every cookie of the LMS domain (WebView +
  /// persisted).
  Future<void> logout() async {
    await setAccessToken(null);
    await _storage.delete(key: _cookiesKey);
    try {
      await _cookieManager.deleteCookies(url: WebUri(KlmsConstants.baseUrl));
    } catch (_) {}
  }
}

class _StoredCookie {
  const _StoredCookie({
    required this.name,
    required this.value,
    this.domain,
    this.path,
    this.expiresDate,
    this.isSecure,
    this.isHttpOnly,
  });

  final String name;
  final String value;
  final String? domain;
  final String? path;
  final int? expiresDate;
  final bool? isSecure;
  final bool? isHttpOnly;

  factory _StoredCookie.fromJson(Map<String, dynamic> j) => _StoredCookie(
        name: j['n'] as String,
        value: (j['v'] as String?) ?? '',
        domain: j['d'] as String?,
        path: j['p'] as String?,
        expiresDate: j['e'] as int?,
        isSecure: j['s'] as bool?,
        isHttpOnly: j['h'] as bool?,
      );
}
