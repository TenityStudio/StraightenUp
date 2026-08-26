import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DailyActivity {
  office,
  gaming,
  scrolling,
  studying,
  driving,
  crafting,
  outdoor,
  itsComplicated,
}

extension DailyActivityMeta on DailyActivity {
  String get label => switch (this) {
        DailyActivity.office => 'Office chair',
        DailyActivity.gaming => 'Gaming',
        DailyActivity.scrolling => 'Phone all day',
        DailyActivity.studying => 'Studying',
        DailyActivity.driving => 'Driving',
        DailyActivity.crafting => 'Handcraft',
        DailyActivity.outdoor => 'Outdoor',
        DailyActivity.itsComplicated => "It's complicated",
      };
  String get emoji => switch (this) {
        DailyActivity.office => '💼',
        DailyActivity.gaming => '🎮',
        DailyActivity.scrolling => '📱',
        DailyActivity.studying => '📚',
        DailyActivity.driving => '🚗',
        DailyActivity.crafting => '🔧',
        DailyActivity.outdoor => '🌲',
        DailyActivity.itsComplicated => '🤷',
      };
}

enum PainFrequency {
  never('Never', 'Neck of steel.'),
  sometimes('Sometimes', 'On heavy days.'),
  daily('Daily', "It's a routine now."),
  rightNow('As we speak', 'You should probably stretch.');

  final String label;
  final String hint;
  const PainFrequency(this.label, this.hint);
}

enum Goal {
  posture('Better posture', '🧍'),
  lessPain('Less pain', '🩹'),
  moveMore('Move more', '🤸'),
  accountability('Group pressure', '👥'),
  justFun('Just for fun', '🎉');

  final String label;
  final String emoji;
  const Goal(this.label, this.emoji);
}

/// Ein „Recommendation Bucket" — grober Übungs-Cluster, den wir aus den
/// Umfrage-Antworten ableiten. Später mapping auf konkrete Lottie-Übungen.
enum ExerciseBucket {
  chinTucks('Chin tucks', 'Reset the head over the shoulders.'),
  shoulderRolls('Shoulder rolls', 'Undo the hunch.'),
  deskStretch('Desk stretch', 'For chair prisoners.'),
  wallAngels('Wall angels', 'Realign the upper back.'),
  neckRotation('Slow neck rotation', 'Loosen a stuck neck.'),
  standAndBreathe('Stand & breathe', 'Reset. That’s it.');

  final String label;
  final String hint;
  const ExerciseBucket(this.label, this.hint);
}

class SurveyResult {
  final Set<DailyActivity> activities;
  final double neckSeverity; // 0.0 – 1.0
  final PainFrequency? painFrequency;
  final Set<Goal> goals;
  final DateTime? completedAt;

  const SurveyResult({
    this.activities = const {},
    this.neckSeverity = 0.3,
    this.painFrequency,
    this.goals = const {},
    this.completedAt,
  });

  SurveyResult copyWith({
    Set<DailyActivity>? activities,
    double? neckSeverity,
    PainFrequency? painFrequency,
    Set<Goal>? goals,
    DateTime? completedAt,
  }) =>
      SurveyResult(
        activities: activities ?? this.activities,
        neckSeverity: neckSeverity ?? this.neckSeverity,
        painFrequency: painFrequency ?? this.painFrequency,
        goals: goals ?? this.goals,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'activities': activities.map((e) => e.name).toList(),
        'neckSeverity': neckSeverity,
        'painFrequency': painFrequency?.name,
        'goals': goals.map((e) => e.name).toList(),
        'completedAt': completedAt?.toIso8601String(),
      };

  static SurveyResult fromJson(Map<String, dynamic> j) => SurveyResult(
        activities: ((j['activities'] as List?) ?? [])
            .map((n) =>
                DailyActivity.values.firstWhere((e) => e.name == n as String))
            .toSet(),
        neckSeverity: (j['neckSeverity'] as num?)?.toDouble() ?? 0.3,
        painFrequency: j['painFrequency'] == null
            ? null
            : PainFrequency.values.firstWhere(
                (e) => e.name == j['painFrequency'] as String),
        goals: ((j['goals'] as List?) ?? [])
            .map((n) => Goal.values.firstWhere((e) => e.name == n as String))
            .toSet(),
        completedAt: j['completedAt'] == null
            ? null
            : DateTime.parse(j['completedAt'] as String),
      );

  /// Grobe Ableitung passender Übungs-Buckets. Die eigentliche Auswahl der
  /// Lottie-Animationen kommt später — hier nur die Logik, was zu wem passt.
  List<ExerciseBucket> recommendedBuckets() {
    final b = <ExerciseBucket>{};
    if (activities.contains(DailyActivity.office) ||
        activities.contains(DailyActivity.studying) ||
        activities.contains(DailyActivity.driving)) {
      b.add(ExerciseBucket.deskStretch);
      b.add(ExerciseBucket.shoulderRolls);
    }
    if (activities.contains(DailyActivity.gaming) ||
        activities.contains(DailyActivity.scrolling)) {
      b.add(ExerciseBucket.chinTucks);
      b.add(ExerciseBucket.neckRotation);
    }
    if (activities.contains(DailyActivity.crafting)) {
      b.add(ExerciseBucket.wallAngels);
    }
    if (neckSeverity >= 0.6) {
      b.add(ExerciseBucket.chinTucks);
      b.add(ExerciseBucket.wallAngels);
    }
    if (painFrequency == PainFrequency.daily ||
        painFrequency == PainFrequency.rightNow) {
      b.add(ExerciseBucket.neckRotation);
      b.add(ExerciseBucket.standAndBreathe);
    }
    if (goals.contains(Goal.lessPain)) b.add(ExerciseBucket.chinTucks);
    if (goals.contains(Goal.moveMore)) b.add(ExerciseBucket.standAndBreathe);
    if (b.isEmpty) b.add(ExerciseBucket.shoulderRolls);
    return b.toList();
  }
}

class SurveyStore extends ChangeNotifier {
  static const _key = 'survey_v1';
  static SurveyStore? _instance;

  static SurveyStore get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('SurveyStore.init() must be awaited before use.');
    }
    return i;
  }

  static Future<SurveyStore> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    SurveyResult? result;
    if (raw != null) {
      try {
        result = SurveyResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return _instance = SurveyStore._(prefs, result);
  }

  final SharedPreferences _prefs;
  SurveyResult? _result;
  SurveyStore._(this._prefs, this._result);

  SurveyResult? get result => _result;
  bool get isComplete => _result?.completedAt != null;

  Future<void> save(SurveyResult r) async {
    _result = r;
    await _prefs.setString(_key, jsonEncode(r.toJson()));
    notifyListeners();
  }
}
