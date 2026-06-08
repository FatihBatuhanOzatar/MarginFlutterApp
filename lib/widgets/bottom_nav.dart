import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import 'app_icons.dart';

/// The bottom navigation: İNDEKS · ARA · ARŞİV · LİSTELER. The active tab uses
/// the accent color; the archive icon fills when active.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _tabs = [
    (AppIconKind.grid, 'İNDEKS'),
    (AppIconKind.search, 'ARA'),
    (AppIconKind.bookmark, 'ARŞİV'),
    (AppIconKind.list, 'LİSTELER'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: _NavButton(
                  kind: _tabs[i].$1,
                  label: _tabs[i].$2,
                  active: i == index,
                  filled: i == 2 && i == index,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.kind,
    required this.label,
    required this.active,
    required this.filled,
    required this.onTap,
  });

  final AppIconKind kind;
  final String label;
  final bool active;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final color = active ? c.accent : c.mut;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 13, bottom: 11),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(kind, size: 21, color: color, filled: filled),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: AppFonts.mono(size: 8.5, letterSpacing: 1.0, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
