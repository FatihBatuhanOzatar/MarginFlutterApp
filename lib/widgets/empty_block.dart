import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';

/// Centered empty state: a large glyph, a title, and an optional subtitle.
class EmptyBlock extends StatelessWidget {
  const EmptyBlock({
    super.key,
    required this.glyph,
    required this.title,
    this.sub,
  });

  final String glyph;
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            glyph,
            style: AppFonts.display(size: 46, weight: FontWeight.w700, height: 1, color: c.line2),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.display(size: 17, weight: FontWeight.w700, color: c.ink),
          ),
          if (sub != null) ...[
            const SizedBox(height: 10),
            Text(
              sub!,
              textAlign: TextAlign.center,
              style: AppFonts.mono(size: 12.5, letterSpacing: 0.5, color: c.mut),
            ),
          ],
        ],
      ),
    );
  }
}
