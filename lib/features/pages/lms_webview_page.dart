import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../l10n/generated/app_localizations.dart';

/// Opens any LMS page inside the app, reusing the persistent authenticated
/// WebView session (no re-login needed).
class LmsWebViewPage extends StatefulWidget {
  const LmsWebViewPage({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<LmsWebViewPage> createState() => _LmsWebViewPageState();
}

class _LmsWebViewPageState extends State<LmsWebViewPage> {
  double _progress = 0;
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'KLMS', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: l10n.openInBrowser,
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => launchUrl(Uri.parse(widget.url),
                mode: LaunchMode.externalApplication),
          ),
        ],
        bottom: _progress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          incognito: false,
          javaScriptEnabled: true,
          supportMultipleWindows: true,
          javaScriptCanOpenWindowsAutomatically: true,
        ),
        onWebViewCreated: (c) => _controller = c,
        // Keep target="_blank" links inside this authenticated WebView instead
        // of letting them open in the external browser (unauthenticated).
        onCreateWindow: (controller, action) async {
          final url = action.request.url;
          if (url != null) {
            await _controller?.loadUrl(urlRequest: URLRequest(url: url));
          }
          return false;
        },
        onProgressChanged: (_, progress) =>
            setState(() => _progress = progress / 100),
      ),
    );
  }
}

/// Renders raw HTML (e.g. an announcement body, a Canvas page or discussion)
/// inside the app. [heading] is an optional headline shown above the body.
/// This is the reusable body-only piece behind [HtmlContentPage]; use it
/// directly when a full Scaffold/AppBar isn't wanted (e.g. ModuleItemPage).
///
/// Links tapped inside the content open in an in-app [LmsWebViewPage] (which
/// reuses the authenticated session) instead of the external browser — the
/// external browser has no LMS cookies, so those pages answered
/// "ユーザ認証が必要です".
class HtmlContentView extends StatelessWidget {
  const HtmlContentView({super.key, required this.html, this.heading});

  final String html;
  final String? heading;

  void _openInApp(BuildContext context, WebUri? uri) {
    final url = uri?.toString();
    if (url == null || !(url.startsWith('http'))) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => LmsWebViewPage(url: url)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingHtml = heading != null
        ? '<h2 style="margin-top:0;font-size:1.2em;">${_escapeHtml(heading!)}</h2>'
        : '';
    final page = '''
<!doctype html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body { font-family: -apple-system, "Hiragino Sans", Roboto, sans-serif;
         margin: 16px; line-height: 1.7;
         background: ${isDark ? '#111318' : '#ffffff'};
         color: ${isDark ? '#e2e2e9' : '#1a1b21'}; }
  a { color: #4a6fd4; } img { max-width: 100%; height: auto; }
</style></head><body>$headingHtml$html</body></html>''';
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: page,
        baseUrl: WebUri(KlmsConstants.baseUrl),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: false,
        useShouldOverrideUrlLoading: true,
        supportMultipleWindows: true,
        javaScriptCanOpenWindowsAutomatically: true,
      ),
      // A tapped link: open it in-app (keeps the session) rather than letting
      // it escape to the external browser.
      shouldOverrideUrlLoading: (controller, action) async {
        if (action.navigationType == NavigationType.LINK_ACTIVATED) {
          _openInApp(context, action.request.url);
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
      // A target="_blank" link would otherwise spawn a new window / external
      // browser — route it in-app too.
      onCreateWindow: (controller, action) async {
        _openInApp(context, action.request.url);
        return false;
      },
    );
  }

  static String _escapeHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

/// Renders raw HTML (e.g. an announcement body) inside the app.
/// [title] is the app-bar text (course name for announcements) and
/// [heading] an optional headline shown above the body.
class HtmlContentPage extends StatelessWidget {
  const HtmlContentPage(
      {super.key, required this.title, required this.html, this.heading});

  final String title;
  final String html;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(title, overflow: TextOverflow.ellipsis),
          backgroundColor: scheme.surface),
      body: HtmlContentView(html: html, heading: heading),
    );
  }
}
