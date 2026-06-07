import 'package:flutter/material.dart';

import 'palettes.dart';
import 'text_styles.dart';

/// Carries the full MARGIN token set (palette + accent) through the widget tree
/// as a [ThemeExtension]. Read it with the [BuildContext.margin] getter:
///
/// ```dart
/// final c = context.margin;
/// Container(color: c.bg, child: Text('hi', style: TextStyle(color: c.ink)));
/// ```
@immutable
class MarginColors extends ThemeExtension<MarginColors> {
  const MarginColors({
    required this.palette,
    required this.accent,
    required this.accentInk,
  });

  /// Builds the extension, computing the readable ink for [accent] once.
  factory MarginColors.from(AppPalette palette, Color accent) =>
      MarginColors(palette: palette, accent: accent, accentInk: inkOn(accent));

  final AppPalette palette;
  final Color accent; // brand / highlight color
  final Color accentInk; // readable text color on top of [accent]

  // Pass-throughs so widgets can write `context.margin.ink` etc.
  Color get bg => palette.bg;
  Color get panel => palette.panel;
  Color get panel2 => palette.panel2;
  Color get ink => palette.ink;
  Color get mut => palette.mut;
  Color get line => palette.line;
  Color get line2 => palette.line2;

  @override
  MarginColors copyWith({
    AppPalette? palette,
    Color? accent,
    Color? accentInk,
  }) =>
      MarginColors(
        palette: palette ?? this.palette,
        accent: accent ?? this.accent,
        accentInk: accentInk ?? this.accentInk,
      );

  @override
  MarginColors lerp(MarginColors? other, double t) {
    if (other is! MarginColors) return this;
    return MarginColors(
      palette: AppPalette.lerp(palette, other.palette, t),
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
    );
  }
}

/// Builds the app [ThemeData] for a given [palette] + [accent].
///
/// The prototype is intentionally hard-edged (zero border radius), so most of
/// the visual identity lives in [MarginColors] and the per-widget styling; this
/// only wires the sensible Material defaults (background, text theme, selection).
ThemeData buildMarginTheme(AppPalette palette, Color accent) {
  final base = ThemeData(brightness: palette.brightness, useMaterial3: true);
  final colors = MarginColors.from(palette, accent);

  return base.copyWith(
    scaffoldBackgroundColor: palette.bg,
    canvasColor: palette.bg,
    extensions: <ThemeExtension<dynamic>>[colors],
    textTheme: AppFonts.textTheme(palette.ink),
    colorScheme: base.colorScheme.copyWith(
      primary: accent,
      onPrimary: colors.accentInk,
      surface: palette.bg,
      onSurface: palette.ink,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: accent,
      selectionColor: accent.withValues(alpha: 0.35),
      selectionHandleColor: accent,
    ),
  );
}

/// Convenient access to [MarginColors] from any [BuildContext].
extension MarginThemeX on BuildContext {
  MarginColors get margin => Theme.of(this).extension<MarginColors>()!;
}
