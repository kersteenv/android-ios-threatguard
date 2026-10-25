import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/guard_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/floating_dock.dart';
import '../widgets/glass_card.dart';
import '../widgets/shield_hero.dart';
import '../widgets/sheets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GuardState>();
    final pad = MediaQuery.paddingOf(context);
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => context.read<GuardState>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          pad.top + 12,
          20,
          kDockClearance + pad.bottom,
        ),
        children: [
          _TopBar(state: s),
          const SizedBox(height: 8),
          const Center(child: ShieldHero(size: 270)),
          _HeroText(state: s),
          const SectionHeader('Today'),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.block_rounded,
                  color: AppColors.green,
                  value: s.blockedToday,
                  label: 'Threats Blocked Today',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.mark_email_read_rounded,
                  color: AppColors.primary,
                  value: s.messagesScanned,
                  label: 'Messages Scanned',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.warning_rounded,
                  color: AppColors.orange,
                  value: s.highRisk,
                  label: 'High Risk Messages',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.person_off_rounded,
                  color: AppColors.violet,
                  value: s.blockedSenderCount,
                  label: 'Blocked Senders',
                ),
              ),
            ],
          ),
          const SectionHeader('Quick Actions'),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.radar_rounded,
                  label: 'Run Scan',
                  onTap: () => showScanSheet(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.shield_rounded,
                  label: 'View Threats',
                  onTap: () => onNavigate(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.fact_check_rounded,
                  label: 'Security Check',
                  onTap: () => showSecurityCheckSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});
  final GuardState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.aurora,
          ),
          child: const Icon(Icons.shield_rounded, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ThreatGuard AI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'Always watching over you',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        GlassIconButton(
          icon: Icons.notifications_rounded,
          badge: state.activity.isNotEmpty,
          onTap: () => showAlertsSheet(context),
        ),
      ],
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.state});
  final GuardState state;

  @override
  Widget build(BuildContext context) {
    final on = state.monitoring;
    final gradient = on
        ? AppGradients.safe
        : const LinearGradient(colors: [AppColors.orange, Color(0xFFFFD58A)]);
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (r) => gradient.createShader(r),
          child: Text(
            on ? 'PROTECTED' : 'PAUSED',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your AI shield against phishing,\nsocial engineering,\nand SMS scams.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.45),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _HeroStat(
                value: '${state.protectionScore}%',
                label: 'Protection Score',
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HeroStat(
                value: on ? 'ONLINE' : 'STANDBY',
                label: 'AI Engine',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HeroStat(
                value: on ? 'ACTIVE' : 'OFF',
                label: 'SMS Monitoring',
                color: on ? AppColors.green : AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'View Protection Status',
            icon: Icons.verified_user_rounded,
            onPressed: () => showProtectionSheet(context),
          ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThreatIcon(icon: icon, color: color, size: 40),
          const SizedBox(height: 14),
          CountUp(
            value: value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.aurora,
            ),
            child: Icon(icon, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
