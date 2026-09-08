import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Farbschema — enthält alle Farben die pro Theme variieren.
class Palette {
  final String id;
  final String name;

  final Color cream;
  final Color ink;
  final Color coral;
  final Color coralDeep;
  final Color amber;
  final Color teal;
  final Color purple;
  final Color bronze;
  final Color white;

  final Color textMuted;
  final Color textFaint;
  final Color textDark;
  final Color textOnDark;

  final Color chipCool1;
  final Color chipCool2;
  final Color chipCool3;

  final Color shadowWarm;
  final Color dashedDivider;

  const Palette({
    required this.id,
    required this.name,
    required this.cream,
    required this.ink,
    required this.coral,
    required this.coralDeep,
    required this.amber,
    required this.teal,
    required this.purple,
    required this.bronze,
    required this.white,
    required this.textMuted,
    required this.textFaint,
    required this.textDark,
    required this.textOnDark,
    required this.chipCool1,
    required this.chipCool2,
    required this.chipCool3,
    required this.shadowWarm,
    required this.dashedDivider,
  });
}

/// Original Theme — cream/coral/amber. Standard.
const paletteClassic = Palette(
  id: 'classic',
  name: 'Classic Coral',
  cream: Color(0xFFFBF4EA),
  ink: Color(0xFF211A12),
  coral: Color(0xFFFF5A3C),
  coralDeep: Color(0xFFFF3B21),
  amber: Color(0xFFFFB020),
  teal: Color(0xFF2E7D6B),
  purple: Color(0xFF7A5CC4),
  bronze: Color(0xFFC98A2E),
  white: Color(0xFFFFFFFF),
  textMuted: Color(0xFF6A5E4E),
  textFaint: Color(0xFF9A8E7C),
  textDark: Color(0xFF4A4034),
  textOnDark: Color(0xFFFBF4EA),
  chipCool1: Color(0xFFFFF0DA),
  chipCool2: Color(0xFFFFE2D6),
  chipCool3: Color(0xFFFFF3D2),
  shadowWarm: Color(0xFFE5B270),
  dashedDivider: Color(0xFFEDE0C8),
);

/// Cool ocean tones.
const paletteOcean = Palette(
  id: 'ocean',
  name: 'Deep Ocean',
  cream: Color(0xFFEAF3F5),
  ink: Color(0xFF10222E),
  coral: Color(0xFF00A6A6),
  coralDeep: Color(0xFF008C8C),
  amber: Color(0xFF2E7D6B),
  teal: Color(0xFF00A6A6),
  purple: Color(0xFF3B4DA6),
  bronze: Color(0xFF467C89),
  white: Color(0xFFFFFFFF),
  textMuted: Color(0xFF4B6570),
  textFaint: Color(0xFF7E9199),
  textDark: Color(0xFF2A3D48),
  textOnDark: Color(0xFFEAF3F5),
  chipCool1: Color(0xFFD9EBEE),
  chipCool2: Color(0xFFC5DEE4),
  chipCool3: Color(0xFFE0EDF0),
  shadowWarm: Color(0xFF6BAAB5),
  dashedDivider: Color(0xFFC5D8DE),
);

/// Forest — greens & earth tones.
const paletteForest = Palette(
  id: 'forest',
  name: 'Deep Forest',
  cream: Color(0xFFF1EDE1),
  ink: Color(0xFF1E2A1B),
  coral: Color(0xFF7C9A3F),
  coralDeep: Color(0xFF5F7A2C),
  amber: Color(0xFFD4A24C),
  teal: Color(0xFF3E7A5A),
  purple: Color(0xFF6E5A8C),
  bronze: Color(0xFFA57340),
  white: Color(0xFFFFFFFF),
  textMuted: Color(0xFF5A6151),
  textFaint: Color(0xFF8B9282),
  textDark: Color(0xFF3B4235),
  textOnDark: Color(0xFFF1EDE1),
  chipCool1: Color(0xFFE6EAD3),
  chipCool2: Color(0xFFD9E0BF),
  chipCool3: Color(0xFFECEEDC),
  shadowWarm: Color(0xFFB0B77A),
  dashedDivider: Color(0xFFD8DCC0),
);

/// Sunset — warm pinks and violets.
const paletteSunset = Palette(
  id: 'sunset',
  name: 'Sunset Blush',
  cream: Color(0xFFFBEDEA),
  ink: Color(0xFF2A1626),
  coral: Color(0xFFE95E80),
  coralDeep: Color(0xFFD13F65),
  amber: Color(0xFFFFA45C),
  teal: Color(0xFF9459C4),
  purple: Color(0xFF9459C4),
  bronze: Color(0xFFC46F4A),
  white: Color(0xFFFFFFFF),
  textMuted: Color(0xFF745265),
  textFaint: Color(0xFFA88794),
  textDark: Color(0xFF4E2E44),
  textOnDark: Color(0xFFFBEDEA),
  chipCool1: Color(0xFFFDE0DA),
  chipCool2: Color(0xFFF8CFCF),
  chipCool3: Color(0xFFFDE7DE),
  shadowWarm: Color(0xFFF0A5B4),
  dashedDivider: Color(0xFFEDD3D2),
);

/// Midnight — dark & bold, high-contrast electric accent.
const paletteMidnight = Palette(
  id: 'midnight',
  name: 'Midnight Neon',
  cream: Color(0xFF191927),
  ink: Color(0xFFF5F3EE),
  coral: Color(0xFF00E5A0),
  coralDeep: Color(0xFF00C289),
  amber: Color(0xFFFFD84C),
  teal: Color(0xFF3AB4FF),
  purple: Color(0xFFB980FF),
  bronze: Color(0xFFFFB84C),
  white: Color(0xFF222236),
  textMuted: Color(0xFFB4B0C6),
  textFaint: Color(0xFF7E7B94),
  textDark: Color(0xFFDCD8E4),
  textOnDark: Color(0xFF191927),
  chipCool1: Color(0xFF272740),
  chipCool2: Color(0xFF2E2E4C),
  chipCool3: Color(0xFF303048),
  shadowWarm: Color(0xFF5A5A80),
  dashedDivider: Color(0xFF3A3A54),
);

/// Rose — magenta/pink accents on soft blush.
const paletteRose = Palette(
  id: 'rose',
  name: 'Rose Blush',
  cream: Color(0xFFFCEEF3),
  ink: Color(0xFF2D111F),
  coral: Color(0xFFE8388D),
  coralDeep: Color(0xFFC7226F),
  amber: Color(0xFFF8B84E),
  teal: Color(0xFF5FA3A0),
  purple: Color(0xFFA46BC8),
  bronze: Color(0xFFC48070),
  white: Color(0xFFFFFFFF),
  textMuted: Color(0xFF7C4F62),
  textFaint: Color(0xFFB08A99),
  textDark: Color(0xFF522638),
  textOnDark: Color(0xFFFCEEF3),
  chipCool1: Color(0xFFFDDDE7),
  chipCool2: Color(0xFFF8C6D5),
  chipCool3: Color(0xFFFDE1EC),
  shadowWarm: Color(0xFFF0A5C0),
  dashedDivider: Color(0xFFEBCDD6),
);

/// Vintage — warm 70s browns, mustard & olive.
const paletteVintage = Palette(
  id: 'vintage',
  name: 'Vintage 70s',
  cream: Color(0xFFF3EAD3),
  ink: Color(0xFF2B1E10),
  coral: Color(0xFFC0562A),
  coralDeep: Color(0xFF9E3F17),
  amber: Color(0xFFDDA300),
  teal: Color(0xFF6B7F3A),
  purple: Color(0xFF8A5A3C),
  bronze: Color(0xFFA57340),
  white: Color(0xFFFDF6E4),
  textMuted: Color(0xFF6B5636),
  textFaint: Color(0xFF9C8963),
  textDark: Color(0xFF4A3820),
  textOnDark: Color(0xFFF3EAD3),
  chipCool1: Color(0xFFEDDDB5),
  chipCool2: Color(0xFFE0CC96),
  chipCool3: Color(0xFFF0E4C4),
  shadowWarm: Color(0xFFC9A868),
  dashedDivider: Color(0xFFD9C69F),
);

/// Slate Mono — minimalist grayscale on cream.
const paletteSlate = Palette(
  id: 'slate',
  name: 'Slate Mono',
  cream: Color(0xFFF3F1EE),
  ink: Color(0xFF161616),
  coral: Color(0xFF3E3E3E),
  coralDeep: Color(0xFF262626),
  amber: Color(0xFF8A8A8A),
  teal: Color(0xFF5A5A5A),
  purple: Color(0xFF4A4A4A),
  bronze: Color(0xFF6E6E6E),
  white: Color(0xFFFFFFFF),
  textMuted: Color(0xFF666666),
  textFaint: Color(0xFF9E9E9E),
  textDark: Color(0xFF2A2A2A),
  textOnDark: Color(0xFFF3F1EE),
  chipCool1: Color(0xFFE4E1DC),
  chipCool2: Color(0xFFD6D2CC),
  chipCool3: Color(0xFFEAE7E2),
  shadowWarm: Color(0xFFB0ADA7),
  dashedDivider: Color(0xFFD0CDC7),
);

/// Cyber — electric purples and cyans on dark navy.
const paletteCyber = Palette(
  id: 'cyber',
  name: 'Cyber Punk',
  cream: Color(0xFF0F0F1E),
  ink: Color(0xFFEDEDFF),
  coral: Color(0xFFFF3DBD),
  coralDeep: Color(0xFFDB1F9E),
  amber: Color(0xFF00F0FF),
  teal: Color(0xFF00C8FF),
  purple: Color(0xFF9D4EDD),
  bronze: Color(0xFFFF9F5A),
  white: Color(0xFF1A1A2E),
  textMuted: Color(0xFFB6B4D4),
  textFaint: Color(0xFF7A7896),
  textDark: Color(0xFFD8D6F2),
  textOnDark: Color(0xFF0F0F1E),
  chipCool1: Color(0xFF20203A),
  chipCool2: Color(0xFF262646),
  chipCool3: Color(0xFF2A2A4A),
  shadowWarm: Color(0xFF5A4E80),
  dashedDivider: Color(0xFF35354E),
);

/// True Dark — reines Dark Mode, nur Schwarz & Grautöne.
const paletteTrueDark = Palette(
  id: 'true_dark',
  name: 'True Dark',
  cream: Color(0xFF111111),
  ink: Color(0xFFF2F2F2),
  coral: Color(0xFFBDBDBD),
  coralDeep: Color(0xFF9E9E9E),
  amber: Color(0xFFD4D4D4),
  teal: Color(0xFF888888),
  purple: Color(0xFFA0A0A0),
  bronze: Color(0xFF7A7A7A),
  white: Color(0xFF1C1C1C),
  textMuted: Color(0xFFB0B0B0),
  textFaint: Color(0xFF808080),
  textDark: Color(0xFFE4E4E4),
  textOnDark: Color(0xFF111111),
  chipCool1: Color(0xFF232323),
  chipCool2: Color(0xFF2A2A2A),
  chipCool3: Color(0xFF2E2E2E),
  shadowWarm: Color(0xFF4A4A4A),
  dashedDivider: Color(0xFF3A3A3A),
);

const allPalettes = <Palette>[
  paletteClassic,
  paletteOcean,
  paletteForest,
  paletteSunset,
  paletteRose,
  paletteVintage,
  paletteSlate,
  paletteMidnight,
  paletteCyber,
  paletteTrueDark,
];

class ThemeStore extends ChangeNotifier {
  static const _key = 'palette_id_v1';

  static ThemeStore? _instance;
  static ThemeStore get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('ThemeStore.init() must be awaited before use.');
    }
    return i;
  }

  static Future<ThemeStore> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_key) ?? paletteClassic.id;
    final palette = allPalettes.firstWhere(
      (p) => p.id == id,
      orElse: () => paletteClassic,
    );
    return _instance = ThemeStore._(prefs, palette);
  }

  final SharedPreferences _prefs;
  Palette _current;
  ThemeStore._(this._prefs, this._current);

  Palette get current => _current;

  Future<void> setPalette(Palette p) async {
    if (p.id == _current.id) return;
    _current = p;
    await _prefs.setString(_key, p.id);
    notifyListeners();
  }

  // Helper — not strictly used but handy for debugging.
  String get debugJson => jsonEncode({'id': _current.id});
}
