import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';

/// Prompts for a ranked entry's custom label (a character, a song, a scene…).
/// Unlike the list-name prompt, an empty value is allowed and *clears* the label
/// (the entry falls back to showing its title). Returns the trimmed text on save
/// — possibly empty — or null when cancelled.
Future<String?> promptEntryLabel(
  BuildContext context, {
  String initial = '',
}) async {
  final controller = TextEditingController(text: initial);
  final c = context.margin;

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: c.bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: c.line2),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ETİKET',
              style: AppFonts.mono(
                size: 11,
                weight: FontWeight.w700,
                letterSpacing: 2,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bu başlığın bir yönünü sırala — karakter, müzik, sahne… Boş bırakırsan etiket silinir.',
              style: AppFonts.body(size: 12.5, height: 1.4, color: c.mut),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: c.accent,
              style:
                  AppFonts.display(size: 20, weight: FontWeight.w700, color: c.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: 'örn. Light Yagami',
                hintStyle: AppFonts.display(
                    size: 20, weight: FontWeight.w700, color: c.mut),
                enabledBorder:
                    UnderlineInputBorder(borderSide: BorderSide(color: c.line2)),
                focusedBorder:
                    UnderlineInputBorder(borderSide: BorderSide(color: c.accent)),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'VAZGEÇ',
                    style:
                        AppFonts.mono(size: 11, letterSpacing: 1.5, color: c.mut),
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(controller.text),
                  child: Text(
                    'KAYDET',
                    style: AppFonts.mono(
                      size: 11,
                      weight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: c.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return result?.trim();
}
