import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/guard_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/floating_dock.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GuardState>();
    final pad = MediaQuery.paddingOf(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        pad.top + 16,
        AppSpacing.screen,
        kDockClearance + pad.bottom,
      ),
      children: [
        const ScreenHeader(title: 'Settings', subtitle: 'Tune your AI shield'),
        GlassCard(
          padding: const EdgeInsets.all(18),
          glow: AppColors.blue,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.aurora,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(110),
                      blurRadius: 22,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Device',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ThreatGuard AI Protection',
                      style: TextStyle(color: AppColors.muted, fontSize: 13.5),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Protection Status',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                        StatusPill(
                          label: s.status.label,
                          color: s.status.color,
                          dot: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('Protection'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            children: [
              _ToggleRow(
                icon: Icons.sms,
                title: 'SMS monitoring',
                subtitle: 'Scan every incoming message automatically',
                value: s.monitoring,
                onChanged: (v) => s.update(() => s.monitoring = v),
              ),
              _ToggleRow(
                icon: Icons.block,
                title: 'Auto-block high-risk senders',
                subtitle: 'Block dangerous senders without asking',
                value: s.autoBlock,
                onChanged: (v) => s.update(() => s.autoBlock = v),
              ),
              _ToggleRow(
                icon: Icons.link,
                title: 'Real-time link scanning',
                subtitle: 'Check every link before it opens',
                value: s.linkScanning,
                onChanged: (v) => s.update(() => s.linkScanning = v),
              ),
              _ToggleRow(
                icon: Icons.notifications_active,
                title: 'Threat alerts',
                subtitle: 'Get notified when a threat is stopped',
                value: s.alerts,
                onChanged: (v) => s.update(() => s.alerts = v),
              ),
              _ToggleRow(
                icon: Icons.hub,
                title: 'Share anonymous threat intel',
                subtitle: 'Help protect others from new scams',
                value: s.shareIntel,
                last: true,
                onChanged: (v) => s.update(() => s.shareIntel = v),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Text(
            'These are your preferences. The features behind them connect with the backend.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
        const SectionHeader('Detection Sensitivity'),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PillTabs(
                labels: const ['Relaxed', 'Balanced', 'Strict'],
                index: s.sensitivity.index,
                expand: true,
                onChanged: (i) =>
                    s.update(() => s.sensitivity = Sensitivity.values[i]),
              ),
              const SizedBox(height: 14),
              Text(
                switch (s.sensitivity) {
                  Sensitivity.relaxed =>
                    'Only the most obvious scams are flagged. Fewer alerts.',
                  Sensitivity.balanced =>
                    'The recommended mix of protection and fewer false alarms.',
                  Sensitivity.strict =>
                    'Flags anything unusual. Maximum protection, more alerts.',
                },
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('About'),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ThreatGuard AI 1.0.0',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 2),
              const Text(
                'Detection engine: not connected yet (pending backend).',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _ToggleRow(
                icon: Icons.science_rounded,
                title: 'Demo mode',
                subtitle: 'Show sample messages. Not real device data.',
                value: s.demoMode,
                last: !s.demoMode,
                onChanged: (v) => s.setDemoMode(v),
              ),
              if (s.demoMode) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: GhostButton(
                    label: 'Reset demo data',
                    icon: Icons.restart_alt_rounded,
                    onPressed: () {
                      context.read<GuardState>().reset();
                      showToast(context, 'Demo data reset');
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });
  final IconData icon;
  final String title, subtitle;
  final bool value, last;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: AppColors.white(0.08))),
      ),
      child: Row(
        children: [
          ThreatIcon(icon: icon, color: AppColors.primary, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.white(0.18),
            ),
          ),
        ],
      ),
    );
  }
}
