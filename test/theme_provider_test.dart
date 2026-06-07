import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:margin/providers/theme_provider.dart';
import 'package:margin/services/storage_service.dart';
import 'package:margin/theme/palettes.dart';

/// Theme preferences must survive a restart — a fresh [ThemeProvider] over the
/// same storage should read back the palette and accent the user picked.
void main() {
  late Directory dir;
  late StorageService storage;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('margin_theme');
    Hive.init(dir.path);
    storage = await StorageService.open();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('defaults to the dark palette and the default accent', () {
    final theme = ThemeProvider(storage);
    expect(theme.palette.name, AppPalette.dark.name);
    expect(theme.isDark, isTrue);
    expect(theme.accent.toARGB32(), kAccentDefault.toARGB32());
  });

  test('persists palette and accent across instances', () async {
    final first = ThemeProvider(storage);
    await first.setPalette(AppPalette.paper);
    await first.setAccent(kAccentOptions[2]);

    final reopened = ThemeProvider(storage);
    expect(reopened.palette.name, 'Kağıt');
    expect(reopened.isDark, isFalse);
    expect(reopened.accent.toARGB32(), kAccentOptions[2].toARGB32());
  });
}
