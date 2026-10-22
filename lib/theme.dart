import 'package:flutter/material.dart';

/// NöroCep renkleri: bordo ana renk, krem zemin, sıcak kahve ve bakır
/// yardımcı tonlar.
abstract final class NoroColors {
  static const bordo = Color(0xFF8B2635);
  static const cream = Color(0xFFFFF8F2);
  static const darkSurface = Color(0xFF1C1415);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  var scheme = ColorScheme.fromSeed(
    seedColor: NoroColors.bordo,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  if (!dark) {
    scheme = scheme.copyWith(
      primary: NoroColors.bordo,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFF6DADB),
      onPrimaryContainer: const Color(0xFF3B0A12),
      secondary: const Color(0xFF7A5545),
      secondaryContainer: const Color(0xFFF3E3D6),
      onSecondaryContainer: const Color(0xFF3E2419),
      tertiary: const Color(0xFFA0612A),
      surface: NoroColors.cream,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFBF1EA),
      surfaceContainer: const Color(0xFFF6EAE2),
      surfaceContainerHigh: const Color(0xFFF1E3DA),
      surfaceContainerHighest: const Color(0xFFEBDCD2),
    );
  } else {
    scheme = scheme.copyWith(
      primary: const Color(0xFFF2B4BC),
      onPrimary: const Color(0xFF4A0E1A),
      primaryContainer: const Color(0xFF6E1A2A),
      onPrimaryContainer: const Color(0xFFFFDADF),
      secondaryContainer: const Color(0xFF4A3329),
      onSecondaryContainer: const Color(0xFFF6E0D3),
      surface: NoroColors.darkSurface,
    );
  }

  final radius = BorderRadius.circular(16);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 2,
      titleTextStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      indicatorColor: scheme.primary,
      labelColor: scheme.primary,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}
