import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import 'app_icons.dart';

/// The solid accent call-to-action ("TEKRAR DENE", "NOTU KAYDET"). Filled accent
/// when enabled; outlined + muted when disabled. [small] is the compact variant.
class HardButton extends StatelessWidget {
  const HardButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.small = false,
    this.enabled = true,
  });

  final String label;
  final AppIconKind? icon;
  final VoidCallback? onTap;
  final bool small;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final fg = enabled ? c.accentInk : c.mut;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: small
            ? const EdgeInsets.symmetric(horizontal: 13, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: enabled ? c.accent : Colors.transparent,
          border: Border.all(color: enabled ? c.accent : c.line2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: small ? 14 : 16, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppFonts.mono(
                size: small ? 10 : 11,
                weight: FontWeight.w700,
                letterSpacing: small ? 1.4 : 1.54,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
