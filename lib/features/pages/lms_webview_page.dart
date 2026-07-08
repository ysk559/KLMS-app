import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

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
        ),
        onProgressChanged: (_, progress) =>
            setState(() => _progress = progress / 100),
      ),
    );
  }
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
    return Scaffold(
      appBar: AppBar(
          title: Text(title, overflow: TextOverflow.ellipsis),
          backgroundColor: scheme.surface),
      body: InAppWebView(
        initialData: InAppWebViewInitialData(data: page),
        initialSettings: InAppWebViewSettings(javaScriptEnabled: false),
      ),
    );
  }

  static String _escapeHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
