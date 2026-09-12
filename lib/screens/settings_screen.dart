import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/call_log.dart';
import '../models/lobby.dart';
import '../models/survey.dart';
import '../models/user_settings.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import '../config/legal_urls.dart';
import '../data/pro_exercises_seed.dart';
import '../services/auth_service.dart';
import '../services/exercise_history.dart';
import '../services/remote_exercises.dart';
import '../services/subscription_service.dart';
import '../theme/palettes.dart';
import 'exercise_context_screen.dart';
import 'pro_plan_screen.dart';
import 'pro_settings_screen.dart';
import 'sign_in_screen.dart';
import 'survey/survey_flow.dart';

class SettingsScreen extends StatefulWidget {
  final UserSettings settings;
  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _start = widget.settings.windowStartHour;
  late int _end = widget.settings.windowEndHour;
  late int _perDay = widget.settings.perDay;

  Future<void> _save() async {
    await widget.settings.setSchedule(start: _start, end: _end, perDay: _perDay);
    final inLobby = LobbyStore.instance.inLobby;
    if (inLobby) {
      // Im Group-Mode kommen die Calls über FCM aus der Cloud Function.
      // Keine lokalen Solo-Reminder — sonst würde man doppelt gebimmelt.
      await NotificationService.instance.cancelAll();
    } else {
      await NotificationService.instance.scheduleRandomDaily(
        startHour: _start,
        endHour: _end,
        perDay: _perDay,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(
          inLobby
              ? 'Saved. Solo reminders paused (group mode active).'
              : 'Saved & rescheduled.',
          style: grotesk(color: AppColors.cream, weight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('SETTINGS',
            style: grotesk(
                size: 15,
                weight: FontWeight.w700,
                letterSpacing: 2)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
          children: [
            AnimatedBuilder(
              animation: SubscriptionService.instance,
              builder: (_, _) => _ProSettingsButton(),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Frequency'),
            const SizedBox(height: 8),
            Sticker(
              fill: AppColors.white,
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.coral,
                        inactiveTrackColor: AppColors.chipCool2,
                        thumbColor: AppColors.ink,
                        overlayColor: Colors.transparent,
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: _perDay.toDouble(),
                        min: 1,
                        max: 8,
                        divisions: 7,
                        label: '$_perDay×',
                        onChanged: (v) => setState(() => _perDay = v.round()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$_perDay×',
                      style: anton(size: 24)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Window'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _hourField('From', _start, (v) => setState(() => _start = v))),
                const SizedBox(width: 14),
                Expanded(child: _hourField('To', _end, (v) => setState(() => _end = v))),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('About you'),
            const SizedBox(height: 8),
            StickerButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (surveyCtx) => Scaffold(
                      backgroundColor: AppColors.cream,
                      body: SurveyFlow(
                        onDone: (r) async {
                          await SurveyStore.instance.save(r);
                          if (surveyCtx.mounted) {
                            Navigator.of(surveyCtx).pop();
                          }
                        },
                      ),
                    ),
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.ink,
                    content: Text('Survey updated.',
                        style: grotesk(
                            color: AppColors.cream,
                            weight: FontWeight.w600)),
                  ),
                );
              },
              fill: AppColors.white,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('RETAKE THE 4-Q SURVEY',
                  style: grotesk(
                    size: 15,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 1.4,
                  )),
            ),
            const SizedBox(height: 32),
            StickerButton(
              onPressed: _save,
              fill: AppColors.coral,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text('SAVE',
                  style: grotesk(
                    size: 18,
                    color: AppColors.cream,
                    weight: FontWeight.w700,
                    letterSpacing: 2,
                  )),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Debug'),
            const SizedBox(height: 8),
            StickerButton(
              onPressed: () async {
                await NotificationService.instance.triggerTestCallNow();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.ink,
                    content: Text(
                      'Call triggered — 10s to confirm on Home.',
                      style: grotesk(
                          color: AppColors.cream, weight: FontWeight.w600),
                    ),
                  ),
                );
              },
              fill: AppColors.amber,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('TRIGGER TEST CALL NOW',
                  style: grotesk(
                    size: 15,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 1.4,
                  )),
            ),
            const SizedBox(height: 10),
            StickerButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const ExerciseContextScreen(),
                  ),
                );
              },
              fill: AppColors.teal,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('TRIGGER TEST CALL + EXERCISE',
                  style: grotesk(
                    size: 15,
                    weight: FontWeight.w800,
                    color: AppColors.cream,
                    letterSpacing: 1.4,
                  )),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Pro exercises (Firestore)'),
            const SizedBox(height: 8),
            StickerButton(
              onPressed: () async {
                try {
                  final n = await RemoteExerciseStore.instance
                      .seedExercises(proExercisesSeed);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.ink,
                      content: Text('$n Pro-Übungen in Firestore geschrieben.',
                          style: grotesk(
                              color: AppColors.cream,
                              weight: FontWeight.w600)),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.coralDeep,
                      content: Text('Seed fehlgeschlagen: $e',
                          style: grotesk(
                              color: AppColors.cream,
                              weight: FontWeight.w600)),
                    ),
                  );
                }
              },
              fill: AppColors.purple,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('SEED PRO EXERCISES → FIRESTORE',
                  style: grotesk(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppColors.cream,
                    letterSpacing: 1.3,
                  )),
            ),
            const SizedBox(height: 10),
            StickerButton(
              onPressed: () async {
                await ExerciseHistory.instance.resetAll();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.ink,
                    content: Text('Exercise-History zurückgesetzt.',
                        style: grotesk(
                            color: AppColors.cream, weight: FontWeight.w600)),
                  ),
                );
              },
              fill: AppColors.white,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('RESET EXERCISE HISTORY',
                  style: grotesk(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 1.3,
                  )),
            ),
            const SizedBox(height: 10),
            StickerButton(
              onPressed: () async {
                await SubscriptionService.instance.debugLogOut();
                if (!context.mounted) return;
                final isPro = SubscriptionService.instance.isPro;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.ink,
                    content: Text(
                        'RC User reset. Pro-Status jetzt: ${isPro ? "aktiv" : "aus"}',
                        style: grotesk(
                            color: AppColors.cream, weight: FontWeight.w600)),
                  ),
                );
              },
              fill: AppColors.white,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('RESET PRO / RC USER',
                  style: grotesk(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 1.3,
                  )),
            ),
            const SizedBox(height: 10),
            StickerButton(
              onPressed: () async {
                await RemoteExerciseStore.instance.refresh();
                if (!context.mounted) return;
                final n = RemoteExerciseStore.instance.current.length;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.ink,
                    content: Text('Refresh: $n Pro-Übungen aus Cloud geladen.',
                        style: grotesk(
                            color: AppColors.cream,
                            weight: FontWeight.w600)),
                  ),
                );
              },
              fill: AppColors.white,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('REFRESH FROM CLOUD',
                  style: grotesk(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 1.3,
                  )),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Group debug'),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: LobbyStore.instance,
              builder: (_, _) => _GroupDebugButtons(),
            ),
            const SizedBox(height: 12),
            StickerButton(
              onPressed: () async {
                await CallLog.instance.clearToday();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.ink,
                    content: Text(
                      "Today's calls cleared.",
                      style: grotesk(
                          color: AppColors.cream, weight: FontWeight.w600),
                    ),
                  ),
                );
              },
              fill: AppColors.white,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('CLEAR TODAY’S CALLS',
                  style: grotesk(
                    size: 15,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 1.4,
                  )),
            ),
            const SizedBox(height: 12),
            StickerButton(
              onPressed: () async {
                await NotificationService.instance.cancelAll();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.ink,
                    content: Text('All reminders paused.',
                        style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
                  ),
                );
              },
              fill: AppColors.white,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Pause all reminders',
                  style: grotesk(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  )),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: AuthService.instance,
              builder: (_, _) => AuthService.instance.hasRealAccount
                  ? _DeleteAccountButton()
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Legal'),
            const SizedBox(height: 8),
            _LegalLink(
              label: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              url: LegalUrls.privacyPolicy,
            ),
            const SizedBox(height: 10),
            _LegalLink(
              label: 'Impressum',
              icon: Icons.description_outlined,
              url: LegalUrls.impressum,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String s) => Text(
        s.toUpperCase(),
        style: kicker(color: AppColors.textFaint, letterSpacing: 1.7),
      );

  Widget _hourField(String label, int value, ValueChanged<int> onChanged) {
    return Sticker(
      fill: AppColors.white,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: grotesk(
                  size: 13,
                  color: AppColors.textFaint,
                  weight: FontWeight.w600)),
          const Spacer(),
          DropdownButton<int>(
            value: value,
            underline: const SizedBox(),
            dropdownColor: AppColors.cream,
            iconEnabledColor: AppColors.ink,
            items: List.generate(24, (h) => h)
                .map((h) => DropdownMenuItem(
                      value: h,
                      child: Text('${h.toString().padLeft(2, '0')}:00',
                          style: grotesk(size: 16, weight: FontWeight.w700)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _ProSettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isPro = SubscriptionService.instance.isPro;
    return StickerButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProSettingsScreen()),
      ),
      fill: isPro ? AppColors.ink : AppColors.chipCool1,
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPro ? Icons.workspace_premium : Icons.lock,
            color: isPro ? AppColors.amber : AppColors.coral,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text('PRO SETTINGS',
              style: grotesk(
                size: 15,
                color: isPro ? AppColors.cream : AppColors.textMuted,
                weight: FontWeight.w800,
                letterSpacing: 1.8,
              )),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(
        text: AuthService.instance.displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.ink, width: 2.5),
        ),
        title: Text('Your name', style: anton(size: 22, height: 1)),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: grotesk(size: 15, weight: FontWeight.w700),
            cursorColor: AppColors.coral,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Wie sollen wir dich nennen?',
              hintStyle: grotesk(
                size: 15,
                color: AppColors.textFaint,
                weight: FontWeight.w500,
              ),
            ),
            onSubmitted: (v) => Navigator.pop(d, v.trim()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, null),
            child: Text('Cancel',
                style: grotesk(color: AppColors.textFaint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, controller.text.trim()),
            child: Text('Save',
                style: grotesk(
                    color: AppColors.coral, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    if (result.isEmpty) return;
    try {
      await AuthService.instance.setDisplayName(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text('Name gespeichert.',
              style:
                  grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coralDeep,
          content: Text('Konnte nicht speichern: $e',
              style:
                  grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.ink, width: 2.5),
        ),
        title: Text('Sign out?', style: anton(size: 22, height: 1)),
        content: Text(
          'Du bleibst in der App als Gast. Ohne Anmeldung geht dein Pro-Abo '
          'bei Reinstall / Handywechsel verloren.',
          style: grotesk(size: 13, color: AppColors.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text('Cancel',
                style: grotesk(color: AppColors.textFaint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text('Sign out',
                style: grotesk(
                    color: AppColors.coralDeep, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await AuthService.instance.signOutToAnonymous();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final signedIn = auth.hasRealAccount;
    final verified = auth.emailVerified;
    final email = auth.email;
    final name = auth.displayName;

    final String kicker_text;
    final Color kickerColor;
    final Color iconBg;
    final IconData iconData;
    final String status;
    if (!signedIn) {
      kicker_text = 'GUEST MODE';
      kickerColor = AppColors.textFaint;
      iconBg = AppColors.amber;
      iconData = Icons.person_outline;
      status = name ?? 'Sign in to save progress';
    } else if (!verified) {
      kicker_text = 'VERIFY EMAIL';
      kickerColor = AppColors.coral;
      iconBg = AppColors.coral;
      iconData = Icons.mark_email_unread;
      status = (name?.isNotEmpty ?? false) ? '$name  ·  $email' : (email ?? 'You');
    } else {
      kicker_text = 'SIGNED IN';
      kickerColor = AppColors.teal;
      iconBg = AppColors.teal;
      iconData = Icons.check;
      status = (name?.isNotEmpty ?? false) ? '$name  ·  $email' : (email ?? 'You');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: signedIn ? AppColors.white : AppColors.chipCool1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Icon(iconData,
                color: signedIn ? AppColors.cream : AppColors.ink, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kicker_text,
                    style: kicker(color: kickerColor, letterSpacing: 1.7)),
                const SizedBox(height: 3),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: grotesk(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              if (!signedIn) {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              } else if (!verified) {
                // Verify-Flow nochmal öffnen
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              } else {
                await _signOut(context);
              }
            },
            child: Text(
              !signedIn ? 'Sign in' : (!verified ? 'Verify' : 'Sign out'),
              style: grotesk(
                size: 13,
                color: !verified ? AppColors.coral : AppColors.textMuted,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePickerRow extends StatelessWidget {
  final Palette current;
  final ValueChanged<Palette> onPick;
  const _ThemePickerRow({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final row1 = allPalettes.take(5).toList();
    final row2 = allPalettes.skip(5).take(5).toList();
    return Column(
      children: [
        _row(row1),
        const SizedBox(height: 12),
        _row(row2),
      ],
    );
  }

  Widget _row(List<Palette> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _tile(items[i])),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _tile(Palette p) {
    final selected = p.id == current.id;
    return GestureDetector(
      onTap: () => onPick(p),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: p.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: p.ink,
                  width: selected ? 3 : 1.8,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 5,
                    bottom: 5,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: p.coral,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: p.ink, width: 1.2),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: p.amber,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: p.ink, width: 1.2),
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.ink,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check,
                              color: p.cream, size: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: grotesk(
              size: 9,
              weight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.ink : AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupDebugButtons extends StatelessWidget {
  Future<void> _snack(BuildContext ctx, String msg) async {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(msg,
            style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = LobbyStore.instance;
    final inLobby = store.inLobby;
    final hasGhosts = store.ghostCount > 0;
    final liveEvent = store.lastEvent != null &&
        !(store.lastEvent!.finalized);

    return Column(
      children: [
        if (!inLobby)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Text(
              'Join or create a lobby first, then come back.',
              style: grotesk(
                size: 13,
                color: AppColors.textMuted,
                weight: FontWeight.w500,
              ),
            ),
          )
        else ...[
          StickerButton(
            onPressed: () async {
              await LobbyStore.instance.spawnGhost();
              if (!context.mounted) return;
              _snack(context,
                  'Ghost added. Members: ${LobbyStore.instance.members.length}');
            },
            fill: AppColors.purple,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('👻 SPAWN GHOST MEMBER',
                style: grotesk(
                  size: 15,
                  weight: FontWeight.w800,
                  color: AppColors.cream,
                  letterSpacing: 1.3,
                )),
          ),
          const SizedBox(height: 10),
          StickerButton(
            onPressed: liveEvent && hasGhosts
                ? () async {
                    final ok = await LobbyStore.instance
                        .ghostRespondToCurrentCall();
                    if (!context.mounted) return;
                    _snack(context,
                        ok ? 'A ghost aced it.' : 'No ghost pending.');
                  }
                : null,
            fill: liveEvent && hasGhosts
                ? AppColors.teal
                : AppColors.dashedDivider,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('👻 GHOST ACES CURRENT CALL',
                style: grotesk(
                  size: 15,
                  weight: FontWeight.w800,
                  color: liveEvent && hasGhosts
                      ? AppColors.cream
                      : AppColors.textFaint,
                  letterSpacing: 1.3,
                )),
          ),
          const SizedBox(height: 10),
          StickerButton(
            onPressed: hasGhosts
                ? () async {
                    final n = await LobbyStore.instance.removeAllGhosts();
                    if (!context.mounted) return;
                    _snack(context, 'Removed $n ghost(s).');
                  }
                : null,
            fill: AppColors.white,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text('REMOVE ALL GHOSTS',
                style: grotesk(
                  size: 14,
                  weight: FontWeight.w800,
                  color: hasGhosts ? AppColors.coralDeep : AppColors.textFaint,
                  letterSpacing: 1.3,
                )),
          ),
        ],
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final String url;
  const _LegalLink({
    required this.label,
    required this.icon,
    required this.url,
  });

  Future<void> _open() async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.ink, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: grotesk(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  )),
            ),
            Icon(Icons.open_in_new,
                size: 16, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  Future<void> _confirm(BuildContext context) async {
    final passwordController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.ink, width: 2.5),
        ),
        title: Text('Delete account?', style: anton(size: 22, height: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wir löschen deinen Account, alle deine Firestore-Daten und '
              'die Verknüpfung zu deinem Pro-Abo aus unserer Datenbank.\n\n'
              'Diese Aktion kann nicht rückgängig gemacht werden.',
              style: grotesk(
                  size: 13,
                  color: AppColors.textMuted,
                  weight: FontWeight.w500,
                  height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                style: grotesk(size: 14, weight: FontWeight.w700),
                cursorColor: AppColors.coral,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Passwort zur Bestätigung',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text('Cancel',
                style: grotesk(color: AppColors.textFaint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text('DELETE',
                style: grotesk(
                    color: AppColors.coralDeep,
                    weight: FontWeight.w800,
                    letterSpacing: 1.4)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await AuthService.instance.deleteAccount(
        password: passwordController.text.isNotEmpty
            ? passwordController.text
            : null,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text('Account gelöscht.',
              style: grotesk(
                  color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coralDeep,
          content: Text('Löschen fehlgeschlagen: $e',
              style: grotesk(
                  color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StickerButton(
      onPressed: () => _confirm(context),
      fill: AppColors.white,
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text('DELETE ACCOUNT',
          style: grotesk(
            size: 14,
            weight: FontWeight.w800,
            color: AppColors.coralDeep,
            letterSpacing: 1.4,
          )),
    );
  }
}
