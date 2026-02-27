import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_extensions.dart';

class AppThemes {
  // Define monochrome color schemes
  static final ColorScheme _monochromeLight = ColorScheme.fromSeed(
    seedColor: Colors.black,
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.white,
    primaryContainer: Colors.white,
    onPrimaryContainer: Colors.black,
    secondary: Colors.grey.shade800,
    onSecondary: Colors.white,
    secondaryContainer: Colors.grey.shade200,
    onSecondaryContainer: Colors.black,
    tertiary: Colors.grey.shade600,
    onTertiary: Colors.white,
    tertiaryContainer: Colors.grey.shade100,
    onTertiaryContainer: Colors.black,
    error: Colors.black,
    onError: Colors.white,
    errorContainer: Colors.grey.shade300,
    onErrorContainer: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
    onSurfaceVariant: Colors.grey.shade800,
    outline: Colors.grey.shade600,
    outlineVariant: Colors.grey.shade400,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Colors.black,
    onInverseSurface: Colors.white,
    inversePrimary: Colors.white,
    surfaceTint: Colors.black,
  );

  static final ColorScheme _monochromeDark = ColorScheme.fromSeed(
    seedColor: Colors.white,
    brightness: Brightness.dark,
    primary: Colors.white,
    onPrimary: Colors.black,
    primaryContainer: Colors.black,
    onPrimaryContainer: Colors.white,
    secondary: Colors.grey.shade200,
    onSecondary: Colors.black,
    secondaryContainer: Colors.grey.shade800,
    onSecondaryContainer: Colors.white,
    tertiary: Colors.grey.shade400,
    onTertiary: Colors.black,
    tertiaryContainer: Colors.grey.shade900,
    onTertiaryContainer: Colors.white,
    error: Colors.white,
    onError: Colors.black,
    errorContainer: Colors.grey.shade700,
    onErrorContainer: Colors.white,
    surface: Colors.black,
    onSurface: Colors.white,
    onSurfaceVariant: Colors.grey.shade200,
    outline: Colors.grey.shade400,
    outlineVariant: Colors.grey.shade600,
    shadow: Colors.white,
    scrim: Colors.white,
    inverseSurface: Colors.white,
    onInverseSurface: Colors.black,
    inversePrimary: Colors.black,
    surfaceTint: Colors.white,
  );

  // Normal (fallback) color schemes
  static final ColorScheme _fallbackLight = ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.light,
  );

  static final ColorScheme _fallbackDark = ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.dark,
  );

  // Get the appropriate color scheme based on settings
  static ColorScheme getColorScheme({
    required bool isMonochrome,
    required bool isDark,
    ColorScheme? dynamicLight,
    ColorScheme? dynamicDark,
  }) {
    if (isMonochrome) {
      return isDark ? _monochromeDark : _monochromeLight;
    }

    // Use dynamic color if available, otherwise use fallback
    return isDark
        ? (dynamicDark ?? _fallbackDark)
        : (dynamicLight ?? _fallbackLight);
  }

  // Create a complete theme data from color scheme
  static ThemeData createThemeData({
    required ColorScheme colorScheme,
    required bool isDark,
    required bool isMonochrome,
  }) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    // Helper to gently soften a surface color toward white (light) or black (dark)
    Color softenSurface(Color c, {double strength = 0.06}) {
      return Color.lerp(c, isDark ? Colors.black : Colors.white, strength)!;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      // Reduce overall background intensity a touch for readability (non-monochrome only)
      scaffoldBackgroundColor: isMonochrome
          ? null
          : softenSurface(colorScheme.surface, strength: 0.06),
      canvasColor: isMonochrome
          ? null
          : softenSurface(colorScheme.surface, strength: 0.06),
      extensions: <ThemeExtension<dynamic>>[
        CricketThemeSettings(isMonochrome: isMonochrome),
      ],

      // Enhanced text theme with Google Fonts
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        headlineSmall: GoogleFonts.montserrat(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        elevation: isMonochrome ? 2 : 0,
        shadowColor: isMonochrome ? colorScheme.shadow : null,
      ),

      // Enhanced button themes for monochrome
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          elevation: isMonochrome ? 4 : 2,
          shadowColor: isMonochrome ? colorScheme.shadow : null,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Card theme for better monochrome appearance
      cardTheme: CardThemeData(
        // Match the softened background so cards blend more subtly (non-monochrome)
        color: isMonochrome
            ? colorScheme.surface
            : softenSurface(colorScheme.surface, strength: 0.04),
        // Remove strong Material 3 surface tint only for non-monochrome
        surfaceTintColor: isMonochrome ? null : Colors.transparent,
        shadowColor: isMonochrome ? colorScheme.shadow : null,
        elevation: isMonochrome ? 4 : 1,
        margin: const EdgeInsets.all(4),
      ),

      // Bottom navigation theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        elevation: isMonochrome ? 8 : 2,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Icon themes
      iconTheme: IconThemeData(color: colorScheme.onSurface),

      primaryIconTheme: IconThemeData(color: colorScheme.onPrimary),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: isMonochrome ? 8 : 6,
      ),

      // Input decoration for forms
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: isMonochrome ? 2 : 1,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: isMonochrome
            ? colorScheme.surface
            : softenSurface(colorScheme.surface, strength: 0.04),
        surfaceTintColor: isMonochrome ? null : Colors.transparent,
        shadowColor: isMonochrome ? colorScheme.shadow : null,
        elevation: isMonochrome ? 8 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Switch theme for settings
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return colorScheme.surfaceVariant;
        }),
      ),
    );
  }

  // Theme mode descriptions for UI
  static String getThemeModeDescription(
    ThemeMode themeMode,
    bool isMonochrome,
  ) {
    if (isMonochrome) {
      return 'Monochrome';
    }

    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  // Animation duration for theme transitions
  static const Duration transitionDuration = Duration(milliseconds: 300);
}
