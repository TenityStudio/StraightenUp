import 'package:flutter/material.dart';

import '../data/exercises.dart';
import '../models/exercise.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'exercise_choice_screen.dart';

/// „Wo bist du gerade?" — Kontext wählen, damit passende Übungen kommen.
class ExerciseContextScreen extends StatelessWidget {
  const ExerciseContextScreen({super.key});

  bool get _isPro => SubscriptionService.instance.isPro;

  Future<void> _pick(BuildContext context, ExerciseContext ctx) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ExerciseChoiceScreen(context: ctx),
      ),
    );
    if (result != null && context.mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SubscriptionService.instance,
      builder: (_, _) => _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('EXERCISE',
            style: grotesk(
                size: 15, weight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('WHERE ARE YOU?',
                  style: kicker(
                      color: AppColors.textFaint, letterSpacing: 1.7)),
              const SizedBox(height: 10),
              Text('Pick your spot,\nget the right move.',
                  style: anton(size: 32, height: 1)),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  children: [
                    for (final ctx in ExerciseContext.values) ...[
                      _ContextTile(
                        ctx: ctx,
                        count: exercisesFor(ctx, pro: _isPro).length,
                        onTap: () => _pick(context, ctx),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Skip this time',
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
  }
}

class _ContextTile extends StatelessWidget {
  final ExerciseContext ctx;
  final int count;
  final VoidCallback onTap;
  const _ContextTile({
    required this.ctx,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: Text(ctx.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ctx.label,
                      style: kicker(
                          color: AppColors.textFaint, letterSpacing: 1.7)),
                  const SizedBox(height: 4),
                  Text('$count exercise${count == 1 ? '' : 's'}',
                      style: anton(size: 20, height: 1)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: AppColors.ink, size: 22),
          ],
        ),
      ),
    );
  }
}
