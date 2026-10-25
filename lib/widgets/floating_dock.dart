import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Bottom space screens must leave free so content isn't hidden by the dock.
const double kDockClearance = 104;

class DockItem {
  const DockItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class FloatingDock extends StatelessWidget {
  const FloatingDock({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });
  final List<DockItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(34);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              const BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.45),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
              BoxShadow(
                color: AppColors.primary.withAlpha(30),
                blurRadius: 40,
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.white(0.16), AppColors.white(0.06)],
                  ),
                  border: Border.all(color: AppColors.white(0.18)),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _DockButton(
                          item: items[i],
                          active: i == index,
                          onTap: () => onChanged(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.item,
    required this.active,
    required this.onTap,
  });
  final DockItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: 46,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: active
                  ? LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha(70),
                        AppColors.blue.withAlpha(60),
                      ],
                    )
                  : null,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(90),
                        blurRadius: 18,
                        spreadRadius: -2,
                      ),
                    ]
                  : const [],
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: active ? Colors.white : AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 280),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primary : AppColors.muted,
            ),
            child: Text(item.label, maxLines: 1, overflow: TextOverflow.clip),
          ),
        ],
      ),
    );
  }
}
