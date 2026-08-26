import 'package:flutter/material.dart';

import '../models/call_log.dart';
import '../models/lobby.dart';
import '../models/survey.dart';
import '../models/user_settings.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
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
            _sectionTitle('Frequency'),
            const SizedBox(height: 8),
            Sticker(
              fill: AppColors.white,
              radius: 16,
              shadowOffset: 4,
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
      shadowOffset: 4,
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
