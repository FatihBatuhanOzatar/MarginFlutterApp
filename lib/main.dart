import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/catalog_provider.dart';
import 'providers/saved_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_shell.dart';
import 'services/storage_service.dart';
import 'services/tmdb_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR'); // Turkish month names for note stamps
  final storage = await StorageService.init();
  runApp(MarginRoot(storage: storage, api: TmdbApi()));
}

/// Owns the singletons (storage + API client) and exposes every provider to the
/// tree. Kept separate from [MarginApp] so the app widget itself is trivial.
class MarginRoot extends StatelessWidget {
  const MarginRoot({super.key, required this.storage, required this.api});

  final StorageService storage;
  final TmdbApi api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TmdbApi>.value(value: api),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => CatalogProvider(api, storage)),
        ChangeNotifierProvider(create: (_) => SavedProvider(storage)),
        ChangeNotifierProvider(create: (_) => SearchProvider(api, storage)),
      ],
      child: const MarginApp(),
    );
  }
}

class MarginApp extends StatelessWidget {
  const MarginApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'MARGIN',
      debugShowCheckedModeBanner: false,
      theme: theme.themeData,
      home: const HomeShell(),
    );
  }
}
