import 'package:flutter/material.dart';

abstract final class SegColors {
  static const canvas = Color(0xFFFFFEFC), surface = Colors.white;
  static const surfaceMuted = Color(0xFFF1F8FC), line = Color(0xFFDCEAF2);
  static const ink = Color(0xFF18334B),
      inkSoft = Color(0xFF526E83),
      inkFaint = Color(0xFF8CA4B4);
  static const primary = Color(0xFF1687D9),
      primaryDeep = Color(0xFF0868AF),
      primarySoft = Color(0xFFE5F4FF);
  static const accent = Color(0xFFFF8A32), accentDeep = Color(0xFFBA4C08);

  /// End of the primary button gradient; white text sits on it.
  static const accentStrong = Color(0xFFEE6A1C);
  static const turquoise = Color(0xFF10B7B0),
      turquoiseDeep = Color(0xFF087B80),
      sky = Color(0xFF63C6F4);
  static const star = Color(0xFFFFC546), starDeep = Color(0xFFAC6B00);
  static const hintGlow = Color(0xFFFFEAAF), successGlow = Color(0xFFB7F1DB);
  static const familyCanvas = Color(0xFFF5FAFD);
}

abstract final class SegSpace {
  static const s1 = 4.0,
      s2 = 8.0,
      s3 = 12.0,
      s4 = 16.0,
      s5 = 24.0,
      s6 = 32.0,
      s7 = 48.0,
      s8 = 64.0;
}

abstract final class SegRadius {
  static const xs = 8.0,
      sm = 12.0,
      md = 20.0,
      lg = 28.0,
      xl = 36.0,
      pill = 999.0;
}

abstract final class SegMotion {
  static const breathe = Duration(milliseconds: 1000),
      nudge = Duration(milliseconds: 400),
      dismiss = Duration(milliseconds: 260);
  static const tap = Duration(milliseconds: 100),
      appear = Duration(milliseconds: 320),
      stagger = Duration(milliseconds: 150),
      fadeHint = Duration(milliseconds: 600),
      focus = Duration(milliseconds: 500),
      pageSlide = Duration(milliseconds: 300);
}

abstract final class SegText {
  static const display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static const title = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.27,
  );
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );
  static const item = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.27,
  );
  static const body = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44,
  );
  static const label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
  );
}

ThemeData segTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Nunito',
  scaffoldBackgroundColor: SegColors.canvas,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: SegColors.primary,
        surface: SegColors.surface,
        error: const Color(0xFFB3261E),
      ).copyWith(
        primary: SegColors.primary,
        onPrimary: SegColors.surface,
        secondary: SegColors.turquoiseDeep,
        primaryContainer: SegColors.primarySoft,
        onPrimaryContainer: SegColors.primaryDeep,
      ),
  textTheme: const TextTheme(
    bodyMedium: SegText.body,
    titleLarge: SegText.title,
    headlineLarge: SegText.display,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: SegColors.canvas,
    foregroundColor: SegColors.ink,
    surfaceTintColor: Colors.transparent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SegColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SegRadius.md),
      borderSide: const BorderSide(color: SegColors.line),
    ),
  ),
);
