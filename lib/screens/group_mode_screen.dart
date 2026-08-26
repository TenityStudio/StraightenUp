import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/lobby.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';

class GroupModeScreen extends StatelessWidget {
  const GroupModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: LobbyStore.instance,
          builder: (_, _) => LobbyStore.instance.inLobby
              ? const _InLobbyView()
              : const _NoLobbyView(),
        ),
      ),
    );
  }
}

class _NoLobbyView extends StatelessWidget {
  const _NoLobbyView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KickerPill(text: 'GROUP MODE'),
          const SizedBox(height: 14),
          Text('Bring the\ncrew', style: anton(size: 40, height: 0.95)),
          const SizedBox(height: 12),
          Text(
            'Everyone in the lobby gets called at the same random moments. Who reacts, who misses — everyone sees.',
            style: grotesk(
              size: 15,
              color: AppColors.textMuted,
              weight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 34),
          StickerButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _CreateLobbyScreen()),
            ),
            fill: AppColors.coral,
            radius: 22,
            shadowOffset: 6,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create lobby',
                    style: anton(size: 30, color: AppColors.cream, height: 1)),
                const SizedBox(height: 8),
                Text(
                  "You're the host. Set the rhythm, share the code.",
                  style: grotesk(
                    size: 15,
                    color: const Color(0xFFFFE3D6),
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlineChip(
                    label: 'Get a code →',
                    fill: AppColors.cream,
                    textColor: AppColors.coralDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StickerButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _JoinLobbyScreen()),
            ),
            fill: AppColors.white,
            radius: 22,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join lobby', style: anton(size: 28, height: 1)),
                const SizedBox(height: 8),
                Text(
                  'Got a 6-letter code from someone? Punch it in.',
                  style: grotesk(
                    size: 15,
                    color: AppColors.textMuted,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: OutlineChip(label: 'Enter code →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CREATE LOBBY ───────────────────────────────────────────────────────────

class _CreateLobbyScreen extends StatefulWidget {
  const _CreateLobbyScreen();

  @override
  State<_CreateLobbyScreen> createState() => _CreateLobbyScreenState();
}

class _CreateLobbyScreenState extends State<_CreateLobbyScreen> {
  final _lobbyCtrl = TextEditingController(text: 'The Straight Crew');
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  int _perDay = 3;
  int _start = 9;
  int _end = 21;
  bool _submitting = false;
  bool _passwordOn = false;

  @override
  void dispose() {
    _lobbyCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lobbyName = _lobbyCtrl.text.trim();
    final yourName = _nameCtrl.text.trim();
    if (lobbyName.isEmpty || yourName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text('Fill in both names.',
              style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
      return;
    }
    final password = _passwordOn ? _passCtrl.text.trim() : null;
    if (_passwordOn && (password == null || password.length < 4)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text('Password must be at least 4 characters.',
              style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await LobbyStore.instance.create(
        lobbyName: lobbyName,
        yourName: yourName,
        perDay: _perDay,
        startHour: _start,
        endHour: _end,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coralDeep,
          content: Text('Failed to create: $e',
              style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('CREATE LOBBY',
            style: grotesk(
                size: 15, weight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
          children: [
            _sectionTitle('Lobby name'),
            const SizedBox(height: 8),
            _InkTextField(controller: _lobbyCtrl, hint: 'The Croatia Crew'),
            const SizedBox(height: 20),
            _sectionTitle('Your name'),
            const SizedBox(height: 8),
            _InkTextField(controller: _nameCtrl, hint: 'You'),
            const SizedBox(height: 24),
            _sectionTitle('Frequency'),
            const SizedBox(height: 8),
            _FrequencyRow(
              value: _perDay,
              onChanged: (v) => setState(() => _perDay = v),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Window'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _HourField(
                    label: 'From',
                    value: _start,
                    onChanged: (v) => setState(() => _start = v),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _HourField(
                    label: 'To',
                    value: _end,
                    onChanged: (v) => setState(() => _end = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Password (optional)'),
            const SizedBox(height: 8),
            _PasswordToggle(
              value: _passwordOn,
              onChanged: (v) => setState(() => _passwordOn = v),
            ),
            if (_passwordOn) ...[
              const SizedBox(height: 10),
              _InkTextField(
                controller: _passCtrl,
                hint: 'at least 4 chars',
                textCapitalization: TextCapitalization.none,
              ),
            ],
            const SizedBox(height: 30),
            StickerButton(
              onPressed: _submitting ? null : _submit,
              fill: AppColors.coral,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                _submitting ? 'CREATING…' : 'CREATE LOBBY',
                style: grotesk(
                  size: 18,
                  color: AppColors.cream,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── JOIN LOBBY ─────────────────────────────────────────────────────────────

class _JoinLobbyScreen extends StatefulWidget {
  const _JoinLobbyScreen();

  @override
  State<_JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<_JoinLobbyScreen> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitting = false;
  bool _checkingCode = false;
  bool? _needsPassword; // null = unbekannt, wird beim Peek gesetzt

  @override
  void initState() {
    super.initState();
    _codeCtrl.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeCtrl.removeListener(_onCodeChanged);
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Timer? _peekDebounce;
  void _onCodeChanged() {
    _peekDebounce?.cancel();
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      if (_needsPassword != null) setState(() => _needsPassword = null);
      return;
    }
    _peekDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _checkingCode = true);
      try {
        final peek = await LobbyStore.instance.peekLobby(code);
        if (!mounted) return;
        setState(() {
          _checkingCode = false;
          _needsPassword = peek.exists ? peek.hasPassword : null;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _checkingCode = false;
          _needsPassword = null;
        });
      }
    });
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim();
    if (code.length != 6 || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text('Need a 6-character code and a name.',
              style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await LobbyStore.instance.join(
        code: code,
        yourName: name,
        password: _needsPassword == true ? _passCtrl.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on WrongPasswordException {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coralDeep,
          content: Text('Wrong password.',
              style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    } on LobbyNotFoundException {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coralDeep,
          content: Text('No lobby with that code.',
              style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coralDeep,
          content: Text('Could not join: $e',
              style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('JOIN LOBBY',
            style: grotesk(
                size: 15, weight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
          children: [
            _sectionTitle('Lobby code'),
            const SizedBox(height: 8),
            _InkTextField(
              controller: _codeCtrl,
              hint: 'ABC123',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(6),
                _UpperCaseFormatter(),
              ],
              style: anton(
                  size: 26, letterSpacing: 3, color: AppColors.ink, height: 1),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Your name'),
            const SizedBox(height: 8),
            _InkTextField(controller: _nameCtrl, hint: 'You'),
            const SizedBox(height: 8),
            _CodeStatusHint(
              checking: _checkingCode,
              needsPassword: _needsPassword,
            ),
            if (_needsPassword == true) ...[
              const SizedBox(height: 16),
              _sectionTitle('Password'),
              const SizedBox(height: 8),
              _InkTextField(
                controller: _passCtrl,
                hint: 'ask the host',
                textCapitalization: TextCapitalization.none,
              ),
            ],
            const SizedBox(height: 30),
            StickerButton(
              onPressed: _submitting ? null : _submit,
              fill: AppColors.coral,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                _submitting ? 'JOINING…' : 'JOIN LOBBY',
                style: grotesk(
                  size: 18,
                  color: AppColors.cream,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ─── IN LOBBY ───────────────────────────────────────────────────────────────

class _InLobbyView extends StatefulWidget {
  const _InLobbyView();

  @override
  State<_InLobbyView> createState() => _InLobbyViewState();
}

class _InLobbyViewState extends State<_InLobbyView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text('Code copied — $code',
            style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _leaveOrClose(BuildContext context) async {
    final store = LobbyStore.instance;
    if (!store.youAreHost) {
      await store.leave();
      return;
    }
    // Host: Confirm bevor die ganze Lobby stirbt.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.ink, width: 3),
        ),
        title: Text('Close lobby?', style: anton(size: 26, height: 1)),
        content: Text(
          'This deletes the lobby, all members, all call history. Everyone in the crew gets kicked. This cannot be undone.',
          style: grotesk(
            size: 14,
            color: AppColors.textMuted,
            weight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text('Keep it',
                style: grotesk(
                    size: 14,
                    color: AppColors.textFaint,
                    weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text('DELETE',
                style: grotesk(
                    size: 14,
                    color: AppColors.coralDeep,
                    weight: FontWeight.w800,
                    letterSpacing: 1.4)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.closeLobby();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text('Lobby closed.',
              style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coralDeep,
          content: Text('Failed: $e',
              style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
        ),
      );
    }
  }

  Future<void> _summon(BuildContext context) async {
    if (!LobbyStore.instance.canSummonNow) return;
    await LobbyStore.instance.summonCall();
    await NotificationService.instance.triggerTestCallNow();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text('You called the crew. Head to Solo to react.',
            style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = LobbyStore.instance;
    final lobby = store.current!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LobbyHeader(
            name: lobby.name,
            code: lobby.code,
            onCopy: () => _copyCode(context, lobby.code),
          ),
          const SizedBox(height: 20),
          _SectionTitle('GROUP RHYTHM'),
          const SizedBox(height: 10),
          _RhythmCard(lobby: lobby),
          const SizedBox(height: 22),
          _SectionTitle('MEMBERS · ${store.members.length}'),
          const SizedBox(height: 10),
          if (store.members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Waiting for the crew…',
                  style: grotesk(
                      size: 13,
                      color: AppColors.textFaint,
                      weight: FontWeight.w500)),
            )
          else
            for (final m in store.members) ...[
              _MemberRow(
                  member: m, isYou: m.uid == (LobbyStore.instance.you?.uid ?? '')),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          _SummonRow(
            canSummon: store.canSummonNow,
            remaining: store.remainingSummonCooldown,
            onTap: () => _summon(context),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _CooldownHint(
              canSummon: store.canSummonNow,
              remaining: store.remainingSummonCooldown,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('LAST CALL'),
          const SizedBox(height: 10),
          _LastCallRanking(event: store.lastEvent),
          const SizedBox(height: 28),
          StickerButton(
            onPressed: () => _leaveOrClose(context),
            fill: AppColors.white,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              store.youAreHost ? 'CLOSE LOBBY' : 'LEAVE LOBBY',
              style: grotesk(
                size: 15,
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

// ─── HEADER ─────────────────────────────────────────────────────────────────

class _LobbyHeader extends StatelessWidget {
  final String name;
  final String code;
  final VoidCallback onCopy;
  const _LobbyHeader({
    required this.name,
    required this.code,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KickerPill(text: 'YOUR GROUP'),
              const SizedBox(height: 10),
              Text(name, style: anton(size: 30, height: 0.98)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _InviteChip(code: code, onTap: onCopy),
      ],
    );
  }
}

class _InviteChip extends StatelessWidget {
  final String code;
  final VoidCallback onTap;
  const _InviteChip({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CODE · TAP',
                style: kicker(
                    color: AppColors.ink, letterSpacing: 1.4, size: 9)),
            const SizedBox(height: 3),
            Text(code,
                style: anton(size: 18, letterSpacing: 2.5, height: 1)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: kicker(color: AppColors.textFaint, letterSpacing: 1.7));
  }
}

class _RhythmCard extends StatelessWidget {
  final Lobby lobby;
  const _RhythmCard({required this.lobby});

  @override
  Widget build(BuildContext context) {
    return Sticker(
      fill: AppColors.white,
      radius: 16,
      shadowOffset: 4,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.chipCool1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const Icon(Icons.schedule, color: AppColors.ink, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${lobby.perDay}× per day',
                    style: anton(size: 22, height: 1)),
                const SizedBox(height: 4),
                Text(
                  'Between ${lobby.windowStartHour.toString().padLeft(2, '0')}:00 and ${lobby.windowEndHour.toString().padLeft(2, '0')}:00',
                  style: grotesk(
                    size: 14,
                    color: AppColors.textMuted,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final LobbyMember member;
  final bool isYou;
  const _MemberRow({required this.member, required this.isYou});

  @override
  Widget build(BuildContext context) {
    final letter = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : '?';
    final avatarColors = [
      AppColors.coral,
      AppColors.teal,
      AppColors.purple,
      AppColors.bronze,
    ];
    final avatarColor =
        avatarColors[member.uid.hashCode.abs() % avatarColors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: member.host ? AppColors.ink : avatarColor,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Text(
              isYou ? 'YOU' : letter,
              style: grotesk(
                size: isYou ? 12 : 16,
                weight: FontWeight.w800,
                color: member.host ? AppColors.amber : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: grotesk(size: 15, weight: FontWeight.w700),
                children: [
                  TextSpan(text: member.displayName),
                  if (member.host)
                    TextSpan(
                      text: '  · host',
                      style: grotesk(
                        size: 13,
                        color: AppColors.textFaint,
                        weight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (member.streak > 0)
            Text('🔥${member.streak}',
                style: grotesk(
                  size: 13,
                  weight: FontWeight.w800,
                  color: AppColors.teal,
                )),
        ],
      ),
    );
  }
}

class _SummonRow extends StatelessWidget {
  final bool canSummon;
  final Duration remaining;
  final VoidCallback onTap;
  const _SummonRow({
    required this.canSummon,
    required this.remaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = canSummon;
    return GestureDetector(
      onTap: active ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.dashedDivider,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: active ? AppColors.coral : AppColors.ink,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.coral : AppColors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: Icon(
                active ? Icons.bolt : Icons.hourglass_bottom,
                color: active ? AppColors.cream : AppColors.ink,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                active ? 'Summon the crew' : 'Cooldown',
                style: grotesk(
                  size: 15,
                  weight: FontWeight.w800,
                  color: active ? AppColors.cream : AppColors.textMuted,
                ),
              ),
            ),
            Text(
              active ? '→' : '⏳',
              style: grotesk(
                size: 18,
                weight: FontWeight.w800,
                color: active ? AppColors.amber : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CooldownHint extends StatelessWidget {
  final bool canSummon;
  final Duration remaining;
  const _CooldownHint({required this.canSummon, required this.remaining});

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final msg = canSummon
        ? 'Ready. 3h cooldown starts after you summon.'
        : 'You can summon again in ${_fmt(remaining)}.';
    return Text(
      msg,
      style: grotesk(
        size: 12,
        color: AppColors.textFaint,
        weight: FontWeight.w500,
      ),
    );
  }
}

class _LastCallRanking extends StatelessWidget {
  final LobbyEvent? event;
  const _LastCallRanking({required this.event});

  @override
  Widget build(BuildContext context) {
    final e = event;
    if (e == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Text(
          'No calls yet. Summon the crew to start the record.',
          style: grotesk(
            size: 13,
            color: AppColors.textMuted,
            weight: FontWeight.w500,
          ),
        ),
      );
    }
    final when = e.startedAt;
    final hhmm =
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
              'called at $hhmm · window ${e.windowSeconds}s · ${e.finalized ? "closed" : "live"}',
              style: grotesk(
                size: 12,
                color: AppColors.textFaint,
                weight: FontWeight.w500,
              )),
        ),
        if (e.responses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Waiting for the first reaction…',
                style: grotesk(
                  size: 13,
                  color: AppColors.textFaint,
                  weight: FontWeight.w500,
                )),
          )
        else
          for (final r in e.responses) ...[
            _RankRow(response: r),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final LobbyResponse response;
  const _RankRow({required this.response});

  String _ord(int n) {
    if (n <= 0) return '—';
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  @override
  Widget build(BuildContext context) {
    final missed = response.missed;
    final medalColor = switch (response.order) {
      1 => AppColors.amber,
      2 => AppColors.textFaint,
      3 => AppColors.bronze,
      _ => AppColors.dashedDivider,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: missed
            ? AppColors.cream
            : (response.order == 1 ? AppColors.amber : AppColors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: missed ? Colors.transparent : medalColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Text(missed ? '—' : _ord(response.order),
                style: grotesk(
                  size: 13,
                  weight: FontWeight.w800,
                  color: AppColors.ink,
                )),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              response.displayName,
              style: grotesk(
                size: 15,
                weight: FontWeight.w700,
                color: missed ? AppColors.textFaint : AppColors.ink,
              ),
            ),
          ),
          Text(
            missed ? 'missed 😬' : '${response.responseSeconds}s',
            style: grotesk(
              size: 13,
              weight: FontWeight.w800,
              color: missed ? AppColors.bronze : AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHARED FORM WIDGETS ────────────────────────────────────────────────────

class _PasswordToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PasswordToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Sticker(
      fill: AppColors.white,
      radius: 14,
      shadowOffset: 4,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(value ? Icons.lock : Icons.lock_open,
              size: 22,
              color: value ? AppColors.coral : AppColors.textFaint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value
                  ? 'Password required to join'
                  : 'No password (anyone with code)',
              style: grotesk(
                size: 14,
                weight: FontWeight.w700,
                color: value ? AppColors.ink : AppColors.textMuted,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.coral,
            inactiveTrackColor: AppColors.dashedDivider,
          ),
        ],
      ),
    );
  }
}

class _CodeStatusHint extends StatelessWidget {
  final bool checking;
  final bool? needsPassword;
  const _CodeStatusHint({required this.checking, required this.needsPassword});

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, top: 4),
        child: Text('Checking code…',
            style: grotesk(
              size: 12,
              color: AppColors.textFaint,
              weight: FontWeight.w500,
            )),
      );
    }
    if (needsPassword == true) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, top: 4),
        child: Row(
          children: [
            const Icon(Icons.lock, size: 14, color: AppColors.coral),
            const SizedBox(width: 6),
            Text('This lobby requires a password.',
                style: grotesk(
                  size: 12,
                  color: AppColors.coral,
                  weight: FontWeight.w700,
                )),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

Widget _sectionTitle(String s) => Text(
      s.toUpperCase(),
      style: kicker(color: AppColors.textFaint, letterSpacing: 1.7),
    );

class _InkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextStyle? style;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  const _InkTextField({
    required this.controller,
    required this.hint,
    this.style,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        style: style ?? grotesk(size: 16, weight: FontWeight.w700),
        cursorColor: AppColors.coral,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: grotesk(
            size: 16,
            color: AppColors.textFaint,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FrequencyRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _FrequencyRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Sticker(
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
                value: value.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                label: '$value×',
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$value×', style: anton(size: 24)),
        ],
      ),
    );
  }
}

class _HourField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _HourField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
