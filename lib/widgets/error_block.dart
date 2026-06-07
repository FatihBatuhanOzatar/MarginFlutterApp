import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import 'app_icons.dart';
import 'hard_button.dart';

/// Stark, centered failure state with a retry action. Shown when the catalog
/// can't be fetched and there's no cache to fall back on.
class ErrorBlock extends StatelessWidget {
  const ErrorBlock({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: c.accent)),
            child: AppIcon(AppIconKind.alert, size: 26, color: c.accent),
          ),
          const SizedBox(height: 14),
          Text(
            'ERR · TMDB',
            style: AppFonts.mono(size: 10, letterSpacing: 2.2, color: c.accent),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              message ?? 'Veri çekilemedi. Bağlantını kontrol et.',
              textAlign: TextAlign.center,
              style: AppFonts.body(size: 14, height: 1.5, color: c.mut),
            ),
          ),
          const SizedBox(height: 14),
          HardButton(
            label: 'TEKRAR DENE',
            icon: AppIconKind.retry,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
