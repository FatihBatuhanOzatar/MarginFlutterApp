# MARGIN

A movie / TV / anime explorer built with **Flutter**, powered by the **TMDB API**.
Editorial, brutalist UI with a personal twist: save titles to your archive and leave a
"margin note" on each one.

> Course project for *Mobile Application Development (Flutter)*.

## Features

- Browse top-rated **films, TV shows and anime** (TMDB).
- **Search** by title, cast or genre, with recent-search history.
- **Detail** page: synopsis, cast, genres, rating, and an editable **margin note**.
- **Archive**: your saved collection, stored locally.
- **Dark / Paper** themes with a selectable accent color.
- Loading, error and empty states; offline cache; animations.

## Tech

Flutter · Provider (state) · Hive (local storage) · `http` (REST) ·
`cached_network_image` · `palette_generator` · `google_fonts`.

## Getting started

This app needs a free **TMDB API key (v3 auth)** — get one at
<https://www.themoviedb.org/settings/api>.

The key is **not** committed to the repo; pass it at runtime:

```bash
flutter pub get
flutter run --dart-define=TMDB_KEY=your_key_here
```

> The code reads the key via `String.fromEnvironment('TMDB_KEY')`.

## Project structure

```
lib/
  theme/      design tokens, palettes, typography
  models/     MediaItem, CastMember, TMDB genre maps
  services/   TMDB REST client, Hive storage
  providers/  theme, catalog, saved, search state
  widgets/    reusable UI pieces (poster, hero, chips, states…)
  screens/    browse, search, detail, saved, settings
```
