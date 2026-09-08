import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palettes.dart';

/// Farbaliase — greifen dynamisch auf das aktuell aktive Palette-Objekt zu.
/// Alte const-Nutzungen sind auf Getter umgestellt worden, damit ein Palette-
/// Wechsel zur Laufzeit sofort greift (via ThemeStore + AnimatedBuilder in main).
class AppColors {
  static Palette get _p => ThemeStore.instance.current;

  static Color get cream => _p.cream;
  static Color get ink => _p.ink;
  static Color get coral => _p.coral;
  static Color get coralDeep => _p.coralDeep;
  static Color get amber => _p.amber;
  static Color get teal => _p.teal;
  static Color get purple => _p.purple;
  static Color get bronze => _p.bronze;
  static Color get white => _p.white;

  static Color get textMuted => _p.textMuted;
  static Color get textFaint => _p.textFaint;
  static Color get textDark => _p.textDark;
  static Color get textOnDark => _p.textOnDark;

  static Color get chipCool1 => _p.chipCool1;
  static Color get chipCool2 => _p.chipCool2;
  static Color get chipCool3 => _p.chipCool3;

  static Color get shadowWarm => _p.shadowWarm;
  static Color get dashedDivider => _p.dashedDivider;
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.coral,
      secondary: AppColors.amber,
      surface: AppColors.white,
      onPrimary: AppColors.cream,
      onSurface: AppColors.ink,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.ink),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

TextStyle anton({
  double size = 34,
  Color? color,
  double height = 0.98,
  double letterSpacing = 0.4,
}) =>
    GoogleFonts.anton(
      fontSize: size,
      color: color ?? AppColors.ink,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle grotesk({
  double size = 15,
  FontWeight weight = FontWeight.w500,
  Color? color,
  double height = 1.35,
  double letterSpacing = 0,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.ink,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle kicker({
  Color? color,
  double letterSpacing = 3.5,
  double size = 12,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.bronze,
      letterSpacing: letterSpacing,
      height: 1,
    );
