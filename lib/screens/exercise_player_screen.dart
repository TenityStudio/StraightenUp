import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_animation.dart';
import '../widgets/sticker.dart';

/// Zeigt eine Übung — Animation oben, Schritte darunter, DONE-Button.
/// Self-paced: kein Timer, der User tappt DONE wenn er fertig ist.
class ExercisePlayerScreen extends StatelessWidget {
  final Exercise exercise;
  const ExercisePlayerScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(e.title.toUpperCase(),
            style: grotesk(
                size: 15, weight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.ink, width: 2.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: e.lottieAsset != null
                      ? Lottie.asset(e.lottieAsset!, fit: BoxFit.contain)
                      : Center(child: exerciseAnimationFor(e.animationKey)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.ink, width: 2.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR PACE',
                          style: kicker(
                              color: AppColors.coral, letterSpacing: 1.7)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: e.steps.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _StepRow(
                            index: i + 1,
                            text: e.steps[i],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              StickerButton(
                onPressed: () => Navigator.of(context).pop(e.id),
                fill: AppColors.teal,
                radius: 16,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text('DONE ✓',
                    style: grotesk(
                      size: 17,
                      color: AppColors.cream,
                      weight: FontWeight.w800,
                      letterSpacing: 1.6,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String text;
  const _StepRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: Text('$index',
              style: grotesk(
                size: 12,
                weight: FontWeight.w800,
                color: AppColors.ink,
              )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: grotesk(
                size: 15,
                weight: FontWeight.w600,
                color: AppColors.ink,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

