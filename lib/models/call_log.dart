import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_settings.dart';

enum CallResult { aced, slouched }

class CallEntry {
  final DateTime time;
  final CallResult result;
  final int responseSeconds;
  final AppMode mode;
  final String? exerciseId;

  CallEntry({
    required this.time,
    required this.result,
    required this.responseSeconds,
    this.mode = AppMode.solo,
    this.exerciseId,
  });

  CallEntry copyWith({String? exerciseId}) => CallEntry(
        time: time,
        result: result,
        responseSeconds: responseSeconds,
        mode: mode,
        exerciseId: exerciseId ?? this.exerciseId,
      );

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'r': result.name,
        's': responseSeconds,
        'm': mode.name,
        if (exerciseId != null) 'e': exerciseId,
      };

  static CallEntry fromJson(Map<String, dynamic> j) => CallEntry(
        time: DateTime.parse(j['t'] as String),
        result: CallResult.values.firstWhere((e) => e.name == j['r']),
        responseSeconds: j['s'] as int,
        mode: AppMode.values.firstWhere(
          (e) => e.name == (j['m'] as String? ?? 'solo'),
          orElse: () => AppMode.solo,
        ),
        exerciseId: j['e'] as String?,
      );

  String get hhmm =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

enum DayStatus { none, allAced, partial, allMissed, group }

class DaySummary {
  final DateTime day;
  final DayStatus status;
  const DaySummary(this.day, this.status);
}

class CallLog extends ChangeNotifier {
  static const _key = 'call_log_v1';

  static CallLog? _instance;
  static CallLog get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('CallLog.init() must be awaited before use.');
    }
    return i;
  }

  static Future<CallLog> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final list = raw == null
        ? <CallEntry>[]
        : (jsonDecode(raw) as List)
            .map((e) => CallEntry.fromJson(e as Map<String, dynamic>))
            .toList();
    return _instance = CallLog._(prefs, list);
  }

  final SharedPreferences _prefs;
  List<CallEntry> _entries;
  CallLog._(this._prefs, this._entries);

  List<CallEntry> get all => List.unmodifiable(_entries);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<CallEntry> get today {
    final now = DateTime.now();
    return _entries
        .where((e) => _sameDay(e.time, now))
        .toList()
        .reversed
        .toList(growable: false);
  }

  int get acedTotal =>
      _entries.where((e) => e.result == CallResult.aced).length;

  int get callsToday => today.length;
  int get acedToday =>
      today.where((e) => e.result == CallResult.aced).length;

  /// Fasst die letzten [days] Tage (endet heute, ältester Eintrag zuerst) zu
  /// je einer Kachel-Status-Kategorie zusammen.
  List<DaySummary> summaryOfLastDays(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      final dayEntries =
          _entries.where((e) => _sameDay(e.time, day)).toList(growable: false);
      if (dayEntries.isEmpty) return DaySummary(day, DayStatus.none);
      if (dayEntries.any((e) => e.mode == AppMode.group)) {
        return DaySummary(day, DayStatus.group);
      }
      final aced =
          dayEntries.where((e) => e.result == CallResult.aced).length;
      if (aced == 0) return DaySummary(day, DayStatus.allMissed);
      if (aced == dayEntries.length) return DaySummary(day, DayStatus.allAced);
      return DaySummary(day, DayStatus.partial);
    });
  }

  /// Setzt die Übungs-ID am letzten Aced-Eintrag von heute.
  Future<void> attachExerciseToLastAced(String exerciseId) async {
    final now = DateTime.now();
    for (int i = _entries.length - 1; i >= 0; i--) {
      final e = _entries[i];
      if (!_sameDay(e.time, now)) break;
      if (e.result == CallResult.aced) {
        _entries[i] = e.copyWith(exerciseId: exerciseId);
        await _persist();
        notifyListeners();
        return;
      }
    }
  }

  Future<void> add(CallEntry entry) async {
    _entries.add(entry);
    if (_entries.length > 500) {
      _entries = _entries.sublist(_entries.length - 500);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> clearToday() async {
    final now = DateTime.now();
    _entries.removeWhere((e) => _sameDay(e.time, now));
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _entries.clear();
    await _prefs.remove(_key);
    notifyListeners();
  }

  Future<void> _persist() => _prefs.setString(
        _key,
        jsonEncode(_entries.map((e) => e.toJson()).toList()),
      );
}
