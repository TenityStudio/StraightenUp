import 'package:flutter/material.dart';

import '../models/lobby.dart';
import '../models/user_settings.dart';
import '../theme/app_theme.dart';
import 'group_mode_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  final UserSettings settings;
  final int initialTab;
  const MainShell({super.key, required this.settings, this.initialTab = 1});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const GroupModeScreen(),
      HomeScreen(settings: widget.settings),
      SettingsScreen(settings: widget.settings),
    ];
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: AnimatedBuilder(
        animation: LobbyStore.instance,
        builder: (_, _) => _StickerNavBar(
          index: _tab,
          inLobby: LobbyStore.instance.inLobby,
          onTap: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

class _StickerNavBar extends StatelessWidget {
  final int index;
  final bool inLobby;
  final ValueChanged<int> onTap;
  const _StickerNavBar({
    required this.index,
    required this.inLobby,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final middleIcon = inLobby ? Icons.groups_2 : Icons.bolt;
    final middleLabel = inLobby ? 'Group' : 'Solo';
    final accent = inLobby ? AppColors.purple : AppColors.coral;
    final shadow = inLobby ? AppColors.purple : AppColors.shadowWarm;

    final items = [
      (Icons.groups_2_outlined, 'Lobby'),
      (middleIcon, middleLabel),
      (Icons.tune, 'Settings'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.ink, width: 3),
          boxShadow: [
            BoxShadow(
              color: shadow,
              offset: const Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: List.generate(items.length, (i) {
            final (icon, label) = items[i];
            final active = i == index;
            final isMiddleGroup = i == 1 && inLobby;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? AppColors.cream : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(icon,
                              color: active
                                  ? AppColors.cream
                                  : AppColors.textFaint,
                              size: 22),
                          if (isMiddleGroup && !active)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.purple,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.ink, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label.toUpperCase(),
                        style: grotesk(
                          size: 11,
                          weight: FontWeight.w700,
                          color: active ? AppColors.cream : AppColors.textFaint,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
