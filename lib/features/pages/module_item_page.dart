import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

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
          // Download and render the PDF natively (Android PdfRenderer /
          // iOS PDFKit via pdfx) — no LMS page in between.
          final bytes = await client.downloadPublicBytes(url);
          // Guard against getting an HTML login/preview page instead of the
          // PDF (would otherwise crash pdfx with "Invalid PDF format"): a real
          // PDF starts with the "%PDF" magic bytes. Fall back to the WebView.
          final isPdf = bytes.length >= 4 &&
              bytes[0] == 0x25 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x44 &&
              bytes[3] == 0x46;
          if (!isPdf) return _fallbackWebView();
          return _PdfViewer(bytes: Uint8List.fromList(bytes));
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

/// Scroll/zoomable PDF rendering from raw bytes.
class _PdfViewer extends StatefulWidget {
  const _PdfViewer({required this.bytes});

  final Uint8List bytes;

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        PdfControllerPinch(document: PdfDocument.openData(widget.bytes));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(controller: _controller);
  }
}
