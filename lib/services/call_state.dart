import 'dart:async';

import 'package:flutter/foundation.dart';

class ActiveCall {
  final DateTime startedAt;
  final int windowSeconds;
  const ActiveCall(this.startedAt, this.windowSeconds);

  int get elapsedSeconds =>
      DateTime.now().difference(startedAt).inSeconds;
  int get secondsLeft =>
      (windowSeconds - elapsedSeconds).clamp(0, windowSeconds);
  bool get expired => elapsedSeconds >= windowSeconds;
}

/// Singleton mit dem aktuellen (offenen) Call. Solange `value != null &&
/// !expired` ist das I'M-STRAIGHT-Fenster aktiv. Ein Ticker feuert jede
/// Sekunde `notifyListeners`, damit die Countdown-UI ohne extra Timer neu baut.
class CallState extends ChangeNotifier {
  CallState._();
  static final CallState instance = CallState._();

  ActiveCall? _current;
  Timer? _ticker;

  ActiveCall? get current => _current;
  bool get isActive => _current != null && !_current!.expired;

  /// Startet ein neues Call-Fenster. Wenn schon eins läuft, wird es ersetzt.
  void trigger({int windowSeconds = 10}) {
    _current = ActiveCall(DateTime.now(), windowSeconds);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_current?.expired ?? true) {
        _ticker?.cancel();
        _ticker = null;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// Bestätigt den aktuellen Call. Gibt die Reaktionszeit in Sekunden zurück
  /// oder null, wenn kein Call aktiv oder das Fenster schon abgelaufen ist.
  int? confirm() {
    final c = _current;
    if (c == null || c.expired) return null;
    final secs = c.elapsedSeconds;
    _ticker?.cancel();
    _ticker = null;
    _current = null;
    notifyListeners();
    return secs;
  }

  /// Räumt den (abgelaufenen) Call weg, sobald der Miss verbucht wurde.
  void clear() {
    _ticker?.cancel();
    _ticker = null;
    _current = null;
    notifyListeners();
  }
}
