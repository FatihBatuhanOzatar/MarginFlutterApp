import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';

/// Prompts for a list name with a hard-edged dialog (sharp corners, mono labels).
/// Returns the trimmed name, or null if cancelled or left empty.
Future<String?> promptListName(
  BuildContext context, {
  String? initial,
  String title = 'YENİ LİSTE',
}) async {
  final controller = TextEditingController(text: initial ?? '');
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
              title,
              style: AppFonts.mono(
                size: 11,
                weight: FontWeight.w700,
                letterSpacing: 2,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: c.accent,
              style: AppFonts.display(size: 20, weight: FontWeight.w700, color: c.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: 'Liste adı…',
                hintStyle:
                    AppFonts.display(size: 20, weight: FontWeight.w700, color: c.mut),
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
                    style: AppFonts.mono(size: 11, letterSpacing: 1.5, color: c.mut),
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

  final trimmed = result?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
