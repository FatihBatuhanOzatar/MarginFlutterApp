import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A full set of surface / text / line colors for one MARGIN theme.
///
/// Mirrors the CSS custom properties from the prototype (`--bg`, `--panel`,
/// `--ink`, …). Two concrete palettes exist: [dark] ("Karanlık") and
/// [paper] ("Kağıt"). The accent color is kept separate because the user can
/// pick it independently of the light/dark mode.
@immutable
class AppPalette {
  const AppPalette({
    required this.name,
    required this.brightness,
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.ink,
    required this.mut,
    required this.line,
    required this.line2,
  });

  /// Display name shown in settings ("Karanlık" / "Kağıt").
  final String name;
  final Brightness brightness;

  final Color bg; // page background
  final Color panel; // raised surface / skeleton base
  final Color panel2; // secondary surface / shimmer highlight
  final Color ink; // primary text
  final Color mut; // muted text
  final Color line; // hairline divider
  final Color line2; // stronger border

  /// Dark theme — the prototype default.
  static const dark = AppPalette(
    name: 'Karanlık',
    brightness: Brightness.dark,
    bg: Color(0xFF0B0B0C),
    panel: Color(0xFF141416),
    panel2: Color(0xFF1B1B1E),
    ink: Color(0xFFF2F0EA),
    mut: Color(0xFF8A8780),
    line: Color(0x21F2F0EA), // rgba(242,240,234,0.13)
    line2: Color(0x42F2F0EA), // rgba(242,240,234,0.26)
  );

  /// Light "paper" theme.
  static const paper = AppPalette(
    name: 'Kağıt',
    brightness: Brightness.light,
    bg: Color(0xFFE9E5DC),
    panel: Color(0xFFF4F1EA),
    panel2: Color(0xFFFBF9F3),
    ink: Color(0xFF15120D),
    mut: Color(0xFF6B6760),
    line: Color(0x2915120D), // rgba(21,18,13,0.16)
    line2: Color(0x5215120D), // rgba(21,18,13,0.32)
  );

  /// All selectable palettes, in display order.
  static const all = <AppPalette>[dark, paper];

  /// Look up a palette by its display [name], falling back to [dark].
  static AppPalette byName(String? name) =>
      all.firstWhere((p) => p.name == name, orElse: () => dark);

  /// Blend two palettes channel-by-channel — used for smooth theme transitions.
  static AppPalette lerp(AppPalette a, AppPalette b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return AppPalette(
      name: t < 0.5 ? a.name : b.name,
      brightness: t < 0.5 ? a.brightness : b.brightness,
      bg: Color.lerp(a.bg, b.bg, t)!,
      panel: Color.lerp(a.panel, b.panel, t)!,
      panel2: Color.lerp(a.panel2, b.panel2, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      mut: Color.lerp(a.mut, b.mut, t)!,
      line: Color.lerp(a.line, b.line, t)!,
      line2: Color.lerp(a.line2, b.line2, t)!,
    );
  }
}

/// Default accent and the curated set the user can choose from (see settings).
const Color kAccentDefault = Color(0xFFFF4416);
const List<Color> kAccentOptions = <Color>[
  Color(0xFFFF4416), // orange-red (default)
  Color(0xFFC7F23C), // lime
  Color(0xFF2E6BFF), // blue
  Color(0xFFE8A317), // amber
];

/// Near-black and near-white inks, reused for "text on a colored field".
const Color kInkDark = Color(0xFF0B0B0C);
const Color kInkLight = Color(0xFFF2F0EA);

/// Returns the readable foreground (near-black or near-white) for a colored
/// [background], using WCAG relative luminance. Ported from the prototype's
/// `inkOn` so colored posters/heroes pick a legible text color automatically.
Color inkOn(Color background) {
  double linearize(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  final luminance = 0.2126 * linearize(background.r) +
      0.7152 * linearize(background.g) +
      0.0722 * linearize(background.b);
  return luminance > 0.34 ? kInkDark : kInkLight;
}
