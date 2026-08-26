import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Anonymer Sign-In beim ersten Start. Legt (falls neu) ein Doc
/// `users/{uid}` mit den Basisfeldern an.
///
/// Später kann ein anonymer User via `linkWith…` auf E-Mail/Google upgraden,
/// ohne die uid oder die verknüpften Daten zu verlieren.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;
  String? get uid => _user?.uid;
  bool get signedIn => _user != null;

  Future<void> init() async {
    _auth.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    });
    _user = _auth.currentUser;
    if (_user == null) {
      try {
        final cred = await _auth.signInAnonymously();
        _user = cred.user;
      } catch (e, st) {
        debugPrint('Anonymous sign-in failed: $e\n$st');
      }
    }
    // Nicht awaiten und nicht crashen — App muss trotzdem starten.
    unawaited(_ensureUserDoc().catchError((e, st) {
      debugPrint('users/{uid} write failed: $e');
    }));
    notifyListeners();
  }

  DocumentReference<Map<String, dynamic>> get userDoc =>
      _db.collection('users').doc(uid);

  Future<void> _ensureUserDoc() async {
    final u = _user;
    if (u == null) return;
    final ref = _db.collection('users').doc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'displayName': null,
        'fcmToken': null,
        'platform': defaultTargetPlatform.name,
        'anonymous': u.isAnonymous,
      });
    } else {
      await ref.update({'lastSeenAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> setDisplayName(String name) async {
    await userDoc.set({'displayName': name}, SetOptions(merge: true));
  }

  Future<void> setFcmToken(String? token) async {
    await userDoc.set({'fcmToken': token}, SetOptions(merge: true));
  }
}
