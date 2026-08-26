import 'package:flutter/material.dart';

import '../models/call_log.dart';
import '../models/lobby.dart';
import '../models/user_settings.dart';
import '../services/call_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'stats_screen.dart';
import 'story_replay_screen.dart';

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    onReplayTap: _replayStory,
                    onStatsTap: _openStats,
                    accent: inLobby ? AppColors.purple : AppColors.coral,
                  ),
                  if (inLobby) ...[
                    const SizedBox(height: 12),
                    _GroupModeBanner(lobbyName: lobbyName ?? 'Group'),
                  ],
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: CallState.instance,
                    builder: (_, _) => CallState.instance.isActive
                        ? _ActiveCallCard(
                            onConfirm: _confirmCall, inLobby: inLobby)
                        : _IdleHeroCard(inLobby: inLobby),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: CallLog.instance,
                    builder: (_, _) => _TodayStatsRow(
                      calls: CallLog.instance.callsToday,
                      aced: CallLog.instance.acedToday,
                      accent:
                          inLobby ? AppColors.purple : AppColors.amber,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("TODAY'S CALLS",
                      style: kicker(
                          color: AppColors.textFaint, letterSpacing: 1.7)),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: CallLog.instance,
                    builder: (_, _) {
                      final today = CallLog.instance.today;
                      if (today.isEmpty) return const _EmptyCallState();
                      return Column(
                        children: [
                          for (final e in today) ...[
                            _CallRow(entry: e),
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onReplayTap;
  final VoidCallback onStatsTap;
  final Color accent;
  const _Header({
    required this.onReplayTap,
    required this.onStatsTap,
    required this.accent,
  });

  Widget _iconTile({
    required IconData icon,
    required VoidCallback onTap,
    Color fill = AppColors.white,
    Color iconColor = AppColors.ink,
  }) {
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
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ink, width: 2.5),
              ),
              child: Text('Y',
                  style: grotesk(
                      size: 16,
                      color: Colors.white,
                      weight: FontWeight.w700)),
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
        boxShadow: const [
          BoxShadow(
              color: AppColors.ink, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_2, color: AppColors.cream, size: 18),
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

class _IdleHeroCard extends StatelessWidget {
  final bool inLobby;
  const _IdleHeroCard({required this.inLobby});

  @override
  Widget build(BuildContext context) {
    final shadow = inLobby ? AppColors.purple : AppColors.shadowWarm;
    final kickerColor = inLobby ? AppColors.purple : AppColors.amber;
    return Sticker(
      fill: AppColors.ink,
      shadowColor: shadow,
      radius: 24,
      shadowOffset: 6,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(inLobby ? 'GROUP · RIGHT NOW' : 'RIGHT NOW',
              style: kicker(color: kickerColor, letterSpacing: 2.8)),
          const SizedBox(height: 10),
          Text("You're\nupright ✓",
              style: anton(size: 36, color: AppColors.cream, height: 0.95)),
          const SizedBox(height: 12),
          Text(
            inLobby
                ? "Waiting for the next crew call. Someone can trigger it any time."
                : "Next call: sometime today. You'll know when.",
            style: grotesk(
              size: 14,
              color: AppColors.cream.withValues(alpha: 0.72),
              weight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCallCard extends StatelessWidget {
  final VoidCallback onConfirm;
  final bool inLobby;
  const _ActiveCallCard({required this.onConfirm, required this.inLobby});

  @override
  Widget build(BuildContext context) {
    final c = CallState.instance.current!;
    final left = c.secondsLeft;
    return Sticker(
      fill: AppColors.coralDeep,
      shadowColor: inLobby ? AppColors.purple : AppColors.ink,
      radius: 24,
      shadowOffset: 6,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(inLobby ? 'CREW CALL' : 'CALL INCOMING',
                  style: kicker(color: Colors.white, letterSpacing: 2.8)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.ink, width: 2.5),
                ),
                child: Text('${left}s',
                    style: grotesk(
                      size: 14,
                      weight: FontWeight.w800,
                      color: AppColors.ink,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('STRAIGHT\nGUYS!',
              style: anton(size: 44, color: AppColors.cream, height: 0.92)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: left / c.windowSeconds,
              minHeight: 8,
              color: AppColors.amber,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 16),
          StickerButton(
            onPressed: onConfirm,
            fill: AppColors.cream,
            radius: 14,
            shadowOffset: 4,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "I'M STRAIGHT ✓",
              style: grotesk(
                size: 18,
                color: AppColors.coralDeep,
                weight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
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
  final Color accent;
  const _TodayStatsRow({
    required this.calls,
    required this.aced,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
                number: '$calls', label: 'calls today', color: AppColors.ink),
          ),
          Container(
              width: 1.5,
              height: 34,
              color: AppColors.ink.withValues(alpha: 0.15)),
          Expanded(
            child: _MiniStat(number: '$aced', label: 'aced', color: accent),
          ),
        ],
      ),
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
  const _CallRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final aced = entry.result == CallResult.aced;
    final color = aced ? AppColors.teal : AppColors.bronze;
    final group = entry.mode == AppMode.group;
    return Container(
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
            child: Row(
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
          ),
          Text(
            aced ? 'Aced · ${entry.responseSeconds}s' : 'Missed 😬',
            style: grotesk(size: 13, color: color, weight: FontWeight.w600),
          ),
        ],
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
      shadowOffset: 4,
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
