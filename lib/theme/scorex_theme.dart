import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

/// A single visual language across scores, account screens and settings.
abstract final class ScoreXTheme {
  static const green = Color(0xFF0B3D2E);
  static const gold = Color(0xFFFFC857);
  static const mint = Color(0xFF63E6BE);

  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF081511) : const Color(0xFFF4F7F5);
    final surface = dark ? const Color(0xFF11251D) : Colors.white;
    final scheme = ColorScheme.fromSeed(seedColor: green, brightness: brightness).copyWith(
      primary: dark ? mint : green,
      onPrimary: dark ? const Color(0xFF05271B) : Colors.white,
      secondary: dark ? gold : const Color(0xFF735200),
      surface: surface,
      onSurface: dark ? const Color(0xFFE8F1EB) : const Color(0xFF172C23),
      onSurfaceVariant: dark ? const Color(0xFFA3BAAE) : const Color(0xFF52675C),
      outlineVariant: dark ? const Color(0xFF294236) : const Color(0xFFD8E4DC),
    );
    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.apply(fontFamily: 'Roboto').copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.4),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.6),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.4),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background, foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0,
        centerTitle: false, titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        color: surface, elevation: 0, margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.outlineVariant)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface, selectedColor: dark ? gold : green,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: const StadiumBorder(), side: BorderSide(color: scheme.outlineVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface, indicatorColor: dark ? gold.withValues(alpha: .17) : const Color(0xFFD8EEE0),
        elevation: 0, height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? (dark ? gold : green) : scheme.onSurfaceVariant,
          size: 25,
        )),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary, unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: dark ? gold : green, dividerColor: scheme.outlineVariant,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 24),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        titleTextStyle: base.textTheme.titleSmall?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
        subtitleTextStyle: base.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }

  static const scoreStyle = TextStyle(fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.w900, letterSpacing: -.8);
}
