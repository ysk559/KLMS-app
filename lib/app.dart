import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'data/settings/settings_controller.dart';
import 'features/home/home_page.dart';
import 'features/pages/course_detail_page.dart';
import 'features/pages/courses_page.dart';
import 'features/settings/settings_page.dart';
import 'features/tasks/tasks_page.dart';
import 'features/timetable/timetable_page.dart';
import 'l10n/generated/app_localizations.dart';

class KlmsApp extends ConsumerWidget {
  const KlmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Keep intl (weekday/date names) in sync with the app language.
    Intl.defaultLocale =
        settings.localeCode ?? PlatformDispatcher.instance.locale.languageCode;
    return MaterialApp(
      title: 'KLMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.localeCode != null ? Locale(settings.localeCode!) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(notificationServiceProvider).requestPermissions();
      _listenWidgetClicks();
      // Refresh silently on launch when already signed in.
      final loggedIn = await ref.read(authServiceProvider).isLoggedIn();
      if (loggedIn && mounted) {
        ref.read(syncControllerProvider.notifier).syncNow();
      }
    });
  }

  /// Deep links from home-screen widgets (klmsapp://tasks | timetable |
  /// `course/<id>`).
  void _listenWidgetClicks() {
    try {
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
      _widgetClickSubscription =
          HomeWidget.widgetClicked.listen(_handleWidgetUri);
    } catch (_) {}
  }

  Future<void> _handleWidgetUri(Uri? uri) async {
    if (uri == null || !mounted) return;
    switch (uri.host) {
      case 'tasks':
        setState(() => _index = 1);
      case 'timetable':
        setState(() => _index = 3);
      case 'course':
        final id = uri.pathSegments.isNotEmpty
            ? int.tryParse(uri.pathSegments.first)
            : null;
        if (id == null) return;
        final course =
            await ref.read(courseRepositoryProvider).getById(id);
        if (course != null && mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CourseDetailPage(course: course)));
        }
    }
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A background sync may have updated the DB while we were away.
    if (state == AppLifecycleState.resumed) {
      ref.read(dbVersionProvider.notifier).state++;
      // Capture any rotated LMS cookies from in-app browsing so the persisted
      // copy (used by API calls and the background isolate) stays fresh.
      ref.read(authServiceProvider).saveSessionCookies();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomePage(),
          TasksPage(),
          CoursesPage(),
          TimetablePage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: l10n.tabTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.tabPages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_view_week_outlined),
            selectedIcon: const Icon(Icons.calendar_view_week),
            label: l10n.tabTimetable,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}
