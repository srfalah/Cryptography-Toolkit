import 'package:flutter/material.dart';

/// Global notifier controlling Light vs Dark mode across the entire application.
final ValueNotifier<ThemeMode> appThemeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

void toggleAppTheme() {
  appThemeNotifier.value = appThemeNotifier.value == ThemeMode.light
      ? ThemeMode.dark
      : ThemeMode.light;
}

class AppTheme {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ===========================================================================
  // CORE SURFACE & TEXT PALETTE
  // ===========================================================================

  static Color scaffoldBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);

  static Color scaffoldBgAlt(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);

  static Color cardBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : Colors.white;

  static Color surfaceSubtle(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  static Color pillBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

  static Color borderSubtle(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : Colors.grey.shade200;

  static Color borderMedium(BuildContext context) =>
      isDark(context) ? const Color(0xFF475569) : Colors.grey.shade300;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF64748B) : Colors.grey.shade500;

  // ===========================================================================
  // CATEGORY SIGNATURE COLORS (ADAPTIVE FOR HIGH CONTRAST IN DARK MODE)
  // ===========================================================================

  /// Asymmetric & Brand Primary (Navy in Light -> Electric Blue in Dark)
  static Color navyAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);

  static Color navyAppBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF172554) : const Color(0xFF1E3A8A);

  /// Extended Euclidean (Teal-700 in Light -> Vibrant Teal-400 in Dark)
  static Color tealAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFF2DD4BF) : Colors.teal.shade700;

  static Color tealAppBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF115E59) : Colors.teal.shade700;

  /// Modular Exponentiation (Orange-800 in Light -> Luminous Orange-400 in Dark)
  static Color orangeAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFFFB923C) : Colors.orange.shade800;

  static Color orangeAppBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF9A3412) : Colors.orange.shade800;

  /// Substitution Ciphers (DeepPurple-600 in Light -> Soft Neon Violet in Dark)
  static Color purpleAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFFA78BFA) : Colors.deepPurple.shade600;

  static Color purpleAppBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF4C1D95) : Colors.deepPurple.shade600;

  /// Transposition Ciphers (BlueGrey-800 in Light -> Cyber Sky-Cyan in Dark)
  static Color transpositionAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFF38BDF8) : Colors.blueGrey.shade800;

  static Color transpositionAppBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : Colors.blueGrey.shade800;

  /// Diffie-Hellman Participant Colors
  static Color aliceColor(BuildContext context) =>
      isDark(context) ? const Color(0xFFF472B6) : Colors.pink.shade700;

  static Color bobColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF38BDF8) : Colors.blue.shade800;

  // ===========================================================================
  // STATUS / ALERT BANNERS (AMBER WARNING, GREEN SUCCESS, RED ERROR)
  // ===========================================================================

  static Color warningBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF451A03) : Colors.amber.shade50;

  static Color warningBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFFD97706) : Colors.amber.shade300;

  static Color warningText(BuildContext context) =>
      isDark(context) ? const Color(0xFFFDE68A) : Colors.amber.shade900;

  static Color successBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF064E3B) : Colors.green.shade50;

  static Color successBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF10B981) : Colors.green.shade400;

  static Color successText(BuildContext context) =>
      isDark(context) ? const Color(0xFFA7F3D0) : Colors.green.shade900;

  static Color errorBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);

  static Color errorBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFFEF4444) : Colors.red.shade200;

  static Color errorText(BuildContext context) =>
      isDark(context) ? const Color(0xFFFCA5A5) : Colors.red.shade700;

  // ===========================================================================
  // THEME DATA DEFINITIONS
  // ===========================================================================

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1E3A8A),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'Roboto',
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade200,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF1E3A8A),
        secondary: Colors.orange.shade800,
        surface: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.blueGrey.shade700),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF60A5FA),
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      fontFamily: 'Roboto',
      cardColor: const Color(0xFF1E293B),
      dividerColor: const Color(0xFF334155),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF60A5FA),
        secondary: Color(0xFFFB923C),
        surface: Color(0xFF1E293B),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        hintStyle: const TextStyle(color: Color(0xFF475569)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
    );
  }
}
