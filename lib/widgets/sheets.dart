import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sms_message.dart';
import '../screens/analysis_summary_screen.dart';
import '../state/guard_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'shield_hero.dart';
import 'threat_gauge.dart';

Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color.fromRGBO(0, 0, 0, 0.55),
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (ctx) => _SheetFrame(child: builder(ctx)),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xF2182238), Color(0xF20B1220)],
            ),
            border: Border(top: BorderSide(color: AppColors.white(0.18))),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 8),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.white(0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- checklist

class _Check {
  const _Check(this.icon, this.title, this.subtitle, this.ok);
  final IconData icon;
  final String title, subtitle;
  final bool ok;
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.check);
  final _Check check;

  @override
  Widget build(BuildContext context) {
    final color = check.ok ? AppColors.green : AppColors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: AppColors.white(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white(0.1)),
      ),
      child: Row(
        children: [
          ThreatIcon(icon: check.icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  check.subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          // Fixed gap so long titles can never touch the status icon.
          const SizedBox(width: 12),
          Icon(
            check.ok ? Icons.check_circle_rounded : Icons.error_rounded,
            color: color,
            size: 22,
          ),
        ],
      ),
    );
  }
}

List<_Check> _checks(GuardState s) => [
  _Check(
    Icons.sms,
    'Autonomous SMS monitoring',
    s.monitoring ? 'Watching every incoming message' : 'Paused',
    s.monitoring,
  ),
  _Check(
    Icons.psychology,
    'AI phishing detection',
    s.monitoring ? 'Engine online and up to date' : 'Standby',
    s.monitoring,
  ),
  _Check(
    Icons.link,
    'Real-time link scanning',
    s.linkScanning ? 'Links checked before you open them' : 'Turned off',
    s.linkScanning,
  ),
  _Check(
    Icons.block,
    'Auto-block high-risk senders',
    s.autoBlock ? 'Dangerous senders are blocked' : 'Turned off',
    s.autoBlock,
  ),
  _Check(
    Icons.notifications_active,
    'Threat alerts',
    s.alerts ? 'You are notified instantly' : 'Turned off',
    s.alerts,
  ),
];

// ---------------------------------------------------------------- protection

void showProtectionSheet(BuildContext context) =>
    showGlassSheet<void>(context, builder: (_) => const _ProtectionSheet());

class _ProtectionSheet extends StatelessWidget {
  const _ProtectionSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GuardState>();
    return Column(
      children: [
        const ShieldHero(size: 190),
        Text(
          s.monitoring ? 'You are protected' : 'Protection paused',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Protection score ${s.protectionScore}%',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        for (final c in _checks(s)) _CheckRow(c),
      ],
    );
  }
}

// ---------------------------------------------------------------- security check

void showSecurityCheckSheet(BuildContext context) =>
    showGlassSheet<void>(context, builder: (_) => const _SecuritySheet());

class _SecuritySheet extends StatelessWidget {
  const _SecuritySheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GuardState>();
    final checks = [
      ..._checks(s),
      const _Check(
        Icons.system_update,
        'AI model up to date',
        'Threat intelligence refreshed today',
        true,
      ),
    ];
    final issues = checks.where((c) => !c.ok).length;
    return Column(
      children: [
        Row(
          children: [
            MiniRing(
              value: s.protectionScore.toDouble(),
              size: 76,
              color: issues == 0 ? AppColors.green : AppColors.orange,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security Check',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    issues == 0
                        ? 'All checks passed. Your device is well protected.'
                        : '$issues item${issues == 1 ? '' : 's'} need your attention.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final c in checks) _CheckRow(c),
      ],
    );
  }
}

// ---------------------------------------------------------------- scan

void showScanSheet(BuildContext context) =>
    showGlassSheet<void>(context, builder: (_) => const _ScanSheet());

class _ScanSheet extends StatefulWidget {
  const _ScanSheet();

  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<_ScanSheet> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GuardState>().runScan();
      setState(() => _started = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GuardState>();
    final done = _started && !s.scanning && s.scanProgress >= 1;
    const steps = [
      'Reading incoming messages',
      'Checking links & domains',
      'Analyzing language patterns',
      'Scoring threats',
    ];
    final active = (s.scanProgress * steps.length)
        .floor()
        .clamp(0, steps.length - 1)
        .toInt();

    return Column(
      children: [
        MiniRing(
          value: done ? 100 : s.scanProgress * 100,
          size: 120,
          color: done ? AppColors.green : AppColors.primary,
        ),
        const SizedBox(height: 18),
        Text(
          done ? 'Scan complete' : 'Scanning your messages…',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          done
              ? '${s.totalThreats} threats are being neutralized. Everything else is safe.'
              : 'ThreatGuard AI is checking every message.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  done || i < active
                      ? Icons.check_circle_rounded
                      : i == active
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: done || i < active
                      ? AppColors.green
                      : i == active
                      ? AppColors.primary
                      : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 14.5,
                    color: done || i <= active
                        ? AppColors.text
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: done
              ? GradientButton(
                  label: 'Done',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                )
              : GhostButton(
                  label: 'Hide',
                  onPressed: () => Navigator.of(context).pop(),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- alerts

void showAlertsSheet(BuildContext context) {
  showGlassSheet<void>(
    context,
    builder: (ctx) {
      final items = context.read<GuardState>().activity.take(4).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent alerts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Threats ThreatGuard handled for you',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No alerts. You are all clear.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
          for (final m in items)
            _SheetAction(
              icon: m.category.icon,
              color: m.color,
              label: m.activityTitle,
              caption: '${m.sender} · ${m.timeLabel}',
              onTap: () {
                Navigator.of(ctx).pop();
                openAnalysis(context, m);
              },
            ),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------- message actions

void showMessageActions(BuildContext context, SmsMessage m) {
  final state = context.read<GuardState>();
  showGlassSheet<void>(
    context,
    builder: (ctx) {
      final blocked = state.isManuallyBlocked(m.sender);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.sender,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${m.category.label} · ${m.risk}% risk',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _SheetAction(
            icon: Icons.analytics,
            color: AppColors.primary,
            label: 'View AI analysis',
            caption: 'See why this message was flagged',
            onTap: () {
              Navigator.of(ctx).pop();
              openAnalysis(context, m);
            },
          ),
          _SheetAction(
            icon: blocked ? Icons.lock_open : Icons.block,
            color: blocked ? AppColors.green : AppColors.red,
            label: blocked ? 'Unblock sender' : 'Block sender',
            caption: blocked
                ? 'Allow messages from this sender again'
                : 'Stop all future messages from this sender',
            onTap: () {
              Navigator.of(ctx).pop();
              if (blocked) {
                state.unblockSender(m.sender);
                showToast(context, '${m.sender} unblocked');
              } else {
                state.blockSender(m.sender);
                showToast(context, '${m.sender} blocked');
              }
            },
          ),
        ],
      );
    },
  );
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.caption,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label, caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white(0.06),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ThreatIcon(icon: icon, color: color, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
