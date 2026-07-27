import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/glass.dart';
import '../../core/utils/formatting.dart';
import '../../data/settings/settings_controller.dart';
import '../../data/sync/sync_log.dart';
import '../../l10n/generated/app_localizations.dart';

/// Shows the rolling sync log so the user can verify that background refresh
/// actually runs (iOS in particular gives no other signal).
class SyncLogPage extends ConsumerStatefulWidget {
  const SyncLogPage({super.key});

  @override
  ConsumerState<SyncLogPage> createState() => _SyncLogPageState();
}

class _SyncLogPageState extends ConsumerState<SyncLogPage> {
  late List<SyncLogEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = SyncLog.read(ref.read(sharedPreferencesProvider));
  }

  Future<void> _reload() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.reload();
    setState(() => _entries = SyncLog.read(prefs));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncLog),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            tooltip: l10n.syncLogClear,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await SyncLog.clear(ref.read(sharedPreferencesProvider));
              await _reload();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_entries.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Text(l10n.syncLogEmpty,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6))),
              )
            else
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < _entries.length; i++) ...[
                      if (i > 0) const Divider(indent: 52),
                      _LogRow(entry: _entries[i]),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final SyncLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (entry.result) {
      'ok' => (Icons.check_circle, Colors.green),
      'reauth' => (Icons.autorenew, Colors.blue),
      'auth' => (Icons.lock_outline, Colors.orange),
      'error' => (Icons.error_outline, theme.colorScheme.error),
      'start' => (Icons.play_arrow, theme.colorScheme.onSurface),
      _ => (Icons.remove_circle_outline, theme.colorScheme.outline),
    };
    final isBackground = entry.source == 'background';
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        '${isBackground ? "バックグラウンド" : "アプリ内"} · ${entry.result}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          formatDateTimeShort(entry.at),
          if (entry.detail != null) entry.detail!,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
