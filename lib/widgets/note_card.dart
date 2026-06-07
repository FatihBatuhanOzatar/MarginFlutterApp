import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import 'app_icons.dart';
import 'hard_button.dart';

/// "KENAR NOTU" — the curator note. Shows the saved note with an edit affordance
/// when one exists, otherwise an inline editor capped at 400 characters. Owns its
/// own draft/editing state and reports a committed note via [onSave].
class NoteCard extends StatefulWidget {
  const NoteCard({super.key, required this.note, required this.onSave});

  final String note;
  final ValueChanged<String> onSave;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  static const _maxLength = 400;

  late final TextEditingController _controller =
      TextEditingController(text: widget.note);
  late bool _editing = widget.note.trim().isEmpty;

  @override
  void didUpdateWidget(NoteCard old) {
    super.didUpdateWidget(old);
    if (old.note != widget.note) {
      _controller.text = widget.note;
      _editing = widget.note.trim().isEmpty;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onSave(value);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final hasNote = widget.note.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: c.line2),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: hasNote && !_editing ? _readView(c) : _editView(c),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(16, 16),
              painter: _FoldPainter(c.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readView(MarginColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.note,
          style: AppFonts.body(
            size: 16,
            height: 1.55,
            fontStyle: FontStyle.italic,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => setState(() => _editing = true),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.accent)),
            ),
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'NOTU DÜZENLE',
              style: AppFonts.mono(size: 10, letterSpacing: 1.6, color: c.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _editView(MarginColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLength: _maxLength,
          maxLines: null,
          minLines: 4,
          cursorColor: c.accent,
          style: AppFonts.body(
            size: 16,
            height: 1.55,
            fontStyle: FontStyle.italic,
            color: c.ink,
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            counterText: '',
            hintText:
                'Bunu neden işaretledin? Gelecekteki sana bir not bırak…',
            hintStyle: AppFonts.body(
              size: 16,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: c.mut,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_controller.text.length}/$_maxLength',
                style: AppFonts.mono(size: 10, letterSpacing: 1.0, color: c.mut),
              ),
              HardButton(
                label: 'NOTU KAYDET',
                icon: AppIconKind.plus,
                small: true,
                enabled: _controller.text.trim().isNotEmpty,
                onTap: _save,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The little accent dog-ear in the top-right corner of the note card.
class _FoldPainter extends CustomPainter {
  _FoldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FoldPainter old) => old.color != color;
}
