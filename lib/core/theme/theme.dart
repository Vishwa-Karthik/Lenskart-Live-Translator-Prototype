import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildDarkHudTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  const colorScheme = ColorScheme.dark(
    primary: Color(0xFF0BD3BF),
    secondary: Color(0xFF58FCEC),
    surface: Color(0xFF0E1116),
    onSurface: Color(0xFFE6F2F1),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF0A0D12),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0A0D12).withOpacity(0.2),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF10151C).withOpacity(0.35),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.18)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            backgroundColor: const Color(0xFF141B23).withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: colorScheme.primary.withOpacity(0.25),
          ).merge(
            ButtonStyle(
              overlayColor: MaterialStateProperty.all(
                colorScheme.primary.withOpacity(0.12),
              ),
            ),
          ),
    ),
  );
}
