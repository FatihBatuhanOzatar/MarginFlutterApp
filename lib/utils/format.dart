import 'package:intl/intl.dart';

/// Zero-pads a number to two digits (`7` → `"07"`), used for the editorial
/// indices and counters throughout the UI.
String pad2(int n) => n.toString().padLeft(2, '0');

/// Turkish long date (`07 Haz 2026`) for the curator-note timestamp.
String formatStamp(DateTime date) =>
    DateFormat('dd MMM yyyy', 'tr_TR').format(date);
