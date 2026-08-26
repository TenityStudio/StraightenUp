import 'package:flutter/material.dart';

import 'explainer_screen.dart';
import 'popup_ambush_screen.dart';
import 'story_screen.dart';

/// Story + Popup + Explainer noch einmal anschauen. Am Ende poppt es zurück.
class StoryReplayFlow extends StatefulWidget {
  const StoryReplayFlow({super.key});

  @override
  State<StoryReplayFlow> createState() => _StoryReplayFlowState();
}

class _StoryReplayFlowState extends State<StoryReplayFlow> {
  int _step = 0;

  void _next() {
    if (_step >= 3) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step++);
    }
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
          _ => ExplainerScreen(onNext: _next),
        },
      ),
    );
  }
}
