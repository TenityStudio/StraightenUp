import 'package:flutter/material.dart';

import '../../models/survey.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bent_figure.dart';
import '../../widgets/sticker.dart';

typedef SurveyDoneCallback = Future<void> Function(SurveyResult result);

class SurveyFlow extends StatefulWidget {
  final SurveyDoneCallback onDone;
  const SurveyFlow({super.key, required this.onDone});

  @override
  State<SurveyFlow> createState() => _SurveyFlowState();
}

class _SurveyFlowState extends State<SurveyFlow> {
  int _step = 0;
  SurveyResult _result = const SurveyResult();

  void _advance(SurveyResult r) {
    setState(() {
      _result = r;
      _step++;
    });
  }

  Future<void> _finish(SurveyResult r) async {
    setState(() => _result = r);
    final finished = r.copyWith(completedAt: DateTime.now());
    await widget.onDone(finished);
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      QuickIntroScreen(onNext: () => setState(() => _step++)),
      ActivityQuestion(
        initial: _result.activities,
        onNext: (v) => _advance(_result.copyWith(activities: v)),
      ),
      NeckSeverityQuestion(
        initial: _result.neckSeverity,
        onNext: (v) => _advance(_result.copyWith(neckSeverity: v)),
      ),
      PainQuestion(
        initial: _result.painFrequency,
        onNext: (v) => _advance(_result.copyWith(painFrequency: v)),
      ),
      GoalsQuestion(
        initial: _result.goals,
        onNext: (v) => _finish(_result.copyWith(goals: v)),
      ),
    ];
    final total = screens.length;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
              child: Row(
                children: [
                  for (var i = 0; i < total; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              i <= _step ? AppColors.coral : AppColors.dashedDivider,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                      ),
                    ),
                    if (i < total - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: screens[_step.clamp(0, total - 1)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Q0: quick heads-up ─────────────────────────────────────────────────────

class QuickIntroScreen extends StatelessWidget {
  final VoidCallback onNext;
  const QuickIntroScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KickerPill(text: '4 QUICK Q'),
          const SizedBox(height: 18),
          Text('Where are\nyou at?',
              style: anton(size: 42, height: 0.95)),
          const SizedBox(height: 14),
          Text(
            'Four short questions so we can call you at the right times — and later suggest exercises that actually fit your day.',
            style: grotesk(
              size: 16,
              color: AppColors.textMuted,
              weight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const Spacer(),
          const Center(child: _ThinkingFigure()),
          const Spacer(),
          StickerButton(
            onPressed: onNext,
            fill: AppColors.coral,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('LET’S GO →',
                style: grotesk(
                  size: 18,
                  color: AppColors.cream,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                )),
          ),
        ],
      ),
    );
  }
}

class _ThinkingFigure extends StatefulWidget {
  const _ThinkingFigure();
  @override
  State<_ThinkingFigure> createState() => _ThinkingFigureState();
}

class _ThinkingFigureState extends State<_ThinkingFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => BentFigure(severity: 0.15 + 0.5 * _c.value, size: 240),
    );
  }
}

// ─── Q1: activity (multi-select) ────────────────────────────────────────────

class ActivityQuestion extends StatefulWidget {
  final Set<DailyActivity> initial;
  final ValueChanged<Set<DailyActivity>> onNext;
  const ActivityQuestion({
    super.key,
    required this.initial,
    required this.onNext,
  });

  @override
  State<ActivityQuestion> createState() => _ActivityQuestionState();
}

class _ActivityQuestionState extends State<ActivityQuestion> {
  late final Set<DailyActivity> _picked = {...widget.initial};

  void _toggle(DailyActivity a) {
    setState(() {
      _picked.contains(a) ? _picked.remove(a) : _picked.add(a);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KickerPill(text: 'Q1 · YOUR DAY'),
          const SizedBox(height: 14),
          Text('What are you\ndoing all day?',
              style: anton(size: 36, height: 0.95)),
          const SizedBox(height: 8),
          Text('Pick everything that fits. Multiple ok.',
              style: grotesk(
                size: 14,
                color: AppColors.textFaint,
                weight: FontWeight.w500,
              )),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                for (final a in DailyActivity.values)
                  _ActivityTile(
                    activity: a,
                    selected: _picked.contains(a),
                    onTap: () => _toggle(a),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          StickerButton(
            onPressed: _picked.isEmpty ? null : () => widget.onNext(_picked),
            fill: _picked.isEmpty ? AppColors.dashedDivider : AppColors.coral,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('NEXT →',
                style: grotesk(
                  size: 18,
                  color: AppColors.cream,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                )),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final DailyActivity activity;
  final bool selected;
  final VoidCallback onTap;
  const _ActivityTile({
    required this.activity,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink,
              offset: selected ? const Offset(2, 2) : const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1,
              duration: const Duration(milliseconds: 200),
              child: Text(activity.emoji,
                  style: const TextStyle(fontSize: 28)),
            ),
            const Spacer(),
            Text(activity.label,
                style: grotesk(
                  size: 14,
                  weight: FontWeight.w800,
                  color: selected ? AppColors.cream : AppColors.ink,
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Q2: neck severity (slider + animated figure) ───────────────────────────

class NeckSeverityQuestion extends StatefulWidget {
  final double initial;
  final ValueChanged<double> onNext;
  const NeckSeverityQuestion({
    super.key,
    required this.initial,
    required this.onNext,
  });

  @override
  State<NeckSeverityQuestion> createState() => _NeckSeverityQuestionState();
}

class _NeckSeverityQuestionState extends State<NeckSeverityQuestion> {
  late double _v = widget.initial;

  String get _label {
    if (_v < 0.15) return 'Basically fine';
    if (_v < 0.35) return 'A little stiff';
    if (_v < 0.55) return "Feels the day";
    if (_v < 0.75) return 'Concerning';
    if (_v < 0.92) return 'Send help';
    return 'One with the floor';
  }

  Color get _labelColor {
    if (_v < 0.34) return AppColors.teal;
    if (_v < 0.67) return AppColors.amber;
    return AppColors.coralDeep;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KickerPill(text: 'Q2 · YOUR NECK'),
          const SizedBox(height: 14),
          Text('How gone is\nyour neck?',
              style: anton(size: 36, height: 0.95)),
          const SizedBox(height: 8),
          Text('Slide right until the figure matches you.',
              style: grotesk(
                size: 14,
                color: AppColors.textFaint,
                weight: FontWeight.w500,
              )),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: _v, end: _v),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                builder: (_, v, _) => BentFigure(severity: v, size: 260),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                _label,
                key: ValueKey(_label),
                style: anton(size: 30, color: _labelColor, height: 1),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.ink,
              inactiveTrackColor: AppColors.dashedDivider,
              thumbColor: AppColors.coral,
              overlayColor: Colors.transparent,
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _v,
              onChanged: (v) => setState(() => _v = v),
            ),
          ),
          const SizedBox(height: 12),
          StickerButton(
            onPressed: () => widget.onNext(_v),
            fill: AppColors.coral,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('NEXT →',
                style: grotesk(
                  size: 18,
                  color: AppColors.cream,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Q3: pain frequency (single-select cards) ───────────────────────────────

class PainQuestion extends StatefulWidget {
  final PainFrequency? initial;
  final ValueChanged<PainFrequency> onNext;
  const PainQuestion({
    super.key,
    required this.initial,
    required this.onNext,
  });

  @override
  State<PainQuestion> createState() => _PainQuestionState();
}

class _PainQuestionState extends State<PainQuestion> {
  late PainFrequency? _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KickerPill(text: 'Q3 · PAIN'),
          const SizedBox(height: 14),
          Text('Does it hurt?',
              style: anton(size: 40, height: 0.95)),
          const SizedBox(height: 8),
          Text('Be honest. Nobody but the app is watching.',
              style: grotesk(
                size: 14,
                color: AppColors.textFaint,
                weight: FontWeight.w500,
              )),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: PainFrequency.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final p = PainFrequency.values[i];
                final selected = _picked == p;
                return GestureDetector(
                  onTap: () => setState(() => _picked = p),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.ink : AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.ink, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: selected
                              ? const Offset(2, 2)
                              : const Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.coral : AppColors.cream,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.ink, width: 2),
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  size: 16, color: AppColors.cream)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.label,
                                  style: grotesk(
                                    size: 18,
                                    weight: FontWeight.w800,
                                    color: selected
                                        ? AppColors.cream
                                        : AppColors.ink,
                                  )),
                              const SizedBox(height: 2),
                              Text(p.hint,
                                  style: grotesk(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: selected
                                        ? AppColors.cream
                                            .withValues(alpha: 0.7)
                                        : AppColors.textMuted,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          StickerButton(
            onPressed: _picked == null
                ? null
                : () => widget.onNext(_picked!),
            fill: _picked == null ? AppColors.dashedDivider : AppColors.coral,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('NEXT →',
                style: grotesk(
                  size: 18,
                  color: AppColors.cream,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Q4: goals (multi-select chips) ─────────────────────────────────────────

class GoalsQuestion extends StatefulWidget {
  final Set<Goal> initial;
  final ValueChanged<Set<Goal>> onNext;
  const GoalsQuestion({
    super.key,
    required this.initial,
    required this.onNext,
  });

  @override
  State<GoalsQuestion> createState() => _GoalsQuestionState();
}

class _GoalsQuestionState extends State<GoalsQuestion> {
  late final Set<Goal> _picked = {...widget.initial};

  void _toggle(Goal g) {
    setState(() {
      _picked.contains(g) ? _picked.remove(g) : _picked.add(g);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KickerPill(text: 'Q4 · GOAL'),
          const SizedBox(height: 14),
          Text('What do you\nwant out of it?',
              style: anton(size: 36, height: 0.95)),
          const SizedBox(height: 8),
          Text("Pick what matters. We'll steer the app that way.",
              style: grotesk(
                size: 14,
                color: AppColors.textFaint,
                weight: FontWeight.w500,
              )),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                for (final g in Goal.values)
                  _GoalChip(
                    goal: g,
                    selected: _picked.contains(g),
                    onTap: () => _toggle(g),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          StickerButton(
            onPressed: _picked.isEmpty ? null : () => widget.onNext(_picked),
            fill: _picked.isEmpty ? AppColors.dashedDivider : AppColors.coral,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('FINISH ✓',
                style: grotesk(
                  size: 18,
                  color: AppColors.cream,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                )),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final Goal goal;
  final bool selected;
  final VoidCallback onTap;
  const _GoalChip({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink,
              offset:
                  selected ? const Offset(2, 2) : const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(goal.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(goal.label,
                style: grotesk(
                  size: 15,
                  weight: FontWeight.w800,
                  color: AppColors.ink,
                )),
          ],
        ),
      ),
    );
  }
}
