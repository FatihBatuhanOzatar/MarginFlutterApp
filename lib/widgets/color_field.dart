import 'package:flutter/material.dart';

import '../theme/grain.dart';
import '../theme/palettes.dart';
import '../theme/text_styles.dart';

/// A small color-field thumbnail with grain and a single big initial — the
/// prototype's stand-in artwork, reused by search rows and archive entries.
/// The [color] comes from the title's dominant poster color (or a fallback).
class ColorFieldThumb extends StatelessWidget {
  const ColorFieldThumb({
    super.key,
    required this.color,
    required this.letter,
    required this.width,
    required this.height,
    required this.fontSize,
  });

  final Color color;
  final String letter;
  final double width;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final ink = inkOn(color);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: color)),
            Positioned.fill(child: GrainOverlay(opacity: 0.05, dark: inkIsLight(ink))),
            Center(
              child: Text(
                letter.toUpperCase(),
                style: AppFonts.display(
                  size: fontSize,
                  color: ink.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether the chosen ink is the light one (so grain dots should be light too).
bool inkIsLight(Color ink) => ink == kInkLight;
