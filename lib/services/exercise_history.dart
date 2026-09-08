import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Merkt sich welche Übungen der User in letzter Zeit gemacht hat, damit sie
/// beim nächsten Zufalls-Angebot nicht sofort wieder vorgeschlagen werden.
///
/// UX-Logik:
/// - Beim Erfolg einer Übung wird ihre ID hier gemerkt.
/// - Der Choice-Screen filtert diese IDs raus und würfelt aus dem Rest.
/// - Sind für einen Pool weniger als benötigt übrig, werden dessen IDs
///   automatisch aus der History entfernt (Reset für diesen Pool).
class ExerciseHistory extends ChangeNotifier {
  static const _key = 'exercise_history_done_v1';

  static ExerciseHistory? _instance;
  static ExerciseHistory get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('ExerciseHistory.init() must be awaited before use.');
    }
    return i;
  }

  static Future<ExerciseHistory> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const [];
    return _instance = ExerciseHistory._(prefs, list.toSet());
  }

  final SharedPreferences _prefs;
  final Set<String> _done;
  ExerciseHistory._(this._prefs, this._done);

  bool wasDone(String id) => _done.contains(id);

  Future<void> markDone(String id) async {
    if (_done.add(id)) {
      await _persist();
      notifyListeners();
    }
  }

  /// Entfernt IDs aus der History (z.B. wenn ein Pool erschöpft ist).
  Future<void> forget(Iterable<String> ids) async {
    var changed = false;
    for (final id in ids) {
      if (_done.remove(id)) changed = true;
    }
    if (changed) {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> resetAll() async {
    if (_done.isEmpty) return;
    _done.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      _prefs.setStringList(_key, _done.toList(growable: false));
}
