import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 24-hour value → "12 AM", "4 PM", etc.
String formatHour(int hour) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h ${hour % 24 >= 12 ? 'PM' : 'AM'}';
}

/// Evenly spaced hour labels starting at midnight (default: 12 AM, 4 AM … 8 PM).
List<String> dayHourLabels({int count = 6, int step = 4}) => [
  for (var i = 0; i < count; i++) formatHour(i * step),
];

/// Vertical bars; the last bar is highlighted.
class TrendBars extends StatelessWidget {
  const TrendBars({super.key, required this.values, required this.labels});
  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<int>(1, math.max);
    final last = values.length - 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Column(
              children: [
                Text(
                  '${values[i]}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: i == last ? AppColors.text : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: (values[i] / maxV).clamp(0.04, 1.0),
                      child: Container(
                        width: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: i == last ? AppGradients.aurora : null,
                          color: i == last ? null : AppColors.white(0.14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
