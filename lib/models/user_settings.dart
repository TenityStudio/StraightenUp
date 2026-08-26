import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { none, solo, group }

class UserSettings {
  static const _kMode = 'app_mode';
  static const _kOnboarded = 'onboarded';
  static const _kStart = 'window_start_hour';
  static const _kEnd = 'window_end_hour';
  static const _kPerDay = 'per_day';
  static const _kStreak = 'streak';
  static const _kLastReactionDay = 'last_reaction_day';
  static const _kTotalPrompts = 'total_prompts';
  static const _kTotalReactions = 'total_reactions';

  final SharedPreferences _prefs;
  UserSettings(this._prefs);

  static Future<UserSettings> load() async =>
      UserSettings(await SharedPreferences.getInstance());

  AppMode get mode => AppMode.values[_prefs.getInt(_kMode) ?? 0];
  Future<void> setMode(AppMode m) => _prefs.setInt(_kMode, m.index);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool v) => _prefs.setBool(_kOnboarded, v);

  int get windowStartHour => _prefs.getInt(_kStart) ?? 9;
  int get windowEndHour => _prefs.getInt(_kEnd) ?? 21;
  int get perDay => _prefs.getInt(_kPerDay) ?? 3;
  Future<void> setSchedule({int? start, int? end, int? perDay}) async {
    if (start != null) await _prefs.setInt(_kStart, start);
    if (end != null) await _prefs.setInt(_kEnd, end);
    if (perDay != null) await _prefs.setInt(_kPerDay, perDay);
  }

  int get streak => _prefs.getInt(_kStreak) ?? 0;
  int get totalPrompts => _prefs.getInt(_kTotalPrompts) ?? 0;
  int get totalReactions => _prefs.getInt(_kTotalReactions) ?? 0;
  String? get lastReactionDay => _prefs.getString(_kLastReactionDay);

  Future<void> recordPromptShown() =>
      _prefs.setInt(_kTotalPrompts, totalPrompts + 1);

  Future<void> recordReaction() async {
    await _prefs.setInt(_kTotalReactions, totalReactions + 1);
    final today = _dayKey(DateTime.now());
    final last = lastReactionDay;
    int newStreak = streak;
    if (last == null) {
      newStreak = 1;
    } else if (last == today) {
      // schon heute gezählt
    } else {
      final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
      newStreak = last == yesterday ? streak + 1 : 1;
    }
    await _prefs.setString(_kLastReactionDay, today);
    await _prefs.setInt(_kStreak, newStreak);
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
