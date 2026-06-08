import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/grain.dart';
import '../theme/palettes.dart';
import '../theme/text_styles.dart';

/// A small thumbnail reused by search rows and archive entries. When [imageUrl]
/// is given it shows the real TMDB poster; until that loads (or if it fails) it
/// falls back to a grainy color field — the title's dominant poster color — with
/// the title's initial, matching the prototype's stand-in artwork.
class ColorFieldThumb extends StatelessWidget {
  const ColorFieldThumb({
    super.key,
    required this.color,
    required this.letter,
    required this.width,
    required this.height,
    required this.fontSize,
    this.imageUrl,
  });

  final Color color;
  final String letter;
  final double width;
  final double height;
  final double fontSize;

  /// Real poster URL. When present, the artwork is layered over the color field,
  /// which then doubles as the loading / fallback placeholder.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final ink = inkOn(color);
    final url = imageUrl;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: color)),
            Positioned.fill(
              child: GrainOverlay(opacity: 0.05, dark: inkIsLight(ink)),
            ),
            Center(
              child: Text(
                letter.toUpperCase(),
                style: AppFonts.display(
                  size: fontSize,
                  color: ink.withValues(alpha: 0.9),
                ),
              ),
            ),
            // Real poster on top; while it loads the color field below shows.
            if (url != null)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (_, _) => const SizedBox.shrink(),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
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
