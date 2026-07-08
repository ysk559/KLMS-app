import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';

/// Manages KLMS credentials.
///
/// Two modes, checked in this order:
///  1. Access token (user-generated in Canvas settings) stored in the
///     platform keychain — most stable.
///  2. Canvas session cookies captured by the in-app WebView login and kept
///     in the WebView's persistent cookie store. The user's ID/password are
///     never stored; only session cookies are reused.
class AuthService {
  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'canvas_access_token';

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

  Future<List<Cookie>> _lmsCookies() async {
    try {
      return await _cookieManager.getCookies(
          url: WebUri(KlmsConstants.baseUrl));
    } catch (_) {
      // Platform channel unavailable (e.g. tests).
      return const [];
    }
  }

  Future<bool> hasSessionCookie() async {
    final cookies = await _lmsCookies();
    return cookies.any((c) => c.name == KlmsConstants.sessionCookieName);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) return true;
    return hasSessionCookie();
  }

  /// Headers to authenticate an API request (token or cookie mode).
  Future<Map<String, String>> authHeaders() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    final cookies = await _lmsCookies();
    if (cookies.isEmpty) return const {};
    final headers = <String, String>{
      'Cookie': cookies.map((c) => '${c.name}=${c.value}').join('; '),
    };
    // Canvas requires the CSRF token (URL-encoded in its cookie) as a header
    // for non-GET requests authenticated by session cookies.
    final csrf = cookies
        .where((c) => c.name == KlmsConstants.csrfCookieName)
        .map((c) => c.value?.toString())
        .firstWhere((v) => v != null, orElse: () => null);
    if (csrf != null) {
      headers['X-CSRF-Token'] = Uri.decodeComponent(csrf);
    }
    return headers;
  }

  /// Clears the stored token and every cookie of the LMS domain.
  Future<void> logout() async {
    await setAccessToken(null);
    try {
      await _cookieManager.deleteCookies(url: WebUri(KlmsConstants.baseUrl));
    } catch (_) {}
  }
}
