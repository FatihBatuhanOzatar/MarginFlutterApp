import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';

/// The recurring `LABEL ──────── trailing` header. A bold mono label, a hairline
/// that fills the remaining width, and an optional muted [count] and/or custom
/// [trailing] widget on the right.
class SectionLine extends StatelessWidget {
  const SectionLine({
    super.key,
    required this.label,
    this.count,
    this.trailing,
  });

  final String label;
  final String? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: AppFonts.mono(
              size: 10,
              weight: FontWeight.w700,
              letterSpacing: 2.0,
              color: c.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: c.line)),
          if (count != null) ...[
            const SizedBox(width: 12),
            Text(
              count!,
              style: AppFonts.mono(
                size: 10,
                letterSpacing: 2.0,
                color: c.mut,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
