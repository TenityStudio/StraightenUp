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
  bool get isAnonymous => _user?.isAnonymous ?? true;
  bool get hasRealAccount => _user != null && !_user!.isAnonymous;
  bool get emailVerified => _user?.emailVerified ?? false;
  /// True nur wenn echter Account UND Email verifiziert.
  bool get isFullyVerified => hasRealAccount && emailVerified;
  String? get email => _user?.email;

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

  String? get displayName => _user?.displayName;

  Future<void> setDisplayName(String name) async {
    final u = _user;
    if (u != null) {
      await u.updateDisplayName(name);
      // Reload damit displayName im _user aktualisiert ist.
      await u.reload();
      _user = _auth.currentUser;
    }
    await userDoc.set({'displayName': name}, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> setFcmToken(String? token) async {
    await userDoc.set({'fcmToken': token}, SetOptions(merge: true));
  }

  // ─── Account-Management ───────────────────────────────────────────────────

  /// Legt einen echten Email/Password-Account an und verknüpft ihn mit dem
  /// aktuellen anonymen User — Daten (Firestore-Docs) bleiben erhalten.
  /// Schickt direkt danach eine Verifizierungs-Mail.
  Future<void> signUpWithEmail(String email, String password) async {
    final current = _user;
    if (current != null && current.isAnonymous) {
      // Upgrade des anonymen Accounts → gleiche UID, alle Daten bleiben.
      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      final userCred = await current.linkWithCredential(credential);
      _user = userCred.user;
    } else {
      final userCred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      _user = userCred.user;
    }
    await _ensureUserDoc();
    await userDoc.set({'anonymous': false, 'email': email},
        SetOptions(merge: true));
    // Verifizierungs-Mail schicken (nicht fatal wenn's fehlschlägt).
    try {
      await _user?.sendEmailVerification();
    } catch (e) {
      debugPrint('sendEmailVerification failed: $e');
    }
    notifyListeners();
  }

  /// Verifizierungs-Mail erneut schicken.
  Future<void> resendVerificationEmail() async {
    final u = _user;
    if (u == null || u.emailVerified) return;
    await u.sendEmailVerification();
  }

  /// Läd den User-State neu (um `emailVerified` nach Klick auf den Mail-Link
  /// zu aktualisieren). Gibt true zurück wenn jetzt verifiziert.
  Future<bool> refreshVerificationStatus() async {
    final u = _user;
    if (u == null) return false;
    await u.reload();
    _user = _auth.currentUser;
    notifyListeners();
    return _user?.emailVerified ?? false;
  }

  /// Meldet einen existierenden Account an. Verwirft die aktuelle anonyme
  /// Session (die Daten der Anonymen bleiben in Firestore, sind aber nicht
  /// mehr aus der App erreichbar).
  Future<void> signInWithEmail(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    _user = userCred.user;
    await _ensureUserDoc();
    notifyListeners();
  }

  /// Password-Reset-Mail schicken.
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Ausloggen → zurück zu anonymem Modus (neue UID).
  Future<void> signOutToAnonymous() async {
    await _auth.signOut();
    final cred = await _auth.signInAnonymously();
    _user = cred.user;
    await _ensureUserDoc();
    notifyListeners();
  }

  /// Löscht Account vollständig — Firebase Auth + Firestore-Docs.
  /// Danach wird ein frischer anonymer User erzeugt (App bleibt nutzbar).
  ///
  /// Für neu-authentifizierte User erforderlich — falls Firebase `requires-
  /// recent-login` wirft, muss der User erst mit dem Password neu einloggen,
  /// dann kann gelöscht werden.
  Future<void> deleteAccount({String? password}) async {
    final u = _user;
    if (u == null) return;

    // Wenn User nicht kürzlich eingeloggt war → re-authentifizieren mit
    // dem eingegebenen Passwort.
    if (password != null && u.email != null && !u.isAnonymous) {
      final cred = EmailAuthProvider.credential(
          email: u.email!, password: password);
      await u.reauthenticateWithCredential(cred);
    }

    // Firestore-User-Doc löschen (falls existiert). Fehler ignorieren — Auth-
    // Delete ist wichtiger und Firestore-TTL/Cleanup kann Reste später holen.
    try {
      await _db.collection('users').doc(u.uid).delete();
    } catch (e) {
      debugPrint('user doc delete failed: $e');
    }

    // Firebase Auth Löschen
    await u.delete();

    // Frischen anonymen User starten (damit App weiterläuft).
    final cred = await _auth.signInAnonymously();
    _user = cred.user;
    await _ensureUserDoc();
    notifyListeners();
  }
}
