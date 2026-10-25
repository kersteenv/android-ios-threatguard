import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sms_message.dart';
import '../state/guard_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/floating_dock.dart';
import '../widgets/glass_card.dart';
import '../widgets/sheets.dart';
import 'analysis_summary_screen.dart';

class SmsMonitorScreen extends StatefulWidget {
  const SmsMonitorScreen({super.key});

  @override
  State<SmsMonitorScreen> createState() => _SmsMonitorScreenState();
}

class _SmsMonitorScreenState extends State<SmsMonitorScreen> {
  int _filter = 0;
  String _query = '';
  static const _filters = ['All', 'Threats', 'Flagged', 'Safe'];

  List<SmsMessage> _apply(List<SmsMessage> all) {
    final q = _query.trim().toLowerCase();
    return all.where((m) {
      final okFilter = switch (_filter) {
        1 => m.risk >= 60,
        2 => m.risk >= 25 && m.risk < 60,
        3 => m.risk < 25,
        _ => true,
      };
      final okQuery =
          q.isEmpty ||
          m.sender.toLowerCase().contains(q) ||
          m.body.toLowerCase().contains(q);
      return okFilter && okQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GuardState>();
    final pad = MediaQuery.paddingOf(context);
    final list = _apply(s.messages);
    final safeCount = s.messages.where((m) => !m.isThreat).length;

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => context.read<GuardState>().refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              pad.top + 16,
              20,
              kDockClearance + pad.bottom + 60,
            ),
            children: [
              ScreenHeader(
                title: 'SMS Monitor',
                subtitle: 'Autonomous AI protection',
                trailing: StatusPill(
                  label: s.monitoring ? 'LIVE' : 'PAUSED',
                  color: s.monitoring ? AppColors.green : AppColors.orange,
                  dot: true,
                ),
              ),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _Stat(value: s.messagesScanned, label: 'Scanned'),
                    _Stat(
                      value: s.blockedToday,
                      label: 'Blocked',
                      color: AppColors.red,
                    ),
                    _Stat(
                      value: safeCount,
                      label: 'Safe',
                      color: AppColors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.white(0.07),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.white(0.12)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 15),
                  cursorColor: AppColors.primary,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Search messages',
                    hintStyle: TextStyle(color: AppColors.muted),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.muted,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PillTabs(
                labels: _filters,
                index: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),
              const SizedBox(height: 18),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No messages match.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              for (final m in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SmsCard(
                    key: ValueKey(m.id),
                    message: m,
                    blocked: s.isBlocked(m.sender),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: kDockClearance + pad.bottom - 8,
          child: _ScanFab(onTap: () => showScanSheet(context)),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});
  final int value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CountUp(
            value: value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SmsCard extends StatelessWidget {
  const _SmsCard({super.key, required this.message, required this.blocked});
  final SmsMessage message;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final m = message;
    return GestureDetector(
      onLongPress: () => showMessageActions(context, m),
      child: GlassCard(
        glow: m.isThreat ? m.color : null,
        padding: const EdgeInsets.all(16),
        onTap: () => openAnalysis(context, m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThreatIcon(icon: m.category.icon, color: m.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.sender,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                              ),
                            ),
                          ),
                          if (blocked && m.isThreat)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.block_rounded,
                                size: 14,
                                color: AppColors.muted,
                              ),
                            ),
                          Text(
                            m.timeLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        m.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 5, color: AppColors.white(0.08)),
                  FractionallySizedBox(
                    widthFactor: m.risk / 100,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [m.color.withAlpha(140), m.color],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusPill(label: m.category.label, color: m.color),
                      StatusPill(
                        label: m.status.label,
                        color: m.color,
                        dot: true,
                      ),
                      StatusPill(
                        label: '${m.confidence}% confidence',
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${m.risk}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: m.color,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'RISK',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  const _ScanFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        gradient: AppGradients.safe,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(110),
            blurRadius: 26,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radar_rounded, size: 20, color: Color(0xFF03121C)),
                SizedBox(width: 8),
                Text(
                  'Scan now',
                  style: TextStyle(
                    color: Color(0xFF03121C),
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
