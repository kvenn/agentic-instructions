# App Theming

> **Note**: This document uses example file paths from a real Flutter project to illustrate the architecture. Adapt the structure and naming to fit your specific project.

## Overview

- Centralized Material 3 theme generation lives in `lib/util/app_theme.dart`.
- Brand colors originate from `ColorPalette.brandSeed` to keep buttons and accents consistent.
- Theme preference defaults to dark mode and persists via `UserPreferencesService` so it syncs across devices.
- Users can switch between dark, light, and system appearance from the settings UI.

## Key Files

- `lib/util/app_theme.dart` — Builds light and dark `ThemeData` instances using the brand seed color.
- `lib/util/color_palette.dart` — Defines the deterministic color palette and exposes the shared brand seed.
- `lib/models/app_theme_preference.dart` — Enum mapping stored preference values to Flutter `ThemeMode` instances.
- `lib/services/preferences/user_preferences_service.dart` — Persists the theme preference and broadcasts changes through a `ValueNotifier`.
- `lib/features/settings/settings_page.dart` — Adds the settings UI for selecting the preferred theme.

## Behavior

- The app launches in dark mode when no preference is stored.
- Changing the preference updates `MaterialApp` through a `ValueListenableBuilder`, immediately re-theming the UI.
- Preferences synchronize through existing snapshot APIs so remote sync continues to function.
