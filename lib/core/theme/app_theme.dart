import 'package:flutter/material.dart';

/// App-wide theme derived from the brand color #021951, tuned for an
/// iOS-like, quiet look: solid navy-biased grounds, generous radii, restrained
/// accent use, and SF-style typography. Frosted "liquid glass" surfaces are
/// provided separately by widgets in `glass.dart`.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF021951);

  // Solid grounds (no gradients) and elevated card surfaces per brightness.
  static const Color _groundLight = Color(0xFFEAEEF6);
  static const Color _groundDark = Color(0xFF0A0E1C);
  static const Color _cardLight = Colors.white;
  static const Color _cardDark = Color(0xFF161C30);
  static const Color _inkLight = Color(0xFF12162A);
  static const Color _inkDark = Color(0xFFEEF1FB);

  /// Accent that reads on the current ground (the deep navy is illegible on a
  /// dark ground, so dark mode lifts it to a soft blue).
  static Color accent(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFAEC6FF) : seed;

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final ground = isDark ? _groundDark : _groundLight;
    final card = isDark ? _cardDark : _cardLight;
    final ink = isDark ? _inkDark : _inkLight;
    final acc = accent(brightness);

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(
      surface: card,
      onSurface: ink,
      primary: acc,
      onPrimary: isDark ? const Color(0xFF0A0F22) : Colors.white,
    );

    final baseText = isDark ? Typography.whiteCupertino : Typography.blackCupertino;
    final textTheme = baseText
        .apply(bodyColor: ink, displayColor: ink)
        .copyWith(
          headlineLarge: baseText.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: ink),
          titleLarge: baseText.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: ink),
          titleMedium: baseText.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.1, color: ink),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ground,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: ground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card.withValues(alpha: isDark ? 0.62 : 0.7),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: acc.withValues(alpha: isDark ? 0.28 : 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 66,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? acc : ink.withValues(alpha: 0.6),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
              color: selected ? acc : ink.withValues(alpha: 0.6));
        }),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: ink.withValues(alpha: 0.7),
      ),
      dividerTheme: DividerThemeData(
        color: ink.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
