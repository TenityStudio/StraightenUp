import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';

/// Sign-Up / Sign-In Screen. Zwei Modi via Toggle.
/// Bei Sign-Up wird der anonyme User upgegraded (UID + Daten bleiben).
class SignInScreen extends StatefulWidget {
  /// Optionaler Titel (z.B. "Sign in to buy Pro").
  final String? intent;
  const SignInScreen({super.key, this.intent});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _signUp = true;
  bool _awaitingVerify = false; // nach Sign-Up: warte auf Klick auf Mail-Link

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      _snack('Ungültige Email.', error: true);
      return;
    }
    if (password.length < 6) {
      _snack('Passwort mindestens 6 Zeichen.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      if (_signUp) {
        await AuthService.instance.signUpWithEmail(email, password);
        if (!mounted) return;
        setState(() {
          _busy = false;
          _awaitingVerify = true;
        });
      } else {
        await AuthService.instance.signInWithEmail(email, password);
        if (!mounted) return;
        // Bei Sign-In: falls Email noch nicht verifiziert → auch Waiting-Screen
        if (!AuthService.instance.emailVerified) {
          setState(() {
            _busy = false;
            _awaitingVerify = true;
          });
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(_readableError(e), error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('Etwas ist schief gelaufen: $e', error: true);
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _busy = true);
    final verified = await AuthService.instance.refreshVerificationStatus();
    if (!mounted) return;
    setState(() => _busy = false);
    if (verified) {
      _snack('Email bestätigt ✓');
      Navigator.of(context).pop(true);
    } else {
      _snack('Noch nicht verifiziert. Check deine Mails.', error: true);
    }
  }

  Future<void> _resendVerify() async {
    try {
      await AuthService.instance.resendVerificationEmail();
      _snack('Mail nochmal geschickt.');
    } catch (e) {
      _snack('Fehler beim Senden: $e', error: true);
    }
  }

  String _readableError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email ist schon registriert. Wechsle zu "Sign in".';
      case 'invalid-email':
        return 'Ungültiges Email-Format.';
      case 'weak-password':
        return 'Passwort ist zu schwach (min. 6 Zeichen).';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Email oder Passwort falsch.';
      case 'operation-not-allowed':
        return 'Email/Password ist noch nicht aktiviert — Firebase Console → Authentication → Sign-in method.';
      case 'network-request-failed':
        return 'Kein Internet.';
      case 'credential-already-in-use':
        return 'Dieser Account existiert schon — nutz "Sign in".';
      default:
        return 'Fehler: ${e.code}';
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Gib zuerst deine Email ein.', error: true);
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(email);
      _snack('Reset-Mail gesendet an $email.');
    } on FirebaseAuthException catch (e) {
      _snack(_readableError(e), error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.coralDeep : AppColors.ink,
        content: Text(msg,
            style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_awaitingVerify) return _buildVerifyState();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(_signUp ? 'CREATE ACCOUNT' : 'SIGN IN',
            style: grotesk(
                size: 14, weight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          children: [
            Text('YOUR ACCOUNT',
                style: kicker(color: AppColors.textFaint, letterSpacing: 1.7)),
            const SizedBox(height: 10),
            Text(
              _signUp ? 'Save your\nprogress.' : 'Welcome\nback.',
              style: anton(size: 32, height: 1),
            ),
            const SizedBox(height: 10),
            Text(
              widget.intent ??
                  (_signUp
                      ? 'Ein Account behält deine Streaks, Übungen und Pro-Sub auch nach Reinstall oder Handywechsel.'
                      : 'Melde dich an um deinen Fortschritt zu holen.'),
              style: grotesk(
                size: 14,
                color: AppColors.textMuted,
                weight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Email'),
            const SizedBox(height: 8),
            _field(_email, 'you@domain.com',
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _sectionTitle('Password'),
            const SizedBox(height: 8),
            _field(_password, 'min. 6 chars', obscure: true),
            const SizedBox(height: 20),
            StickerButton(
              onPressed: _busy ? null : _submit,
              fill: AppColors.coral,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                _busy ? '…' : (_signUp ? 'CREATE ACCOUNT' : 'SIGN IN'),
                style: grotesk(
                  size: 16,
                  color: AppColors.cream,
                  weight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!_signUp)
              TextButton(
                onPressed: _busy ? null : _forgotPassword,
                child: Text('Forgot password?',
                    style: grotesk(
                      size: 13,
                      color: AppColors.textMuted,
                      weight: FontWeight.w600,
                    )),
              ),
            Center(
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _signUp = !_signUp),
                child: Text.rich(
                  TextSpan(
                    text: _signUp
                        ? 'Already have an account?  '
                        : 'New here?  ',
                    style: grotesk(
                      size: 13,
                      color: AppColors.textMuted,
                      weight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: _signUp ? 'Sign in' : 'Create account',
                        style: grotesk(
                          size: 13,
                          color: AppColors.coral,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyState() {
    final email = _email.text.trim();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('CHECK YOUR EMAIL',
            style: grotesk(
                size: 14, weight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('EMAIL VERIFICATION',
                  style: kicker(
                      color: AppColors.textFaint, letterSpacing: 1.7)),
              const SizedBox(height: 10),
              Text('Almost\nthere.',
                  style: anton(size: 32, height: 1)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ink, width: 2.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mark_email_read,
                            color: AppColors.coral, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            email.isEmpty ? 'deine Email' : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: grotesk(
                              size: 15,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Wir haben dir einen Bestätigungs-Link geschickt. '
                      'Öffne die Mail und klick den Link — danach kannst du '
                      'unten auf "Ich habe verifiziert" tippen.',
                      style: grotesk(
                        size: 13,
                        color: AppColors.textMuted,
                        weight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StickerButton(
                onPressed: _busy ? null : _checkVerified,
                fill: AppColors.coral,
                radius: 16,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(_busy ? '…' : 'ICH HABE VERIFIZIERT',
                    style: grotesk(
                      size: 15,
                      color: AppColors.cream,
                      weight: FontWeight.w800,
                      letterSpacing: 1.4,
                    )),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : _resendVerify,
                child: Text('Mail nochmal schicken',
                    style: grotesk(
                      size: 13,
                      color: AppColors.textMuted,
                      weight: FontWeight.w600,
                    )),
              ),
              const Spacer(),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text('Später',
                    style: grotesk(
                      size: 13,
                      color: AppColors.textFaint,
                      weight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String s) => Text(
        s.toUpperCase(),
        style: kicker(color: AppColors.textFaint, letterSpacing: 1.7),
      );

  Widget _field(TextEditingController c, String hint,
      {bool obscure = false, TextInputType keyboard = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        style: grotesk(size: 16, weight: FontWeight.w700),
        cursorColor: AppColors.coral,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: grotesk(
            size: 16,
            color: AppColors.textFaint,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
