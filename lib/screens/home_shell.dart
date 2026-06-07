import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/empty_block.dart';
import 'browse_screen.dart';
import 'search_screen.dart';

/// The app frame: an [IndexedStack] of the three tabs (İNDEKS · ARA · ARŞİV)
/// behind a [BottomNav]. Keeping the stack alive preserves each tab's scroll
/// position and state when switching.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _select(int tab) => setState(() => _tab = tab);

  // The slide-up detail route is wired in once the detail screen exists.
  void _open(MediaItem item) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            BrowseScreen(onOpen: _open, onSearch: () => _select(1)),
            SearchScreen(active: _tab == 1, onOpen: _open),
            const _ComingSoon('ARŞİV'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(index: _tab, onTap: _select),
    );
  }
}

/// Interim placeholder for tabs not yet built.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyBlock(glyph: '◴', title: label, sub: 'Yakında'),
    );
  }
}
