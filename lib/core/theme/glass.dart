import 'dart:ui';

import 'package:flutter/material.dart';

/// A frosted "liquid glass" surface: translucent fill over a real backdrop
/// blur, a hairline highlight border, and a soft shadow. Used for elements
/// that float over content (the tab bar, the home hero card).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = (isDark ? const Color(0xFF1E243C) : Colors.white)
        .withValues(alpha: isDark ? 0.72 : 0.78);
    final border = (isDark ? const Color(0xFF96AAE6) : Colors.white)
        .withValues(alpha: isDark ? 0.16 : 0.7);
    final br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.10),
            blurRadius: isDark ? 30 : 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: br,
              border: Border.all(color: border, width: 1),
            ),
            child: _maybeInk(padding, br),
          ),
        ),
      ),
    );
  }

  Widget _maybeInk(EdgeInsetsGeometry padding, BorderRadius br) {
    final content = Padding(padding: padding, child: child);
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: br, onTap: onTap, child: content),
    );
  }
}

/// A solid, softly-shadowed grouped card (iOS "inset grouped" list feel).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final br = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.62 : 0.07),
            blurRadius: isDark ? 24 : 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A small uppercase-ish section label used above grouped cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: ink.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
