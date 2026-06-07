import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/palettes.dart';
import '../theme/text_styles.dart';
import '../widgets/app_icons.dart';
import '../widgets/section_line.dart';

/// AYARLAR — the in-app surface for the prototype's dev tweak panel: pick the
/// palette (Karanlık/Kağıt) and the accent color. Both persist via [ThemeProvider].
///
/// Pushed with a short fade so it reads as a settings overlay rather than a
/// peer screen in the bottom-nav stack.
Route<void> settingsRoute() {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => const SettingsScreen(),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _topBar(context, c),
              const SectionLine(label: 'TEMA'),
              _paletteRow(c, theme),
              const SectionLine(label: 'AKSAN'),
              _accentRow(c, theme),
              const SectionLine(label: 'HAKKINDA'),
              _about(c),
              _footer(c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, MarginColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AYARLAR',
                style: AppFonts.display(
                  size: 30,
                  letterSpacing: -0.9,
                  height: 0.85,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'GÖRÜNÜM VE TERCİHLER',
                style: AppFonts.mono(size: 9.5, letterSpacing: 2.47, color: c.mut),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: c.line2)),
              child: AppIcon(AppIconKind.close, size: 18, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paletteRow(MarginColors c, ThemeProvider theme) {
    final palettes = AppPalette.all;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < palettes.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _PaletteCard(
              palette: palettes[i],
              accent: theme.accent,
              active: palettes[i].name == theme.palette.name,
              onTap: () => theme.setPalette(palettes[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _accentRow(MarginColors c, ThemeProvider theme) {
    final selected = theme.accent.toARGB32();
    return Row(
      children: [
        for (var i = 0; i < kAccentOptions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _AccentSwatch(
              color: kAccentOptions[i],
              active: kAccentOptions[i].toARGB32() == selected,
              borderColor: c.line2,
              onTap: () => theme.setAccent(kAccentOptions[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _about(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MARGIN — film, dizi ve anime için kişisel bir keşif ve arşiv '
            'defteri. Ara, incele, koleksiyonuna ekle ve kendi notunu bırak.',
            style: AppFonts.body(
              size: 13,
              height: 1.6,
              color: c.ink.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'VERİ · THE MOVIE DATABASE (TMDB)',
            style: AppFonts.mono(size: 10, letterSpacing: 1.2, color: c.mut),
          ),
        ],
      ),
    );
  }

  Widget _footer(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 18),
      child: Text(
        'TMDB · THE MOVIE DATABASE',
        textAlign: TextAlign.center,
        style: AppFonts.mono(
          size: 9.5,
          letterSpacing: 1.71,
          color: c.mut.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// A selectable theme preview: a miniature of the palette (title bar, meta bar,
/// accent chip) over its real background, with the name below. The active card
/// is ringed in the current accent.
class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.palette,
    required this.accent,
    required this.active,
    required this.onTap,
  });

  final AppPalette palette;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? accent : c.line2,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 78,
              color: palette.bg,
              padding: const EdgeInsets.all(13),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 9, width: double.infinity, color: palette.ink),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(height: 6, width: 44, color: palette.mut),
                      const Spacer(),
                      Container(width: 14, height: 14, color: accent),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Text(
                palette.name.toUpperCase(),
                style: AppFonts.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: active ? c.ink : c.mut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One accent option: a solid swatch that shows a contrast-aware check when it
/// is the active accent.
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.active,
    required this.borderColor,
    required this.onTap,
  });

  final Color color;
  final bool active;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: active ? c.ink : borderColor,
            width: active ? 2 : 1,
          ),
        ),
        child: active
            ? Text(
                '✓',
                style: TextStyle(
                  color: inkOn(color),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }
}
