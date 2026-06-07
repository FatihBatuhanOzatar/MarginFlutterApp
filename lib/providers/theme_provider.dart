import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/palettes.dart';

/// Holds the active palette (Karanlık/Kağıt) and accent color, persisting both
/// to storage so the user's choice survives restarts. Drives the app's
/// [ThemeData] via [themeData].
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._storage)
      : _palette = AppPalette.byName(_storage.themeModeName()),
        _accent = _storage.accentValue() == null
            ? kAccentDefault
            : Color(_storage.accentValue()!);

  final StorageService _storage;

  AppPalette _palette;
  Color _accent;

  AppPalette get palette => _palette;
  Color get accent => _accent;
  bool get isDark => _palette.brightness == Brightness.dark;
  ThemeData get themeData => buildMarginTheme(_palette, _accent);

  Future<void> setPalette(AppPalette palette) async {
    if (palette.name == _palette.name) return;
    _palette = palette;
    notifyListeners();
    await _storage.setThemeModeName(palette.name);
  }

  Future<void> setAccent(Color accent) async {
    if (accent.toARGB32() == _accent.toARGB32()) return;
    _accent = accent;
    notifyListeners();
    await _storage.setAccentValue(accent.toARGB32());
  }
}
