import 'package:flutter/material.dart';

import '../models/call_log.dart';
import '../models/lobby.dart';
import '../models/user_settings.dart';
import '../services/auth_service.dart';
import '../services/call_state.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import '../data/exercises.dart';
import 'exercise_context_screen.dart';
import 'exercise_player_screen.dart';
import 'pro_plan_screen.dart';
import 'sign_in_screen.dart';
import 'stats_screen.dart';
import 'story_replay_screen.dart';

class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) => child;
}

class HomeScreen extends StatefulWidget {
  final UserSettings settings;
  const HomeScreen({super.key, required this.settings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastMissedAt;

  @override
  void initState() {
    super.initState();
    CallState.instance.addListener(_onCallStateChanged);
  }

  @override
  void dispose() {
    CallState.instance.removeListener(_onCallStateChanged);
    super.dispose();
  }

  AppMode get _currentMode =>
      LobbyStore.instance.inLobby ? AppMode.group : AppMode.solo;

  Future<void> _onCallStateChanged() async {
    final c = CallState.instance.current;
    if (c != null && c.expired && _lastMissedAt != c.startedAt) {
      _lastMissedAt = c.startedAt;
      await CallLog.instance.add(CallEntry(
        time: c.startedAt,
        result: CallResult.slouched,
        responseSeconds: c.windowSeconds,
        mode: _currentMode,
      ));
      await widget.settings.recordPromptShown();
      CallState.instance.clear();
    }
    if (mounted) setState(() {});
  }

  Future<void> _confirmCall() async {
    final secs = CallState.instance.confirm();
    if (secs == null) return;
    await CallLog.instance.add(CallEntry(
      time: DateTime.now(),
      result: CallResult.aced,
      responseSeconds: secs,
      mode: _currentMode,
    ));
    await widget.settings.recordPromptShown();
    await widget.settings.recordReaction();
    if (LobbyStore.instance.inLobby) {
      await LobbyStore.instance.recordYourResponse(secs);
    }
    if (mounted) setState(() {});
    if (mounted) _offerExercise();
  }

  Future<void> _offerExercise() async {
    final wants = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cream,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => PopScope(
        canPop: false,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textFaint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('BONUS',
                style: kicker(color: AppColors.coral, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Do a quick\nexercise?',
                style: anton(size: 28, height: 1)),
            const SizedBox(height: 10),
            Text(
              '30–60 sec. Pick your spot, get a matching move.',
              style: grotesk(
                size: 14,
                color: AppColors.textMuted,
                weight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            StickerButton(
              onPressed: () => Navigator.of(sheetCtx).pop(true),
              fill: AppColors.coral,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('LET\'S GO',
                  style: grotesk(
                    size: 15,
                    color: AppColors.cream,
                    weight: FontWeight.w800,
                    letterSpacing: 1.4,
                  )),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetCtx).pop(false),
              child: Text('Not now',
                  style: grotesk(
                    size: 14,
                    color: AppColors.textFaint,
                    weight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ),
      ),
    );
    if (wants == true && mounted) {
      final exerciseId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const ExerciseContextScreen(),
        ),
      );
      if (exerciseId != null) {
        await CallLog.instance.attachExerciseToLastAced(exerciseId);
      }
    }
  }

  Future<void> _replayStory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StoryReplayFlow()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openStats() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatsScreen(settings: widget.settings),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editName() async {
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
    if (result == null || result.isEmpty || !mounted) return;
    try {
      await AuthService.instance.setDisplayName(result);
    } catch (_) {}
  }

  Future<void> _openAccountSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            AuthService.instance,
            SubscriptionService.instance,
          ]),
          builder: (_, _) {
            final auth = AuthService.instance;
            final signedIn = auth.hasRealAccount;
            final verified = auth.emailVerified;
            final name = auth.displayName;
            final email = auth.email;
            final isPro = SubscriptionService.instance.isPro;

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textFaint.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    !signedIn
                        ? 'GUEST'
                        : !verified
                            ? 'VERIFY EMAIL'
                            : 'SIGNED IN',
                    style: kicker(
                      color: !signedIn
                          ? AppColors.textFaint
                          : !verified
                              ? AppColors.coral
                              : AppColors.teal,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name?.isNotEmpty == true
                        ? name!
                        : (email ?? 'Sign in to save progress'),
                    style: anton(size: 26, height: 1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (name?.isNotEmpty == true && email != null) ...[
                    const SizedBox(height: 4),
                    Text(email,
                        style: grotesk(
                          size: 13,
                          color: AppColors.textMuted,
                          weight: FontWeight.w600,
                        )),
                  ],
                  if (signedIn && verified) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          Navigator.of(sheetCtx).pop();
                          await _editName();
                        },
                        icon: Icon(Icons.edit,
                            size: 14, color: AppColors.textMuted),
                        label: Text(
                          name?.isNotEmpty == true
                              ? 'Change name'
                              : 'Set your name',
                          style: grotesk(
                            size: 12,
                            color: AppColors.textMuted,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  // Pro-Badge oder Go-Pro-Button
                  if (isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.ink, width: 2.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium,
                              color: AppColors.amber, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text("YOU'RE PRO ✓",
                                style: grotesk(
                                  size: 14,
                                  color: AppColors.cream,
                                  weight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                )),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(sheetCtx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProPlanScreen(),
                                ),
                              );
                            },
                            child: Text('Manage',
                                style: grotesk(
                                  size: 12,
                                  color: AppColors.cream,
                                  weight: FontWeight.w700,
                                )),
                          ),
                        ],
                      ),
                    )
                  else
                    StickerButton(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProPlanScreen(),
                          ),
                        );
                      },
                      fill: AppColors.ink,
                      radius: 16,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium,
                              color: AppColors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text('GO PRO',
                              style: grotesk(
                                size: 15,
                                color: AppColors.cream,
                                weight: FontWeight.w800,
                                letterSpacing: 2,
                              )),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (!signedIn || !verified)
                    StickerButton(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                        );
                      },
                      fill: AppColors.coral,
                      radius: 16,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        !signedIn ? 'SIGN IN / CREATE ACCOUNT' : 'VERIFY EMAIL',
                        style: grotesk(
                          size: 14,
                          color: AppColors.cream,
                          weight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    )
                  else
                    StickerButton(
                      onPressed: () async {
                        Navigator.of(sheetCtx).pop();
                        await AuthService.instance.signOutToAnonymous();
                      },
                      fill: AppColors.white,
                      radius: 16,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text('SIGN OUT',
                          style: grotesk(
                            size: 14,
                            color: AppColors.coralDeep,
                            weight: FontWeight.w800,
                            letterSpacing: 1.4,
                          )),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LobbyStore.instance,
      builder: (_, _) {
        final inLobby = LobbyStore.instance.inLobby;
        final lobbyName = LobbyStore.instance.current?.name;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedBuilder(
                    animation: AuthService.instance,
                    builder: (_, _) => _Header(
                      onReplayTap: _replayStory,
                      onStatsTap: _openStats,
                      onAvatarTap: _openAccountSheet,
                      accent: inLobby ? AppColors.purple : AppColors.coral,
                    ),
                  ),
                  if (inLobby) ...[
                    const SizedBox(height: 12),
                    _GroupModeBanner(lobbyName: lobbyName ?? 'Group'),
                  ],
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: CallState.instance,
                    builder: (_, _) {
                      final active = CallState.instance.isActive;
                      return _MorphCard(
                        active: active,
                        inLobby: inLobby,
                        onConfirm: _confirmCall,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: CallLog.instance,
                    builder: (_, _) => _TodayStatsRow(
                      calls: CallLog.instance.callsToday,
                      aced: CallLog.instance.acedToday,
                      streak: CallLog.instance.currentStreak,
                      accent:
                          inLobby ? AppColors.purple : AppColors.amber,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("TODAY'S CALLS",
                      style: kicker(
                          color: AppColors.textFaint, letterSpacing: 1.7)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.ink, width: 2.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AnimatedBuilder(
                        animation: CallLog.instance,
                        builder: (_, _) {
                          final today = CallLog.instance.today;
                          if (today.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: _EmptyCallState(),
                            );
                          }
                          return ScrollConfiguration(
                            behavior: const _NoOverscrollBehavior(),
                            child: ListView.separated(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: today.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                              final e = today[i];
                              final ex = e.exerciseId == null
                                  ? null
                                  : combinedCatalog.firstWhere(
                                      (x) => x.id == e.exerciseId,
                                      orElse: () => combinedCatalog.first,
                                    );
                              return _CallRow(
                                entry: e,
                                exerciseTitle: ex?.title,
                                onExerciseTap: ex == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ExercisePlayerScreen(
                                                    exercise: ex),
                                          ),
                                        ),
                              );
                            },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MorphCard extends StatelessWidget {
  final bool active;
  final bool inLobby;
  final VoidCallback onConfirm;
  const _MorphCard({
    required this.active,
    required this.inLobby,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    const dur = Duration(milliseconds: 450);
    const curve = Curves.easeInOut;
    final fill = active ? AppColors.coralDeep : AppColors.ink;
    final r = BorderRadius.circular(24);

    final body = AnimatedContainer(
      duration: dur,
      curve: curve,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: r,
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: AnimatedSwitcher(
        duration: dur,
        switchInCurve: curve,
        switchOutCurve: curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previous,
            if (current != null) current,
          ],
        ),
        child: active
            ? _ActiveContent(
                key: const ValueKey('active'), inLobby: inLobby)
            : _IdleContent(
                key: const ValueKey('idle'), inLobby: inLobby),
      ),
    );

    return GestureDetector(
      onTap: active ? onConfirm : null,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}

class _IdleContent extends StatelessWidget {
  final bool inLobby;
  const _IdleContent({super.key, required this.inLobby});
  @override
  Widget build(BuildContext context) {
    final kickerColor = inLobby ? AppColors.purple : AppColors.amber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(inLobby ? 'GROUP · RIGHT NOW' : 'RIGHT NOW',
                style: kicker(color: kickerColor, letterSpacing: 2.8)),
          ),
        ),
        const SizedBox(height: 10),
        Text("You're\nupright ✓",
            style: anton(size: 36, color: AppColors.cream, height: 0.95)),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: Text(
            inLobby
                ? "Waiting for the next crew call. Someone can trigger it any time."
                : "Next call: sometime today. You'll know when.",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: grotesk(
              size: 14,
              color: AppColors.cream.withValues(alpha: 0.72),
              weight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveContent extends StatelessWidget {
  final bool inLobby;
  const _ActiveContent({super.key, required this.inLobby});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CallState.instance,
      builder: (_, _) {
        final c = CallState.instance.current;
        final left = c?.secondsLeft ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(inLobby ? 'CREW CALL' : 'CALL INCOMING',
                      style:
                          kicker(color: AppColors.amber, letterSpacing: 2.8)),
                  Text('${left}s',
                      style: grotesk(
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.cream,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text("Straighten\nUp! ✓",
                style: anton(size: 36, color: AppColors.cream, height: 0.95)),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: Text(
                "Tap the card — you've got ${left}s.",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: grotesk(
                  size: 14,
                  color: AppColors.cream.withValues(alpha: 0.85),
                  weight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onReplayTap;
  final VoidCallback onStatsTap;
  final VoidCallback onAvatarTap;
  final Color accent;
  const _Header({
    required this.onReplayTap,
    required this.onStatsTap,
    required this.onAvatarTap,
    required this.accent,
  });

  String _initial() {
    final name = AuthService.instance.displayName;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim()[0].toUpperCase();
    }
    final email = AuthService.instance.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'Y';
  }

  Widget _iconTile({
    required IconData icon,
    required VoidCallback onTap,
    Color? fill,
    Color? iconColor,
  }) {
    fill ??= AppColors.white;
    iconColor ??= AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Good posture,',
            style: grotesk(
                size: 13,
                color: AppColors.textFaint,
                weight: FontWeight.w600)),
        Row(
          children: [
            _iconTile(icon: Icons.replay, onTap: onReplayTap),
            const SizedBox(width: 8),
            _iconTile(
              icon: Icons.bar_chart_rounded,
              onTap: onStatsTap,
              fill: AppColors.amber,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAvatarTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.ink, width: 2.5),
                ),
                child: Text(
                  _initial(),
                  style: grotesk(
                      size: 16,
                      color: Colors.white,
                      weight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupModeBanner extends StatelessWidget {
  final String lobbyName;
  const _GroupModeBanner({required this.lobbyName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_2, color: AppColors.cream, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'GROUP MODE · $lobbyName',
              style: grotesk(
                size: 13,
                weight: FontWeight.w800,
                color: AppColors.cream,
                letterSpacing: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStatsRow extends StatelessWidget {
  final int calls;
  final int aced;
  final int streak;
  final Color accent;
  const _TodayStatsRow({
    required this.calls,
    required this.aced,
    required this.streak,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
                number: '$calls', label: 'today', color: AppColors.ink),
          ),
          Container(
              width: 1.5,
              height: 34,
              color: AppColors.ink.withValues(alpha: 0.15)),
          Expanded(
            child: _MiniStat(number: '$aced', label: 'aced', color: accent),
          ),
          Container(
              width: 1.5,
              height: 34,
              color: AppColors.ink.withValues(alpha: 0.15)),
          Expanded(
            child: _StreakStat(streak: streak),
          ),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final int streak;
  const _StreakStat({required this.streak});
  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(active ? '🔥' : '💤',
            style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text('$streak',
            style: anton(
              size: 26,
              height: 1,
              color: active ? AppColors.coralDeep : AppColors.textFaint,
            )),
        const SizedBox(width: 6),
        Text(streak == 1 ? 'day' : 'days',
            style: grotesk(
              size: 12,
              color: AppColors.textMuted,
              weight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  const _MiniStat({
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(number, style: anton(size: 26, height: 1, color: color)),
        const SizedBox(width: 8),
        Text(label,
            style: grotesk(
              size: 12,
              color: AppColors.textMuted,
              weight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _CallRow extends StatelessWidget {
  final CallEntry entry;
  final String? exerciseTitle;
  final VoidCallback? onExerciseTap;
  const _CallRow({
    required this.entry,
    this.exerciseTitle,
    this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    final aced = entry.result == CallResult.aced;
    final color = aced ? AppColors.teal : AppColors.bronze;
    final group = entry.mode == AppMode.group;
    return GestureDetector(
      onTap: onExerciseTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.hhmm,
                          style: grotesk(size: 15, weight: FontWeight.w700)),
                      if (group) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('GROUP',
                              style: grotesk(
                                size: 9,
                                color: AppColors.cream,
                                weight: FontWeight.w800,
                                letterSpacing: 1,
                              )),
                        ),
                      ],
                    ],
                  ),
                  if (exerciseTitle != null) ...[
                    const SizedBox(height: 2),
                    Text(exerciseTitle!,
                        style: grotesk(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.textMuted,
                        )),
                  ],
                ],
              ),
            ),
            Text(
              aced ? 'Aced · ${entry.responseSeconds}s' : 'Missed 😬',
              style: grotesk(size: 13, color: color, weight: FontWeight.w600),
            ),
            if (onExerciseTap != null) ...[
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.ink, width: 2),
                ),
                child: Icon(Icons.play_arrow_rounded,
                    size: 20, color: AppColors.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCallState extends StatelessWidget {
  const _EmptyCallState();
  @override
  Widget build(BuildContext context) {
    return Sticker(
      fill: AppColors.white,
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Text('No calls today. Yet.',
              style: grotesk(size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'The app schedules them at random moments in your window.',
            textAlign: TextAlign.center,
            style: grotesk(size: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
