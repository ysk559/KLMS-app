import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../background/background_sync.dart';
import '../../core/constants.dart';
import '../../data/providers.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import 'sync_log_page.dart';
import '../auth/login_webview_page.dart';
import 'course_nicknames_page.dart';
import 'exclude_courses_page.dart';
import 'timetable_settings_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  /// Email of the connected Google account, once known (best-effort — only
  /// populated after a successful connect or a silent sign-in check;
  /// otherwise the generic description is shown instead).
  String? _googleEmail;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    if (s.googleCalendarSync || s.googleTasksSync) {
      _refreshGoogleEmail();
    }
  }

  Future<void> _refreshGoogleEmail() async {
    final account =
        await ref.read(googleCalendarServiceProvider).currentOrSilent;
    if (mounted) setState(() => _googleEmail = account?.email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authStatusProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          _SectionHeader(l10n.sectionAppearance),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.themeMode),
            subtitle: Text(switch (settings.themeMode) {
              ThemeMode.system => l10n.themeSystem,
              ThemeMode.light => l10n.themeLight,
              ThemeMode.dark => l10n.themeDark,
            }),
            onTap: () => _pickTheme(context, ref, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(switch (settings.localeCode) {
              null => l10n.languageSystem,
              'ja' => '日本語',
              'en' => 'English',
              'fr' => 'Français',
              final other => other,
            }),
            onTap: () => _pickLanguage(context, ref, l10n),
          ),
          _SectionHeader(l10n.sectionNotifications),
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined),
            title: Text(l10n.announcementNotifications),
            subtitle: Text(l10n.announcementNotificationsDesc),
            value: settings.announcementNotifications,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(announcementNotifications: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm),
            title: Text(l10n.deadlineReminder),
            subtitle: Text(l10n.deadlineReminderDesc),
            value: settings.deadlineReminderEnabled,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(deadlineReminderEnabled: v)),
          ),
          ListTile(
            enabled: settings.deadlineReminderEnabled,
            leading: const Icon(Icons.schedule),
            title: Text(l10n.reminderTiming),
            subtitle: Text(l10n.reminderTimingValue(
                settings.reminderHours, settings.reminderMinutes)),
            onTap: () => _pickReminderOffset(context, ref, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.filter_alt_outlined),
            title: Text(l10n.excludeWords),
            subtitle: Text(settings.excludeWords.isEmpty
                ? l10n.excludeWordsDesc
                : settings.excludeWords.join(', ')),
            onTap: () => _editExcludeWords(context, ref, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_remove),
            title: Text(l10n.excludeCourses),
            subtitle: Text(l10n.excludeCoursesDesc),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ExcludeCoursesPage())),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_off_outlined),
            title: Text(l10n.excludeApplyToList),
            subtitle: Text(l10n.excludeApplyToListDesc),
            value: settings.excludeAlsoFromList,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(excludeAlsoFromList: v)),
          ),
          _SectionHeader(l10n.sectionSync),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l10n.backgroundSync),
            subtitle: Text(!kIsWeb && Platform.isIOS
                ? '${l10n.backgroundSyncDesc}\n${l10n.iosSyncNote}'
                : l10n.backgroundSyncDesc),
            trailing: DropdownButton<int>(
              value: settings.backgroundSyncMinutes,
              items: [
                DropdownMenuItem(value: 0, child: Text(l10n.syncIntervalOff)),
                for (final m in const [15, 30, 60, 180])
                  DropdownMenuItem(
                    value: m,
                    child: Text(m < 60
                        ? l10n.everyMinutes(m)
                        : l10n.everyHours(m ~/ 60)),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                notifier.update((s) => s.copyWith(backgroundSyncMinutes: v));
                BackgroundSyncScheduler.apply(ref.read(settingsProvider));
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.syncLog),
            subtitle: Text(l10n.syncLogDesc),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SyncLogPage())),
          ),

          // --- Google: one account, then what it syncs. ---
          _SectionHeader('Google'),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.googleAccount),
            subtitle: Text(_googleEmail ?? l10n.googleNotConnected),
            trailing: _googleEmail == null
                ? const Icon(Icons.chevron_right)
                : TextButton(
                    onPressed: () => _disconnectGoogle(context, ref, l10n),
                    child: Text(l10n.googleDisconnect),
                  ),
            onTap: _googleEmail == null
                ? () => _connectGoogle(context, ref, l10n)
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.event_available_outlined),
            title: Text(l10n.googleCalendarSync),
            subtitle: Text(l10n.googleCalendarSyncDesc),
            value: settings.googleCalendarSync,
            onChanged: (v) => _toggleGoogleCalendarSync(context, ref, l10n, v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.check_circle_outline),
            title: Text(l10n.googleTasksSync),
            subtitle: Text(l10n.googleTasksSyncDesc),
            value: settings.googleTasksSync,
            onChanged: (v) => _toggleGoogleTasksSync(context, ref, l10n, v),
          ),
          _SectionHeader(l10n.sectionCourses),
          ListTile(
            leading: const Icon(Icons.short_text),
            title: Text(l10n.courseNicknames),
            subtitle: Text(l10n.courseNicknamesDesc),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CourseNicknamesPage())),
          ),
          _SectionHeader(l10n.sectionTimetable),
          ListTile(
            leading: const Icon(Icons.calendar_view_week_outlined),
            title: Text(l10n.timetableSettings),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const TimetableSettingsPage())),
          ),
          _SectionHeader(l10n.sectionAccount),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(auth.value == true ? l10n.loggedInAs : l10n.notLoggedIn),
            trailing: auth.value == true
                ? TextButton(
                    onPressed: () => _confirmLogout(context, ref, l10n),
                    child: Text(l10n.logout),
                  )
                : TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const LoginWebViewPage())),
                    child: Text(l10n.loginButton),
                  ),
          ),
          _SectionHeader(l10n.sectionAbout),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l10n.contact),
            onTap: () => launchUrl(Uri.parse(KlmsConstants.contactUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.licenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'KLMS App',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _pickTheme(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final current = ref.read(settingsProvider).themeMode;
    final result = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.themeMode),
        children: [
          for (final (mode, label) in [
            (ThemeMode.system, l10n.themeSystem),
            (ThemeMode.light, l10n.themeLight),
            (ThemeMode.dark, l10n.themeDark),
          ])
            RadioListTile<ThemeMode>(
              value: mode,
              groupValue: current,
              title: Text(label),
              onChanged: (v) => Navigator.of(context).pop(v),
            ),
        ],
      ),
    );
    if (result != null) {
      ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(themeMode: result));
    }
  }

  Future<void> _pickLanguage(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final current = ref.read(settingsProvider).localeCode;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          for (final (code, label) in [
            ('system', l10n.languageSystem),
            ('ja', '日本語'),
            ('en', 'English'),
            ('fr', 'Français'),
          ])
            RadioListTile<String>(
              value: code,
              groupValue: current ?? 'system',
              title: Text(label),
              onChanged: (v) => Navigator.of(context).pop(v),
            ),
        ],
      ),
    );
    if (result != null) {
      ref.read(settingsProvider.notifier).update((s) => result == 'system'
          ? s.copyWith(clearLocale: true)
          : s.copyWith(localeCode: result));
    }
  }

  Future<void> _pickReminderOffset(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final settings = ref.read(settingsProvider);
    var hours = settings.reminderHours;
    var minutes = settings.reminderMinutes;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.reminderTiming),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: hours,
                items: [
                  for (var h = 0; h <= 72; h++)
                    DropdownMenuItem(value: h, child: Text('$h'))
                ],
                onChanged: (v) => setState(() => hours = v ?? hours),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(l10n.hoursUnit),
              ),
              DropdownButton<int>(
                value: minutes,
                items: [
                  for (var m = 0; m < 60; m += 5)
                    DropdownMenuItem(value: m, child: Text('$m'))
                ],
                onChanged: (v) => setState(() => minutes = v ?? minutes),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(l10n.minutesBeforeUnit),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel)),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.save)),
          ],
        ),
      ),
    );
    if (ok == true) {
      ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(reminderHours: hours, reminderMinutes: minutes));
    }
  }

  Future<void> _editExcludeWords(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final words = ref.read(settingsProvider).excludeWords;
          void save(List<String> updated) {
            ref
                .read(settingsProvider.notifier)
                .update((s) => s.copyWith(excludeWords: updated));
            setState(() {});
          }

          void addPendingWord() {
            final w = controller.text.trim();
            final current = ref.read(settingsProvider).excludeWords;
            if (w.isNotEmpty && !current.contains(w)) {
              save([...current, w]);
              controller.clear();
            }
          }

          return AlertDialog(
            title: Text(l10n.excludeWords),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final w in words)
                        InputChip(
                          label: Text(w),
                          onDeleted: () =>
                              save([...words]..remove(w)),
                        ),
                    ],
                  ),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: l10n.addWord,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: addPendingWord,
                      ),
                    ),
                    onSubmitted: (_) => addPendingWord(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    // Closing also commits any text still in the field, so
                    // forgetting to tap "+" doesn't lose the word.
                    addPendingWord();
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.close)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.logout)),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authServiceProvider).logout();
      ref.read(dbVersionProvider.notifier).state++;
    }
  }

  /// Signs in once; both syncs then reuse the same account.
  Future<GoogleSignInAccount?> _ensureGoogleAccount(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final service = ref.read(googleCalendarServiceProvider);
    final existing = await service.currentOrSilent;
    final account = existing ?? await service.connect();
    if (account == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.googleCalendarConnectFailed)));
      }
      return null;
    }
    if (mounted) setState(() => _googleEmail = account.email);
    return account;
  }

  Future<void> _connectGoogle(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final account = await _ensureGoogleAccount(context, ref, l10n);
    if (account != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.googleCalendarConnected(account.email))));
    }
  }

  /// Disconnects the account and removes everything the app created on the
  /// Google side (its calendar and its task list), then turns both syncs off.
  Future<void> _disconnectGoogle(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.googleDisconnectConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.ok)),
        ],
      ),
    );
    if (ok != true) return;
    final service = ref.read(googleCalendarServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    await service.deleteAll(prefs);
    await service.deleteAllTasks(prefs);
    await service.disconnect();
    if (mounted) setState(() => _googleEmail = null);
    ref.read(settingsProvider.notifier).update((s) =>
        s.copyWith(googleCalendarSync: false, googleTasksSync: false));
  }

  Future<void> _toggleGoogleCalendarSync(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, bool enable) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (!enable) {
      // Turning the sync off must also take the events with it, otherwise the
      // calendar keeps deadlines the app no longer maintains.
      await ref
          .read(googleCalendarServiceProvider)
          .deleteAll(ref.read(sharedPreferencesProvider));
      notifier.update((s) => s.copyWith(googleCalendarSync: false));
      return;
    }
    final account = await _ensureGoogleAccount(context, ref, l10n);
    if (account == null) return;
    notifier.update((s) => s.copyWith(googleCalendarSync: true));
    ref.read(syncControllerProvider.notifier).syncNow();
  }

  Future<void> _toggleGoogleTasksSync(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, bool enable) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (!enable) {
      await ref
          .read(googleCalendarServiceProvider)
          .deleteAllTasks(ref.read(sharedPreferencesProvider));
      notifier.update((s) => s.copyWith(googleTasksSync: false));
      return;
    }
    final account = await _ensureGoogleAccount(context, ref, l10n);
    if (account == null) return;
    notifier.update((s) => s.copyWith(googleTasksSync: true));
    ref.read(syncControllerProvider.notifier).syncNow();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
