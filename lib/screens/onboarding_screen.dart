import 'package:flutter/material.dart';

import '../models/survey.dart';
import '../models/user_settings.dart';
import 'explainer_screen.dart';
import 'main_shell.dart';
import 'mode_choice_screen.dart';
import 'popup_ambush_screen.dart';
import 'story_screen.dart';
import 'survey/survey_flow.dart';

class OnboardingFlow extends StatefulWidget {
  final UserSettings settings;
  const OnboardingFlow({super.key, required this.settings});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;
  // 0 story1, 1 story2, 2 popup, 3 explainer, 4 survey, 5 mode

  void _next() => setState(() => _step++);

  Future<void> _saveSurvey(SurveyResult r) async {
    await SurveyStore.instance.save(r);
    if (mounted) setState(() => _step++);
  }

  Future<void> _pick(AppMode mode) async {
    await widget.settings.setMode(mode);
    await widget.settings.setOnboarded(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(settings: widget.settings)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: switch (_step) {
          0 => StoryScreen(index: 0, onNext: _next),
          1 => StoryScreen(index: 1, onNext: _next),
          2 => PopupAmbushScreen(onConfirm: _next),
          3 => ExplainerScreen(onNext: _next),
          4 => SurveyFlow(onDone: _saveSurvey),
          _ => ModeChoiceScreen(
              onChoose: _pick,
              onJoinCode: () => _pick(AppMode.group),
            ),
        },
      ),
    );
  }
}
