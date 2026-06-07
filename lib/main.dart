import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/catalog_provider.dart';
import 'providers/saved_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'services/tmdb_api.dart';
import 'theme/app_theme.dart';
import 'theme/grain.dart';
import 'theme/text_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const _ThemePreview(),
    );
  }
}

/// Temporary landing screen that proves the theme/fonts/grain load.
/// Replaced by the real home shell in a later step.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MARGIN',
                  style: AppFonts.display(
                    size: 48,
                    letterSpacing: -1.4,
                    height: 0.85,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'KİŞİSEL EKRAN İNDEKSİ',
                  style: AppFonts.mono(
                    size: 10,
                    letterSpacing: 2.6,
                    color: c.mut,
                  ),
                ),
                const SizedBox(height: 24),
                Container(width: 40, height: 3, color: c.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
