import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/course.dart';
import '../../data/models/course_module.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'lms_webview_page.dart';

/// Displays a single module item's content in-app: a wiki page, a discussion,
/// or a file (image / text / PDF), instead of dropping straight into the
/// LMS WebView. Falls back to that WebView on error.
class ModuleItemPage extends ConsumerStatefulWidget {
  const ModuleItemPage({super.key, required this.course, required this.item});

  final Course course;
  final ModuleItem item;

  @override
  ConsumerState<ModuleItemPage> createState() => _ModuleItemPageState();
}

class _ModuleItemPageState extends ConsumerState<ModuleItemPage> {
  bool _loading = true;
  Object? _error;
  Widget? _content;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await _resolve();
      if (!mounted) return;
      setState(() {
        _content = content;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<Widget> _resolve() async {
    final client = ref.read(canvasClientProvider);
    final item = widget.item;
    switch (item.type) {
      case 'Page':
        final pageUrl = item.pageUrl;
        if (pageUrl == null) return _fallbackWebView();
        final json = await client.getPage(widget.course.id, pageUrl);
        return HtmlContentView(
          html: (json['body'] as String?) ?? '',
          heading: (json['title'] as String?) ?? item.title,
        );

      case 'Discussion':
        final topicId = item.contentId;
        if (topicId == null) return _fallbackWebView();
        final json = await client.getDiscussion(widget.course.id, topicId);
        return HtmlContentView(
          html: (json['message'] as String?) ?? '',
          heading: (json['title'] as String?) ?? item.title,
        );

      case 'File':
        final fileId = item.contentId;
        if (fileId == null) return _fallbackWebView();
        final json = await client.getFileInfo(fileId);
        final contentType = (json['content-type'] as String?) ?? '';
        final url = json['url'] as String?;
        if (url == null) return _fallbackWebView();

        if (contentType.startsWith('image/')) {
          final bytes = await client.downloadPublicBytes(url);
          return InteractiveViewer(
            child: Center(
              child: Image.memory(Uint8List.fromList(bytes)),
            ),
          );
        }
        if (contentType.startsWith('text/') || contentType == 'application/json') {
          final bytes = await client.downloadPublicBytes(url);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              utf8.decode(bytes, allowMalformed: true),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          );
        }
        if (contentType == 'application/pdf') {
          if (Platform.isIOS) {
            // WKWebView (used on iOS) renders PDFs natively.
            return InAppWebView(initialUrlRequest: URLRequest(url: WebUri(url)));
          }
          // Android's WebView doesn't reliably render PDFs: fall back to the
          // Canvas file preview page.
          final previewUrl = item.htmlUrl ?? url;
          return InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(previewUrl)));
        }
        final fallbackUrl = item.htmlUrl ?? url;
        return InAppWebView(initialUrlRequest: URLRequest(url: WebUri(fallbackUrl)));

      default:
        return _fallbackWebView();
    }
  }

  Widget _fallbackWebView() {
    final url = widget.item.htmlUrl;
    if (url == null) {
      throw StateError('No content available for this item');
    }
    return InAppWebView(initialUrlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.parsed.displayName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.syncFailed),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _load,
                        child: Text(l10n.retry),
                      ),
                      if (widget.item.htmlUrl != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushReplacement(MaterialPageRoute(
                                  builder: (_) => LmsWebViewPage(
                                      url: widget.item.htmlUrl!,
                                      title: widget.item.title))),
                          child: Text(l10n.openOnLms),
                        ),
                      ],
                    ],
                  ),
                )
              : _content!,
    );
  }
}
