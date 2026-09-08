import 'dart:math';

import 'package:flutter/material.dart';

import '../data/exercises.dart';
import '../models/exercise.dart';
import '../services/exercise_history.dart';
import '../services/remote_exercises.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'exercise_player_screen.dart';
import 'pro_plan_screen.dart';

const _slotsPerPool = 2;

/// Zeigt für einen Kontext bis zu 2 Free + 2 Pro Übungen an, zufällig gewählt.
/// Bereits abgeschlossene Übungen (siehe [ExerciseHistory]) werden aus dem
/// Pool gefiltert bis der Pool zu klein wird → dann automatisch Reset.
/// Beim Klick auf eine Pro-Übung als Free-User → Paywall-Hinweis.
class ExerciseChoiceScreen extends StatefulWidget {
  final ExerciseContext context;
  const ExerciseChoiceScreen({
    super.key,
    required this.context,
  });

  @override
  State<ExerciseChoiceScreen> createState() => _ExerciseChoiceScreenState();
}

class _ExerciseChoiceScreenState extends State<ExerciseChoiceScreen> {
  List<Exercise> _free = const [];
  List<Exercise> _locked = const [];

  @override
  void initState() {
    super.initState();
    _pickRandom();
    RemoteExerciseStore.instance.addListener(_onRemoteChanged);
  }

  @override
  void dispose() {
    RemoteExerciseStore.instance.removeListener(_onRemoteChanged);
    super.dispose();
  }

  void _onRemoteChanged() {
    // Wenn Firestore neue Pro-Übungen liefert, Auswahl neu würfeln.
    _pickRandom();
  }

  Future<void> _pickRandom() async {
    final history = ExerciseHistory.instance;
    final allFree = exercisesFor(widget.context, pro: false);
    final allLocked =
        exercisesFor(widget.context, pro: true).where((e) => e.isPro).toList();

    final free = await _pickFromPool(allFree, history);
    final locked = await _pickFromPool(allLocked, history);
    if (!mounted) return;
    setState(() {
      _free = free;
      _locked = locked;
    });
  }

  Future<List<Exercise>> _pickFromPool(
      List<Exercise> pool, ExerciseHistory history) async {
    if (pool.isEmpty) return const [];
    // Erste Runde: rausfiltern was schon gemacht wurde
    var remaining = pool.where((e) => !history.wasDone(e.id)).toList();
    // Wenn Pool zu klein wurde → dessen History-Einträge vergessen und neu ziehen
    if (remaining.length < _slotsPerPool) {
      await history.forget(pool.map((e) => e.id));
      remaining = List<Exercise>.from(pool);
    }
    remaining.shuffle(Random());
    return remaining.take(_slotsPerPool).toList();
  }

  Future<void> _open(BuildContext ctx, Exercise e) async {
    if (e.isPro && !SubscriptionService.instance.isPro) {
      _showPaywall(ctx);
      return;
    }
    final result = await Navigator.of(ctx).push<String>(
      MaterialPageRoute(builder: (_) => ExercisePlayerScreen(exercise: e)),
    );
    if (result != null) {
      await ExerciseHistory.instance.markDone(result);
      if (ctx.mounted) Navigator.of(ctx).pop(result);
    }
  }

  void _showPaywall(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
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
            Text('PRO', style: kicker(color: AppColors.coral, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('More moves,\nmore options.',
                style: anton(size: 28, height: 1)),
            const SizedBox(height: 12),
            Text(
              'Unlock every exercise, all contexts, new drops every week.',
              style: grotesk(
                size: 14,
                color: AppColors.textMuted,
                weight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            StickerButton(
              onPressed: () {
                Navigator.of(sheetCtx).pop();
                Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => ProPlanScreen(),
                  ),
                );
              },
              fill: AppColors.coral,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('SEE PRO PLANS',
                  style: grotesk(
                    size: 15,
                    color: AppColors.cream,
                    weight: FontWeight.w800,
                    letterSpacing: 1.4,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SubscriptionService.instance,
      builder: (_, _) => _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final isPro = SubscriptionService.instance.isPro;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(widget.context.label,
            style: grotesk(
                size: 15, weight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 30),
          children: [
            Text('PICK ONE',
                style: kicker(color: AppColors.textFaint, letterSpacing: 1.7)),
            const SizedBox(height: 10),
            for (final e in _free) ...[
              _ExerciseTile(
                  exercise: e, locked: false, onTap: () => _open(context, e)),
              const SizedBox(height: 12),
            ],
            if (_locked.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('PRO',
                      style:
                          kicker(color: AppColors.coral, letterSpacing: 1.7)),
                  const SizedBox(width: 8),
                  if (!isPro)
                    Icon(Icons.lock, size: 14, color: AppColors.coral),
                ],
              ),
              const SizedBox(height: 10),
              for (final e in _locked) ...[
                _ExerciseTile(
                    exercise: e,
                    locked: !isPro,
                    onTap: () => _open(context, e)),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final bool locked;
  final VoidCallback onTap;
  const _ExerciseTile({
    required this.exercise,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: locked ? AppColors.chipCool1 : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(exercise.title,
                          style: anton(size: 22, height: 1)),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.lock,
                            size: 16, color: AppColors.coral),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(exercise.subtitle,
                      style: grotesk(
                        size: 13,
                        color: AppColors.textMuted,
                        weight: FontWeight.w500,
                        height: 1.35,
                      )),
                  const SizedBox(height: 8),
                  Text('${exercise.seconds}s · ${exercise.steps.length} steps',
                      style: grotesk(
                        size: 11,
                        color: AppColors.textFaint,
                        weight: FontWeight.w700,
                        letterSpacing: 1.2,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(locked ? Icons.lock : Icons.play_arrow_rounded,
                color: AppColors.ink, size: 26),
          ],
        ),
      ),
    );
  }
}
