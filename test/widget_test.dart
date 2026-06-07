import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:margin/main.dart';
import 'package:margin/providers/catalog_provider.dart';
import 'package:margin/providers/saved_provider.dart';
import 'package:margin/providers/search_provider.dart';
import 'package:margin/providers/theme_provider.dart';
import 'package:margin/services/palette_cache.dart';
import 'package:margin/services/storage_service.dart';
import 'package:margin/services/tmdb_api.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('margin_test');
    Hive.init(tempDir.path);
    storage = await StorageService.open();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('App boots and shows the brand mark', (tester) async {
    final api = TmdbApi();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
          ChangeNotifierProvider(create: (_) => CatalogProvider(api, storage)),
          ChangeNotifierProvider(create: (_) => SavedProvider(storage)),
          ChangeNotifierProvider(create: (_) => SearchProvider(api, storage)),
          ChangeNotifierProvider(create: (_) => PaletteCache()),
        ],
        child: const MarginApp(),
      ),
    );
    await tester.pump();
    expect(find.text('MARGIN'), findsOneWidget);
  });
}
