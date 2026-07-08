import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// In-app login: the user signs in to KLMS (keio.jp → Okta MFA) once.
/// Only the resulting session cookies are kept, in the WebView's persistent
/// store — the ID/password never touch the app.
class LoginWebViewPage extends ConsumerStatefulWidget {
  const LoginWebViewPage({super.key});

  @override
  ConsumerState<LoginWebViewPage> createState() => _LoginWebViewPageState();
}

class _LoginWebViewPageState extends ConsumerState<LoginWebViewPage> {
  bool _finished = false;
  double _progress = 0;

  Future<void> _checkLoggedIn(Uri? url) async {
    if (_finished || url == null) return;
    // Only consider it done once we are back on the LMS itself (not on
    // keio.jp / Okta) with a Canvas session cookie set.
    if (url.host != Uri.parse(KlmsConstants.baseUrl).host) return;
    if (url.path.startsWith('/login')) return;
    final hasSession =
        await ref.read(authServiceProvider).hasSessionCookie();
    if (!hasSession || !mounted) return;
    _finished = true;
    ref.read(dbVersionProvider.notifier).state++; // refresh auth status
    ref.read(syncControllerProvider.notifier).syncNow();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).loginSuccess)),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
        bottom: _progress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(KlmsConstants.loginUrl)),
        initialSettings: InAppWebViewSettings(
          // Persist cookies/localStorage so Okta & Canvas sessions survive
          // app restarts ("認証スキップ").
          incognito: false,
          clearCache: false,
          javaScriptEnabled: true,
          userAgent: null,
        ),
        onProgressChanged: (_, progress) =>
            setState(() => _progress = progress / 100),
        onLoadStop: (_, url) => _checkLoggedIn(url),
        onUpdateVisitedHistory: (_, url, __) => _checkLoggedIn(url),
      ),
    );
  }
}
