import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A rolling, on-device log of sync attempts so the user (and we) can tell
/// whether background refresh is actually running on iOS/Android, where the
/// OS gives no other feedback. Kept tiny and written through SharedPreferences
/// so both the UI and the background isolate can append to it.
class SyncLog {
  SyncLog._();

  static const String prefsKey = 'sync_log_v1';
  static const int _maxEntries = 40;

  static Future<void> add(String source, String result, {String? detail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final entries = read(prefs);
      entries.insert(
        0,
        SyncLogEntry(
          at: DateTime.now(),
          source: source,
          result: result,
          detail: detail,
        ),
      );
      final trimmed = entries.take(_maxEntries).toList();
      await prefs.setString(
          prefsKey, jsonEncode([for (final e in trimmed) e.toJson()]));
    } catch (_) {
      // Logging must never break a sync.
    }
  }

  static List<SyncLogEntry> read(SharedPreferences prefs) {
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(SyncLogEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear(SharedPreferences prefs) =>
      prefs.remove(prefsKey);
}

class SyncLogEntry {
  const SyncLogEntry({
    required this.at,
    required this.source,
    required this.result,
    this.detail,
  });

  final DateTime at;

  /// 'background' or 'foreground'.
  final String source;

  /// 'ok', 'auth', 'error', 'skipped'.
  final String result;
  final String? detail;

  Map<String, dynamic> toJson() => {
        't': at.toIso8601String(),
        's': source,
        'r': result,
        if (detail != null) 'd': detail,
      };

  factory SyncLogEntry.fromJson(Map<String, dynamic> j) => SyncLogEntry(
        at: DateTime.tryParse(j['t'] as String? ?? '') ?? DateTime.now(),
        source: j['s'] as String? ?? '?',
        result: j['r'] as String? ?? '?',
        detail: j['d'] as String?,
      );
}
