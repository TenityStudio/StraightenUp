import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';

/// Lädt Pro-/Extra-Übungen aus Firestore, cached sie lokal in SharedPreferences
/// und stellt sie über einen ChangeNotifier zur Verfügung.
///
/// UX-Prinzip:
/// - Beim App-Start wird der lokale Cache SOFORT gelesen und in [current]
///   bereitgestellt (kein Netzwerk-Wait, kein Flackern).
/// - Danach läuft ein Background-Refresh gegen Firestore. Wenn neue Daten
///   ankommen, wird [current] aktualisiert und alle Listener benachrichtigt.
///
/// Firestore-Struktur (Collection `exercises`):
/// ```
/// exercises/{id}
///   title       string
///   subtitle    string
///   steps       array<string>
///   seconds     number
///   context     'transit' | 'office' | 'home'
///   isPro       bool
///   animationKey string?    (optional — key aus exercise_animation.dart)
///   lottieAsset  string?    (optional — Firebase-Storage-URL o.ä.)
///   week        number?     (optional — für "wöchentliche Drops")
///   updatedAt   timestamp   (optional — für Sync-Diagnose)
/// ```
class RemoteExerciseStore extends ChangeNotifier {
  static const _cacheKey = 'remote_exercises_v1';
  static const _cacheTsKey = 'remote_exercises_ts_v1';
  static const _staleness = Duration(hours: 6);
  static const _collection = 'exercises';

  static RemoteExerciseStore? _instance;
  static RemoteExerciseStore get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('RemoteExerciseStore.init() must be awaited before use.');
    }
    return i;
  }

  /// Legt die Instanz an und lädt sofort den lokalen Cache.
  /// Der Firestore-Refresh läuft danach unawaited im Hintergrund.
  static Future<RemoteExerciseStore> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    final store = RemoteExerciseStore._(prefs);
    store._loadFromCache();
    // Fire and forget — App darf nicht auf Netzwerk warten.
    unawaited(store.refreshIfStale());
    return _instance = store;
  }

  final SharedPreferences _prefs;
  List<Exercise> _current = const [];
  DateTime? _lastFetched;
  bool _refreshing = false;

  RemoteExerciseStore._(this._prefs);

  List<Exercise> get current => List.unmodifiable(_current);
  DateTime? get lastFetched => _lastFetched;
  bool get isRefreshing => _refreshing;

  void _loadFromCache() {
    try {
      final raw = _prefs.getString(_cacheKey);
      final tsMs = _prefs.getInt(_cacheTsKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(Exercise.fromJson)
          .whereType<Exercise>()
          .toList();
      _current = list;
      if (tsMs != null) {
        _lastFetched = DateTime.fromMillisecondsSinceEpoch(tsMs);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('RemoteExerciseStore: cache load failed: $e');
    }
  }

  Future<void> refreshIfStale() async {
    final last = _lastFetched;
    if (last != null && DateTime.now().difference(last) < _staleness) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final snap =
          await FirebaseFirestore.instance.collection(_collection).get();
      final list = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .map(Exercise.fromJson)
          .whereType<Exercise>()
          .toList();
      _current = list;
      _lastFetched = DateTime.now();
      await _persist();
      notifyListeners();
    } catch (e) {
      // Kein Netz / Firestore-Regeln / etc. — App läuft mit Cache weiter.
      debugPrint('RemoteExerciseStore: refresh failed: $e');
    } finally {
      _refreshing = false;
    }
  }

  /// Debug/Admin: schreibt eine Liste von Übungen als Docs in Firestore.
  /// Existierende Docs mit gleicher `id` werden per merge überschrieben.
  Future<int> seedExercises(List<Exercise> exercises) async {
    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance.collection(_collection);
    for (final ex in exercises) {
      final data = Map<String, dynamic>.from(ex.toJson())
        ..remove('id')
        ..['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(col.doc(ex.id), data, SetOptions(merge: true));
    }
    await batch.commit();
    await refresh(); // sofort neu einlesen damit die App die Docs kennt
    return exercises.length;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _cacheKey,
      jsonEncode(_current.map((e) => e.toJson()).toList()),
    );
    final ts = _lastFetched?.millisecondsSinceEpoch;
    if (ts != null) {
      await _prefs.setInt(_cacheTsKey, ts);
    }
  }
}
