import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Eight-theme system with per-theme light/dark variants.
///
/// Call [buildTheme] with user preferences from [SettingsService].
class AppTheme {
  AppTheme._();

  // ── Theme colour definitions ───────────────────────────────────────────

  static const Map<String, _ThemeColors> _themes = {
    'Legacy': _ThemeColors(
      lightScaffold: Color(0xFFF8F8F8),
      darkScaffold: Color(0xFF121212),
      lightCard: Color(0xFFF0F0F0),
      darkCard: Color(0xFF2A2A2A),
      lightDialog: Color(0xFFFFFFFF),
      darkDialog: Color(0xFF1E1E1E),
      seedColor: Color(0xFF00897B),
    ),
    'Material You': _ThemeColors(
      // Surfaces derived from accent via ColorScheme.fromSeed
      lightScaffold: null,
      darkScaffold: null,
      lightCard: null,
      darkCard: null,
      lightDialog: null,
      darkDialog: null,
      seedColor: Color(0xFF6750A4), // fallback; overridden by accent
    ),
    'Ocean Depths': _ThemeColors(
      lightScaffold: Color(0xFFF0F7FA),
      darkScaffold: Color(0xFF0A1929),
      lightCard: Color(0xFFE3EEF5),
      darkCard: Color(0xFF112840),
      lightDialog: Color(0xFFF5FAFD),
      darkDialog: Color(0xFF0F2234),
      seedColor: Color(0xFF1565C0),
    ),
    'Sunset Glow': _ThemeColors(
      lightScaffold: Color(0xFFFFF8F0),
      darkScaffold: Color(0xFF1A1210),
      lightCard: Color(0xFFFFEFDF),
      darkCard: Color(0xFF2A1E18),
      lightDialog: Color(0xFFFFFBF5),
      darkDialog: Color(0xFF231A14),
      seedColor: Color(0xFFE65100),
    ),
    'Nordic Frost': _ThemeColors(
      lightScaffold: Color(0xFFF5F8FA),
      darkScaffold: Color(0xFF101820),
      lightCard: Color(0xFFE8EDF2),
      darkCard: Color(0xFF1A2430),
      lightDialog: Color(0xFFF8FAFC),
      darkDialog: Color(0xFF151E28),
      seedColor: Color(0xFF546E7A),
    ),
    'Rose Garden': _ThemeColors(
      lightScaffold: Color(0xFFFDF2F5),
      darkScaffold: Color(0xFF1A1015),
      lightCard: Color(0xFFF8E5EC),
      darkCard: Color(0xFF2A1820),
      lightDialog: Color(0xFFFFF5F8),
      darkDialog: Color(0xFF21141A),
      seedColor: Color(0xFFAD1457),
    ),
    'Midnight Amethyst': _ThemeColors(
      lightScaffold: Color(0xFFF5F0FA),
      darkScaffold: Color(0xFF13101A),
      lightCard: Color(0xFFE8DEF5),
      darkCard: Color(0xFF1E1528),
      lightDialog: Color(0xFFF9F5FF),
      darkDialog: Color(0xFF1A1222),
      seedColor: Color(0xFF7B1FA2),
    ),
    'Forest Canopy': _ThemeColors(
      lightScaffold: Color(0xFFF0F8F0),
      darkScaffold: Color(0xFF0A150A),
      lightCard: Color(0xFFE0F0E0),
      darkCard: Color(0xFF152A15),
      lightDialog: Color(0xFFF5FBF5),
      darkDialog: Color(0xFF102010),
      seedColor: Color(0xFF2E7D32),
    ),
  };

  static Color getThemeSeedColor(String themeName) {
    return _themes[themeName]?.seedColor ?? _themes['Legacy']!.seedColor;
  }

  // ── Build ThemeData ────────────────────────────────────────────────────

  static ThemeData buildTheme({
    required String themeName,
    required Brightness brightness,
    required Color accentColor,
    required String fontFamily,
    required double fontSizeScale,
    ColorScheme? dynamicScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final colors = _themes[themeName] ?? _themes['Legacy']!;
    final isMaterialYou = themeName == 'Material You';

    // Check if accentColor is default M3 purple when on Material You
    final effectiveAccent = (isMaterialYou && dynamicScheme != null && accentColor.toARGB32() == 0xFF6750A4)
        ? dynamicScheme.primary
        : accentColor;

    // Color scheme — all themes use fromSeed with the user's accent
    ColorScheme colorScheme;
    if (isMaterialYou && dynamicScheme != null && accentColor.toARGB32() == 0xFF6750A4) {
      colorScheme = dynamicScheme.copyWith(
        primary: effectiveAccent,
        secondary: effectiveAccent,
      );
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: effectiveAccent,
        brightness: brightness,
      ).copyWith(
        primary: effectiveAccent,
        secondary: effectiveAccent,
      );
    }

    // Surfaces — Material You lets M3 decide, others use fixed colours
    final scaffoldBg = isMaterialYou
        ? colorScheme.surface
        : (isDark ? colors.darkScaffold! : colors.lightScaffold!);
    final cardBg = isMaterialYou
        ? colorScheme.surfaceContainerHigh
        : (isDark ? colors.darkCard! : colors.lightCard!);
    final dialogBg = isMaterialYou
        ? colorScheme.surfaceContainerHigh
        : (isDark ? colors.darkDialog! : colors.lightDialog!);

    // Typography
    TextTheme textTheme = _buildTextTheme(base.textTheme, fontFamily);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: effectiveAccent,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEEEEEE),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white : Colors.black87,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ── Font helper ────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(TextTheme base, String fontFamily) {
    switch (fontFamily) {
      case 'System':
        return base;
      case 'RobotoCondensed':
        return base.apply(fontFamily: 'RobotoCondensed');
      case 'Inter':
        return GoogleFonts.interTextTheme(base);
      case 'Poppins':
        return GoogleFonts.poppinsTextTheme(base);
      case 'Lato':
        return GoogleFonts.latoTextTheme(base);
      case 'Nunito':
        return GoogleFonts.nunitoTextTheme(base);
      case 'Source Sans 3':
        return GoogleFonts.sourceSans3TextTheme(base);
      default:
        return base.apply(fontFamily: 'RobotoCondensed');
    }
  }

  /// Returns the effective font family string for ad-hoc TextStyles.
  static String? getFontFamily(String fontSetting) {
    switch (fontSetting) {
      case 'System':
        return null;
      case 'RobotoCondensed':
        return 'RobotoCondensed';
      case 'Inter':
        return GoogleFonts.inter().fontFamily;
      case 'Poppins':
        return GoogleFonts.poppins().fontFamily;
      case 'Lato':
        return GoogleFonts.lato().fontFamily;
      case 'Nunito':
        return GoogleFonts.nunito().fontFamily;
      case 'Source Sans 3':
        return GoogleFonts.sourceSans3().fontFamily;
      default:
        return 'RobotoCondensed';
    }
  }
}

/// Internal colour set for a single theme.
class _ThemeColors {
  final Color? lightScaffold;
  final Color? darkScaffold;
  final Color? lightCard;
  final Color? darkCard;
  final Color? lightDialog;
  final Color? darkDialog;
  final Color seedColor;

  const _ThemeColors({
    required this.lightScaffold,
    required this.darkScaffold,
    required this.lightCard,
    required this.darkCard,
    required this.lightDialog,
    required this.darkDialog,
    required this.seedColor,
  });
}
