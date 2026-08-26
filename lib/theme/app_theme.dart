import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const cream = Color(0xFFFBF4EA);
  static const ink = Color(0xFF211A12);
  static const coral = Color(0xFFFF5A3C);
  static const coralDeep = Color(0xFFFF3B21);
  static const amber = Color(0xFFFFB020);
  static const teal = Color(0xFF2E7D6B);
  static const purple = Color(0xFF7A5CC4);
  static const bronze = Color(0xFFC98A2E);
  static const white = Color(0xFFFFFFFF);

  static const textMuted = Color(0xFF6A5E4E);
  static const textFaint = Color(0xFF9A8E7C);
  static const textDark = Color(0xFF4A4034);
  static const textOnDark = Color(0xFFFBF4EA);

  static const chipCool1 = Color(0xFFFFF0DA);
  static const chipCool2 = Color(0xFFFFE2D6);
  static const chipCool3 = Color(0xFFFFF3D2);

  static const shadowWarm = Color(0xFFE5B270);
  static const dashedDivider = Color(0xFFEDE0C8);
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
    appBarTheme: const AppBarTheme(
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
  Color color = AppColors.ink,
  double height = 0.98,
  double letterSpacing = 0.4,
}) =>
    GoogleFonts.anton(
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle grotesk({
  double size = 15,
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.ink,
  double height = 1.35,
  double letterSpacing = 0,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle kicker({
  Color color = AppColors.bronze,
  double letterSpacing = 3.5,
  double size = 12,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing,
      height: 1,
    );
