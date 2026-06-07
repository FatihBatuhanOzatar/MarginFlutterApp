import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';

/// Square, hard-edged filter chip. Active = filled with the accent; inactive =
/// outlined and muted. Labels are uppercased to match the prototype.
class MarginChip extends StatelessWidget {
  const MarginChip({
    super.key,
    required this.label,
    required this.active,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.accent : Colors.transparent,
          border: Border.all(color: active ? c.accent : c.line2),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppFonts.mono(
            size: 10,
            letterSpacing: 1.2,
            color: active ? c.accentInk : c.mut,
          ),
        ),
      ),
    );
  }
}
