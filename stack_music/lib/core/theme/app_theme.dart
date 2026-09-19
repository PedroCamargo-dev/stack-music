import 'package:flutter/material.dart';

/// Design System do Stack Music (ver DESIGN.md na raiz do repo).
/// Dark-first, accent amarelo/dourado #FADC40, índigo reservado ao player.
class AppColors {
  static const darkBackground = Color(0xFF0E0F13);
  static const darkSurface = Color(0xFF1A1B21);
  static const darkSurface2 = Color(0xFF24262E);
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFEDEDEF);

  static const primary = Color(0xFFFADC40);
  static const primaryLight = Color(0xFFE8B923);
  static const secondaryAccent = Color(0xFF6A3FFB);
  static const secondaryAccentLight = Color(0xFF4B44E0);
  static const danger = Color(0xFFDA1A1C);

  static const darkTextPrimary = Color(0xFFF5F6FA);
  static const darkTextSecondary = Color(0xFF9AA0AE);
  static const lightTextPrimary = Color(0xFF101216);
  static const lightTextSecondary = Color(0xFF6F6F92);

  static const playerGradientStart = Color(0xFF151354);
  static const playerGradientEnd = Color(0xFF2C1656);

  // Dark
  static Color background(Brightness b) =>
      b == Brightness.dark ? darkBackground : lightBackground;
  static Color surface(Brightness b) =>
      b == Brightness.dark ? darkSurface : lightSurface;
  static Color surface2(Brightness b) =>
      b == Brightness.dark ? darkSurface2 : lightSurface2;
  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? darkTextSecondary : lightTextSecondary;
}

class AppTheme {
  static const _font = 'Inter';

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData light() => _base(Brightness.light);

  static ThemeData _base(Brightness b) {
    final bg = AppColors.background(b);
    final surface = AppColors.surface(b);
    final textP = AppColors.textPrimary(b);
    final textS = AppColors.textSecondary(b);
    final primary =
        b == Brightness.dark ? AppColors.primary : AppColors.primaryLight;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.secondaryAccent,
        brightness: b,
        primary: primary,
        surface: surface,
      ),
      fontFamily: _font,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textP,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textP,
        ),
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(
            fontFamily: _font, fontSize: 26, fontWeight: FontWeight.w700, color: textP),
        titleLarge: TextStyle(
            fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700, color: textP),
        titleMedium: TextStyle(
            fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600, color: textP),
        bodyMedium: TextStyle(fontFamily: _font, fontSize: 13, color: textS),
        bodySmall: TextStyle(
            fontFamily: _font, fontSize: 11, letterSpacing: 1.2, color: textS),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2(b),
        selectedColor: primary,
        labelStyle: TextStyle(fontFamily: _font, fontSize: 13, color: textP),
        shape: const StadiumBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textS,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: AppColors.surface2(b),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
      ),
    );
  }
}