import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/guard_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/floating_dock.dart';
import '../widgets/glass_card.dart';

const _coverage = <String>[
  'Phishing',
  'Smishing',
  'Social engineering',
  'Banking scams',
  'Account recovery scams',
  'Crypto scams',
  'Parcel delivery scams',
  'Credential theft',
  'OTP theft',
  'Identity impersonation',
  'Business impersonation',
  'Government impersonation',
  'AI-generated campaigns',
  'Malicious links',
  'URL obfuscation',
  'Psychological manipulation',
  'Urgency-based scams',
  'Fake verification scams',
];

class ThreatCenterScreen extends StatelessWidget {
  const ThreatCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GuardState>();
    final pad = MediaQuery.paddingOf(context);
    final elevated = s.highRisk >= 3;
    final levelColor = elevated ? AppColors.orange : AppColors.green;
    final senders = s.blockedSenders;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        pad.top + 16,
        20,
        kDockClearance + pad.bottom,
      ),
      children: [
        const ScreenHeader(
          title: 'Threat Center',
          subtitle: 'What ThreatGuard is stopping',
        ),
        GlassCard(
          glow: levelColor,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              ThreatIcon(
                icon: Icons.public_rounded,
                color: levelColor,
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current threat level',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    Text(
                      elevated ? 'Elevated' : 'Low',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: levelColor,
                      ),
                    ),
                    Text(
                      elevated
                          ? 'Scam activity targeting you is above normal.'
                          : 'Scam activity is within the normal range.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('Detection Coverage'),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in _coverage)
                StatusPill(
                  label: label,
                  color: AppColors.primary,
                  icon: Icons.check_rounded,
                ),
            ],
          ),
        ),
        SectionHeader('Blocked Senders  ·  ${senders.length}'),
        if (senders.isEmpty)
          const GlassCard(
            child: Center(
              child: Text(
                'No blocked senders yet.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        for (final name in senders)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.block_rounded,
                    size: 20,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  if (s.isManuallyBlocked(name))
                    GestureDetector(
                      onTap: () {
                        context.read<GuardState>().unblockSender(name);
                        showToast(context, '$name unblocked');
                      },
                      child: const Text(
                        'Unblock',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    const StatusPill(
                      label: 'Auto-blocked',
                      color: AppColors.muted,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
