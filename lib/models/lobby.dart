import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';

class LobbyMember {
  final String uid;
  final String displayName;
  final DateTime? joinedAt;
  final int streak;
  final DateTime? lastSummonAt;
  final bool host;

  const LobbyMember({
    required this.uid,
    required this.displayName,
    this.joinedAt,
    this.streak = 0,
    this.lastSummonAt,
    this.host = false,
  });

  static LobbyMember fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String hostUid,
  }) {
    final d = doc.data() ?? {};
    return LobbyMember(
      uid: doc.id,
      displayName: (d['displayName'] as String?) ?? 'Anon',
      joinedAt: (d['joinedAt'] as Timestamp?)?.toDate(),
      streak: (d['streak'] as int?) ?? 0,
      lastSummonAt: (d['lastSummonAt'] as Timestamp?)?.toDate(),
      host: doc.id == hostUid,
    );
  }
}

class Lobby {
  final String code;
  final String name;
  final String hostUid;
  final int perDay;
  final int windowStartHour;
  final int windowEndHour;
  final DateTime? createdAt;
  final bool hasPassword;
  final String? passwordHash;

  const Lobby({
    required this.code,
    required this.name,
    required this.hostUid,
    required this.perDay,
    required this.windowStartHour,
    required this.windowEndHour,
    this.createdAt,
    this.hasPassword = false,
    this.passwordHash,
  });

  static Lobby fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Lobby(
      code: doc.id,
      name: (d['name'] as String?) ?? doc.id,
      hostUid: (d['hostUid'] as String?) ?? '',
      perDay: (d['perDay'] as int?) ?? 3,
      windowStartHour: (d['startHour'] as int?) ?? 9,
      windowEndHour: (d['endHour'] as int?) ?? 21,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      hasPassword: (d['hasPassword'] as bool?) ?? false,
      passwordHash: d['passwordHash'] as String?,
    );
  }
}

/// SHA-256 des Passworts als Hex. Client-seitig — reicht für „Freunde-App".
/// Wer richtig sicher will: Cloud Function join, Hash serverseitig checken.
String hashLobbyPassword(String password) {
  final salted = 'straight_guys_v1:$password';
  return sha256.convert(utf8.encode(salted)).toString();
}

class WrongPasswordException implements Exception {
  const WrongPasswordException();
  @override
  String toString() => 'Wrong password.';
}

class LobbyNotFoundException implements Exception {
  const LobbyNotFoundException();
  @override
  String toString() => 'No lobby with that code.';
}

class LobbyResponse {
  final String uid;
  final String displayName;
  final int? responseSeconds; // null = missed
  final int order; // 1-based unter den geacked; -1 = missed
  const LobbyResponse({
    required this.uid,
    required this.displayName,
    required this.responseSeconds,
    required this.order,
  });
  bool get missed => responseSeconds == null;
}

class LobbyEvent {
  final String id;
  final DateTime startedAt;
  final int windowSeconds;
  final String trigger; // "summon" | "schedule"
  final String? summonerUid;
  final bool finalized;
  final List<LobbyResponse> responses;

  const LobbyEvent({
    required this.id,
    required this.startedAt,
    required this.windowSeconds,
    required this.trigger,
    required this.summonerUid,
    required this.finalized,
    required this.responses,
  });

  bool get expired {
    return DateTime.now()
            .difference(startedAt)
            .inSeconds >=
        windowSeconds;
  }
}

/// Firestore-basierter Lobby-Store. Hört live auf `lobbies/{code}`,
/// `.../members` und das neueste `.../events` inkl. Responses.
class LobbyStore extends ChangeNotifier {
  static const summonCooldown = Duration(hours: 3);

  static LobbyStore? _instance;
  static LobbyStore get instance {
    final i = _instance;
    if (i == null) throw StateError('LobbyStore.init() must be awaited first.');
    return i;
  }

  static Future<LobbyStore> init() async {
    if (_instance != null) return _instance!;
    final store = LobbyStore._();
    _instance = store;
    // Firestore-Restore läuft im Hintergrund — blockiert nicht den Startup.
    unawaited(store._restoreActiveLobby().catchError((e, st) {
      debugPrint('restoreActiveLobby failed: $e');
    }));
    return store;
  }

  LobbyStore._();

  final _db = FirebaseFirestore.instance;
  final _auth = AuthService.instance;

  Lobby? _current;
  List<LobbyMember> _members = const [];
  LobbyEvent? _lastEvent;

  StreamSubscription? _lobbySub;
  StreamSubscription? _membersSub;
  StreamSubscription? _eventsSub;
  StreamSubscription? _responsesSub;
  String? _currentEventId;

  Lobby? get current => _current;
  bool get inLobby => _current != null;
  List<LobbyMember> get members => _members;
  LobbyEvent? get lastEvent => _lastEvent;

  String get _yourUid => _auth.uid ?? '';
  String get yourDisplayName {
    final m = _members.where((m) => m.uid == _yourUid).firstOrNull;
    return m?.displayName ?? 'You';
  }

  LobbyMember? get you =>
      _members.where((m) => m.uid == _yourUid).firstOrNull;

  bool get youAreHost => _current?.hostUid == _yourUid;

  DateTime? get lastSummonAt => you?.lastSummonAt;

  Duration get remainingSummonCooldown {
    final last = lastSummonAt;
    if (last == null) return Duration.zero;
    final left = summonCooldown - DateTime.now().difference(last);
    return left.isNegative ? Duration.zero : left;
  }

  bool get canSummonNow => remainingSummonCooldown == Duration.zero;

  // ─── Setup / Teardown ─────────────────────────────────────────────────────

  Future<void> _restoreActiveLobby() async {
    final uid = _auth.uid;
    if (uid == null) return;
    try {
      final userSnap = await _db.collection('users').doc(uid).get();
      final code = userSnap.data()?['activeLobbyCode'] as String?;
      if (code != null && code.isNotEmpty) {
        await _attachTo(code);
      }
    } catch (e) {
      debugPrint('restoreActiveLobby failed: $e');
    }
  }

  Future<void> _attachTo(String code) async {
    _detach();
    final ref = _db.collection('lobbies').doc(code);
    _lobbySub = ref.snapshots().listen((snap) {
      if (!snap.exists) {
        _current = null;
        _members = const [];
        _lastEvent = null;
        notifyListeners();
        return;
      }
      _current = Lobby.fromDoc(snap);
      notifyListeners();
    });
    _membersSub = ref
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .listen((snap) {
      final hostUid = _current?.hostUid ?? '';
      _members = snap.docs
          .map((d) => LobbyMember.fromDoc(d, hostUid: hostUid))
          .toList();
      notifyListeners();
    });
    _eventsSub = ref
        .collection('events')
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) {
        _lastEvent = null;
        _currentEventId = null;
        _responsesSub?.cancel();
        notifyListeners();
        return;
      }
      final doc = snap.docs.first;
      final data = doc.data();
      final startedAt =
          (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      _lastEvent = LobbyEvent(
        id: doc.id,
        startedAt: startedAt,
        windowSeconds: (data['windowSeconds'] as int?) ?? 10,
        trigger: (data['trigger'] as String?) ?? 'summon',
        summonerUid: data['summonerUid'] as String?,
        finalized: (data['finalized'] as bool?) ?? false,
        responses: _lastEvent?.id == doc.id
            ? _lastEvent!.responses
            : const [],
      );
      if (_currentEventId != doc.id) {
        _currentEventId = doc.id;
        _responsesSub?.cancel();
        _responsesSub = ref
            .collection('events')
            .doc(doc.id)
            .collection('responses')
            .snapshots()
            .listen(_onResponses);
      }
      notifyListeners();
    });
  }

  void _onResponses(QuerySnapshot<Map<String, dynamic>> snap) {
    final e = _lastEvent;
    if (e == null) return;
    final aced = <LobbyResponse>[];
    final missed = <LobbyResponse>[];
    for (final d in snap.docs) {
      final data = d.data();
      final secs = data['responseSeconds'] as int?;
      final resp = LobbyResponse(
        uid: d.id,
        displayName: (data['displayName'] as String?) ?? 'Anon',
        responseSeconds: secs,
        order: 0,
      );
      if (secs == null) {
        missed.add(resp);
      } else {
        aced.add(resp);
      }
    }
    aced.sort((a, b) =>
        (a.responseSeconds ?? 999).compareTo(b.responseSeconds ?? 999));
    final ranked = <LobbyResponse>[
      for (var i = 0; i < aced.length; i++)
        LobbyResponse(
          uid: aced[i].uid,
          displayName: aced[i].displayName,
          responseSeconds: aced[i].responseSeconds,
          order: i + 1,
        ),
      ...missed.map((r) => LobbyResponse(
            uid: r.uid,
            displayName: r.displayName,
            responseSeconds: null,
            order: -1,
          )),
    ];
    _lastEvent = LobbyEvent(
      id: e.id,
      startedAt: e.startedAt,
      windowSeconds: e.windowSeconds,
      trigger: e.trigger,
      summonerUid: e.summonerUid,
      finalized: e.finalized,
      responses: ranked,
    );
    notifyListeners();
  }

  void _detach() {
    _lobbySub?.cancel();
    _membersSub?.cancel();
    _eventsSub?.cancel();
    _responsesSub?.cancel();
    _lobbySub = null;
    _membersSub = null;
    _eventsSub = null;
    _responsesSub = null;
    _currentEventId = null;
    _current = null;
    _members = const [];
    _lastEvent = null;
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  static String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<Lobby> create({
    required String lobbyName,
    required String yourName,
    required int perDay,
    required int startHour,
    required int endHour,
    String? password,
  }) async {
    final uid = _yourUid;
    if (uid.isEmpty) throw StateError('Not signed in.');
    String code;
    while (true) {
      code = generateCode();
      final exists = (await _db.collection('lobbies').doc(code).get()).exists;
      if (!exists) break;
    }
    final ref = _db.collection('lobbies').doc(code);
    final hasPassword = password != null && password.isNotEmpty;
    final batch = _db.batch();
    batch.set(ref, {
      'name': lobbyName,
      'hostUid': uid,
      'perDay': perDay,
      'startHour': startHour,
      'endHour': endHour,
      'createdAt': FieldValue.serverTimestamp(),
      'hasPassword': hasPassword,
      'passwordHash':
          hasPassword ? hashLobbyPassword(password) : null,
    });
    batch.set(ref.collection('members').doc(uid), {
      'displayName': yourName,
      'joinedAt': FieldValue.serverTimestamp(),
      'streak': 0,
    });
    batch.set(_db.collection('users').doc(uid),
        {'displayName': yourName, 'activeLobbyCode': code},
        SetOptions(merge: true));
    await batch.commit();
    await _attachTo(code);
    // Solo-Reminder ausschalten — im Group-Mode kommen die Calls über FCM.
    unawaited(NotificationService.instance.cancelAll());
    return Lobby.fromDoc(await ref.get());
  }

  /// Prüft ob eine Lobby existiert und ob sie ein Passwort verlangt — ohne
  /// beizutreten. Für die Join-UI, damit sie das Passwort-Feld erst zeigt
  /// wenn nötig.
  Future<({bool exists, bool hasPassword})> peekLobby(String code) async {
    final normalized = code.toUpperCase().trim();
    final snap = await _db.collection('lobbies').doc(normalized).get();
    if (!snap.exists) return (exists: false, hasPassword: false);
    final d = snap.data() ?? {};
    return (exists: true, hasPassword: (d['hasPassword'] as bool?) ?? false);
  }

  Future<Lobby> join({
    required String code,
    required String yourName,
    String? password,
  }) async {
    final uid = _yourUid;
    if (uid.isEmpty) throw StateError('Not signed in.');
    final normalized = code.toUpperCase().trim();
    final ref = _db.collection('lobbies').doc(normalized);
    final snap = await ref.get();
    if (!snap.exists) {
      throw const LobbyNotFoundException();
    }
    final data = snap.data() ?? {};
    final hasPassword = (data['hasPassword'] as bool?) ?? false;
    if (hasPassword) {
      final expected = data['passwordHash'] as String?;
      if (password == null || password.isEmpty || expected == null) {
        throw const WrongPasswordException();
      }
      if (hashLobbyPassword(password) != expected) {
        throw const WrongPasswordException();
      }
    }
    final batch = _db.batch();
    batch.set(ref.collection('members').doc(uid), {
      'displayName': yourName,
      'joinedAt': FieldValue.serverTimestamp(),
      'streak': 0,
    }, SetOptions(merge: true));
    batch.set(_db.collection('users').doc(uid),
        {'displayName': yourName, 'activeLobbyCode': normalized},
        SetOptions(merge: true));
    await batch.commit();
    await _attachTo(normalized);
    unawaited(NotificationService.instance.cancelAll());
    return Lobby.fromDoc(snap);
  }

  /// Nur eigenes Member-Doc entfernen. Lobby bleibt bestehen.
  Future<void> leave() async {
    final uid = _yourUid;
    final code = _current?.code;
    _detach();
    notifyListeners();
    if (uid.isEmpty || code == null) return;
    try {
      await _db
          .collection('lobbies')
          .doc(code)
          .collection('members')
          .doc(uid)
          .delete();
      await _db.collection('users').doc(uid).set(
          {'activeLobbyCode': FieldValue.delete()},
          SetOptions(merge: true));
    } catch (e) {
      debugPrint('leave lobby cleanup failed: $e');
    }
  }

  /// Host löscht die komplette Lobby. Client entfernt Lobby-Doc; die
  /// Cloud Function `onLobbyDeleted` räumt Members/Events/Responses und
  /// den `activeLobbyCode` bei allen Mitgliedern nach.
  Future<void> closeLobby() async {
    final code = _current?.code;
    if (code == null) return;
    if (!youAreHost) {
      throw StateError('Only the host can close the lobby.');
    }
    _detach();
    notifyListeners();
    try {
      await _db.collection('lobbies').doc(code).delete();
      await _db.collection('users').doc(_yourUid).set(
          {'activeLobbyCode': FieldValue.delete()},
          SetOptions(merge: true));
    } catch (e) {
      debugPrint('closeLobby failed: $e');
      rethrow;
    }
  }

  /// Erzeugt einen frischen Event-Doc und markiert den Cooldown für den User.
  /// Der FCM-Fanout an die anderen Members passiert später serverseitig via
  /// Cloud Function; lokal aktiviert der Aufrufer selbst sein eigenes 10s-
  /// Fenster (siehe [NotificationService.triggerTestCallNow]).
  Future<void> summonCall({int windowSeconds = 10}) async {
    final uid = _yourUid;
    final code = _current?.code;
    if (code == null || uid.isEmpty) return;
    if (!canSummonNow) return;
    final ref = _db.collection('lobbies').doc(code);
    await ref.collection('events').add({
      'startedAt': FieldValue.serverTimestamp(),
      'windowSeconds': windowSeconds,
      'trigger': 'summon',
      'summonerUid': uid,
      'finalized': false,
    });
    await ref
        .collection('members')
        .doc(uid)
        .set({'lastSummonAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
  }

  /// Schreibt „aced" für den aktuellen User in das laufende Event.
  // ─── Ghost debug helpers ────────────────────────────────────────────────

  static const _ghostNames = [
    'Marko', 'Lena', 'Jonas', 'Ivo', 'Ana',
    'Peter', 'Ivana', 'Luka', 'Sara', 'Nikola'
  ];

  int get ghostCount =>
      _members.where((m) => m.uid.startsWith('ghost_')).length;

  Future<void> spawnGhost() async {
    final code = _current?.code;
    if (code == null || _yourUid.isEmpty) return;
    final rnd = Random();
    final name = _ghostNames[rnd.nextInt(_ghostNames.length)];
    final ghostId =
        'ghost_${rnd.nextInt(9999999).toString().padLeft(7, '0')}';
    await _db
        .collection('lobbies')
        .doc(code)
        .collection('members')
        .doc(ghostId)
        .set({
      'displayName': name,
      'joinedAt': FieldValue.serverTimestamp(),
      'streak': rnd.nextInt(20),
      'ghost': true,
      'spawnedBy': _yourUid,
    });
  }

  Future<bool> ghostRespondToCurrentCall() async {
    final code = _current?.code;
    final e = _lastEvent;
    if (code == null || e == null || e.finalized) return false;
    final respondedIds = e.responses.map((r) => r.uid).toSet();
    final pendingGhosts = _members
        .where((m) =>
            m.uid.startsWith('ghost_') && !respondedIds.contains(m.uid))
        .toList();
    if (pendingGhosts.isEmpty) return false;
    final ghost = pendingGhosts.first;
    final rnd = Random();
    final secs = 2 + rnd.nextInt(5);
    await _db
        .collection('lobbies')
        .doc(code)
        .collection('events')
        .doc(e.id)
        .collection('responses')
        .doc(ghost.uid)
        .set({
      'displayName': ghost.displayName,
      'responseSeconds': secs,
      'answeredAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Future<int> removeAllGhosts() async {
    final code = _current?.code;
    if (code == null) return 0;
    final snap = await _db
        .collection('lobbies')
        .doc(code)
        .collection('members')
        .where('ghost', isEqualTo: true)
        .get();
    if (snap.docs.isEmpty) return 0;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    return snap.docs.length;
  }

  // ─── Real user response ─────────────────────────────────────────────────

  Future<void> recordYourResponse(int seconds) async {
    final uid = _yourUid;
    final code = _current?.code;
    final e = _lastEvent;
    if (code == null || uid.isEmpty || e == null) return;
    if (e.finalized) return;
    await _db
        .collection('lobbies')
        .doc(code)
        .collection('events')
        .doc(e.id)
        .collection('responses')
        .doc(uid)
        .set({
      'displayName': yourDisplayName,
      'responseSeconds': seconds,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }
}
