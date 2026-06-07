import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/grain.dart';
import 'theme/palettes.dart';
import 'theme/text_styles.dart';

void main() => runApp(const MarginApp());

class MarginApp extends StatelessWidget {
  const MarginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MARGIN',
      debugShowCheckedModeBanner: false,
      theme: buildMarginTheme(AppPalette.dark, kAccentDefault),
      home: const _ThemePreview(),
    );
  }
}

/// Temporary landing screen that proves the theme/fonts/grain load.
/// Replaced by the real home shell in a later step.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MARGIN',
                  style: AppFonts.display(
                    size: 48,
                    letterSpacing: -1.4,
                    height: 0.85,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'KİŞİSEL EKRAN İNDEKSİ',
                  style: AppFonts.mono(
                    size: 10,
                    letterSpacing: 2.6,
                    color: c.mut,
                  ),
                ),
                const SizedBox(height: 24),
                Container(width: 40, height: 3, color: c.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
