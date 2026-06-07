import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The three typefaces from the prototype, exposed as thin helpers so screens
/// compose their own sizes/weights without importing google_fonts everywhere.
///
/// - [display] → Syne: brand mark, poster & hero titles.
/// - [mono]    → JetBrains Mono: labels, meta, counters, indices.
/// - [body]    → Archivo: overviews, notes, paragraph text.
abstract final class AppFonts {
  static TextStyle display({
    double? size,
    FontWeight weight = FontWeight.w800,
    double? height,
    double? letterSpacing,
    Color? color,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.syne(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
        fontStyle: fontStyle,
      );

  static TextStyle mono({
    double? size,
    FontWeight weight = FontWeight.w500,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle body({
    double? size,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    Color? color,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
        fontStyle: fontStyle,
      );

  /// Material [TextTheme] used as the app default so stray [Text] widgets
  /// inherit the body face and the current [ink] color.
  static TextTheme textTheme(Color ink) => GoogleFonts.archivoTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).apply(bodyColor: ink, displayColor: ink);
}
