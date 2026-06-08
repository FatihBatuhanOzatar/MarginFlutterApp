import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import '../widgets/app_icons.dart';

/// Opens a preview of a share [card] that the user can export as a PNG through
/// the OS share sheet. [shareText] accompanies the image.
void showSharePreview(
  BuildContext context, {
  required Widget card,
  required String shareText,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _SharePreviewScreen(card: card, shareText: shareText),
    ),
  );
}

class _SharePreviewScreen extends StatefulWidget {
  const _SharePreviewScreen({required this.card, required this.shareText});

  final Widget card;
  final String shareText;

  @override
  State<_SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<_SharePreviewScreen> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  /// Rasterizes the card boundary to a PNG and hands it to the OS share sheet.
  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/margin_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(data.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: widget.shareText),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(c),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(color: c.line2)),
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: widget.card,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: GestureDetector(
                onTap: _share,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: c.accent, border: Border.all(color: c.accent)),
                  child: Center(
                    child: Text(
                      _busy ? 'HAZIRLANIYOR…' : 'GÖRSELİ PAYLAŞ',
                      style: AppFonts.mono(
                        size: 12,
                        weight: FontWeight.w700,
                        letterSpacing: 1.92,
                        color: c.accentInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PAYLAŞ',
            style: AppFonts.display(
                size: 22, weight: FontWeight.w700, letterSpacing: -0.4, color: c.ink),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: c.line2)),
              child: AppIcon(AppIconKind.close, size: 16, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
