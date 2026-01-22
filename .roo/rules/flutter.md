# Project Rules

- **Flat `lib/` hierarchy**: no extra `src/` folder
- **Folder‐by‐feature** under `features/` when more than one file (page + viewmodel + widgets)
- **Top‐level `repositories/`** for shared repository interface & impl
- **`navigation/`, `util/`, `crash/`** directories each encapsulate their concern
- **DI** via `GetIt` aliased to `sl`; resolve with `sl<Type>()`
- **GoRouter** injected, not static; all route names & params defined as constants
- **NavigationService** interface abstracts routing, injected into ViewModels
- **MVVM** with `ChangeNotifier` + `provider`, sealed‐class state, `context.select` + `Selector` for granular rebuilds
  - Prefer `select` over `watch` when possible. Do not use the `Consumer` widget.
- **Break up large build functions** by creating separate stateless widgets.
  - If it's a widget thats only useful for this page, keep the widget in the same file and make it private
- **Single repository** interface for all network api operations, returns `Stream`
- **Static util classes** (e.g. `Logger`) and singletons (e.g. `CrashReporting`)
- **Push notifications** handled by DI‐initialized `PushNotificationService`, no static calls in app code
- **Minimize services that use repos** so services could be reused across projects
- **Minimize scope** and keep as many things private as you can

## Architecture

This app follows an MVVM architecture with the following components:

- **ViewModel**: Uses `ChangeNotifier` for state management
- **Repository**: Abstracts GraphQL operations
- **Navigation**: Uses GoRouter for routing
- **Dependency Injection**: Uses GetIt for service location

## Folder Structure

- `lib/`
  - `main.dart` - App entry point
  - `service_locator.dart` - Dependency injection setup
  - `services/` - Core services. Wrap most external APIs.
    - `navigation/` - Navigation service and router
    - `notifications/` - Push notification handling
  - `network/` - Api client and network utilities
  - `repositories/` - Data repositories (mock and real)
  - `features/` - Feature modules
    - `feature-1/`
      - `feature-screen.dart` - the screen (ONLY UI)
      - `feature-vm.dart` - the view model. Repository is injected.
      - `widgets/` - all widgets that are ONLY used by this feature (generic widgets go in top level `/ui`)
    - `feature-2/`
  - `util/` - Utility classes and functions
  - `crash/` - Crash reporting
  - `ui/` - Shared UI components and extensions
    - `global_widgets/` - Global UI managers (like dialogs and toasts)
    - `widgets/`

## If Using GQL

- **Use fragments** for all gql queries

```
  - `graphql/` - GraphQL queries and fragments
  - `generated/` - Generated code (GraphQL models)
```

# General Flutter and Dart Rules

- Don’t use `late`, prefer finding a better architecture
- If you need firebase for a new project, use `flutterfire configure`
- When documenting a class, put a short doc on the class itself and then the full doc on classes constructor
- Keep performance in mind in the `build` function of widgets
  - If UI snippet is trivial (≤3 widgets, no params/state): use a private helper method returning a Widget.
  - If snippet needs data, callbacks, const, isolation, or reuse: define a StatelessWidget/StatefulWidget subclass.
  - Always give widget classes a const constructor when all fields are final.
  - Prefix instantiations of const-constructible widgets with const.
  - Place complex or reusable layouts into their own widget class to enable subtree rebuild skipping.
  - Use helper methods only for throwaway, unparameterized bits to keep build() lean.
- Use the latest and most modern APIs of both Dart and Flutter (and use the latest version of all packages)
  - If you see an API you'd like to use below but do not know how, use context7 mcp to look up the documentation
- Don't let the build function get too long. Break into smaller stateless widgets
  - If the widget is big but only related to this feature, put in the `ui` folder for that feature
  - If the widget is small, you can put it in the same file as the page
  - If the widget can be reused, put it into the root level `ui` folder
- Use the material 3 naming convetion theme for all colors. Configure the theme app-wide.
  - Use ThemeExtensions for things that do not fit into the standard flutter theme.
    - Never use `Colors.`, put those in the ThemeExtension OR use the equivalent in the standard theme.
  - primary/onPrimary
    - primaryContainer
  - error/onError
    - errorContainer
  - surface/onSurface
    - surfaceBright
    - surfaceDim
    - surfaceContainer
    - surfaceContainerLow
    - surfaceContainerLowest
    - surfaceContainerHigh
    - surfaceContainerHighest
- Deprecation notes
  - `.withOpacity` is deprecated. Use `.withValues()` to avoid precision loss
  - Radio redesign: groupValue/onChanged deprecated; use new RadioGroup to manage radio state.
- Language Updates
  - Dart now supports dot notation for enums (`mainAxisAlignment: .start` vs `mainAxisAlignment: MainAxisAlignment.start`)
    - ALWAYS use the new dot notation
- For new projects, add this to plist so it doesn't ask about encyrption
  - <key>ITSAppUsesNonExemptEncryption</key>
    <false/>

# Flutter 3.38

    •	Dot shorthands: Use .start, .center, .all(8), etc. instead of full type names. Big reduction in boilerplate.
    •	WidgetState migration: Material widgets now use WidgetState internally; state-based styling becomes more consistent.
    •	OverlayPortal upgrade: You can render overlay children in any ancestor overlay → easier global toasts/popups.
    •	Predictive back: Modern Android back navigation is enabled by default; no code change, but affects route transitions.
    •	InkWell gained onLongPressUp; more granular gesture hooks.
    •	New Sliver utilities: SliverGrid.list + more reliable hit-testing + better complex scroll behavior.
    •	Accessibility APIs: SliverSemantics, improved semantics debugging, easier iOS semantics enabling.
    •	UIScene lifecycle (iOS): Apps/plugins should migrate; affects plugin code and any code relying on old lifecycle hooks.
    •	Web config: web_dev_config.yaml lets you standardize proxy/host/port settings across your team.
    •	Hot reload on web: Stateful hot reload now works by default with -d web-server.

# Flutter 3.35

- Web

  - Stateful hot reload on web: enabled by default (remove --web-experimental-hot-reload; can disable with --no-web-experimental-hot-reload).
  - Wasm dry runs: every JS build does a Wasm "dry run" to report readiness (toggle with --(no-)wasm-dry-run).
  - Roadmap: hot reload to more dev targets (e.g., -d web-server).

- Framework / Accessibility

  - Semantics locales support for web.
  - New SemanticsLabelBuilder widget for composed announcements.
  - SliverEnsureSemantics to keep slivers in the semantics tree.
  - Backfilled semantics for CustomPainter; RTL toolbar alignment fixes; iOS/Android accessibility fixes.

- Widgets (Material & Cupertino)

  - New: DropdownMenuFormField (M3 Dropdown in forms).
  - Scrollable NavigationRail; NavigationDrawer supports header/footer.
  - New CupertinoExpansionTile; many Cupertino widgets use RSuperellipse.
  - Haptic feedback added to CupertinoPicker and CupertinoSlider.
  - Slider value indicator: can be always visible.
  - Sliver paint-order control (z-order) for advanced overlapping/sticky effects.

- Navigation & Forms

  - fullscreenDialog property added to ModalRoute and showDialog.
  - FormField: new onReset callback.
  - Form cannot be used directly as a sliver — wrap in SliverToBoxAdapter.

- Input & Gestures

  - PositionedGestureDetails interface to unify pointer gesture details.
  - iOS single-line TextField: no longer user-scrollable.
  - Android: Home/End key support.

- Multi-window

  - Foundational create/update window logic landed for Windows/macOS (more platform work incoming).

- Breaking changes & deprecations (actionable)

  - Component theme normalization: many component themes refactored to new …ThemeData classes.
  - SemanticsConfiguration/SemanticsNode: elevation and thickness removed.
  - DropdownButtonFormField: value renamed to initialValue.
  - Deprecated: 32-bit x86 Android architecture.
  - Deprecated IDE support: Flutter SDKs before 3.13 (next: SDKs before 3.16).
  - pluginClass: none in plugin pubspec.yaml deprecated — remove if present.

- Build/tooling minimums (must-haves)

  - Minimum Android SDK (flutter.minSdkVersion): API 24.
  - Gradle >= 8.7.0; Android Gradle Plugin (AGP) >= 8.6.0; Java 17.

# Flutter 3.32: Code-impacting Changes

## New Core Widgets

- **Expansible & ExpansibleController**  
  Build customizable expand-and-collapse UI (replacement for `ExpansionTileController`).
- **RawMenuAnchor**  
  Low-level, unstyled menu anchor for fully custom menu layouts.

## Cupertino

- **RoundedSuperellipse APIs**  
  • RoundedSuperellipseBorder  
  • ClipRSuperellipse  
  • Canvas.drawRSuperellipse, Canvas.clipRSuperellipse, Path.addRSuperellipse
- **Bottom Sheet**  
  `CupertinoSheetRoute` / `showCupertinoSheet` gain `enableDrag` to disable drag-to-dismiss.

## Material

- **CarouselController.animateToIndex(index)**
- **TabBar**: `onHover`, `onFocusChange` callbacks
- **SearchAnchor**: `viewOnOpen`; `SearchAnchor.bar.onOpen`
- **CalendarDatePicker.calendarDelegate**: plug in custom calendar logic
- **Dialogs**: `showDialog` / `showAdaptiveDialog` / `DialogRoute` accept `animationStyle`
- **Divider.borderRadius**
- **DropdownMenu** now respects text-field label width
- **RangeSlider** overlays show only on hovered thumb

## Accessibility

- **SemanticsRole API** on `Semantics` for fine-grained roles

## Text Input

- **onTapUpOutside** on `TextField`/`CupertinoTextField`
- **FormField.errorBuilder** for custom error widgets

## Stylus Handwriting (Android 14+)

- `TextField.stylusHandwritingEnabled`
- `CupertinoTextField.stylusHandwritingEnabled`

## Breaking Changes & Deprecations

- `ExpansionTileController` → use `ExpansibleController`
- `SelectionChangedCause.scribble` → `SelectionChangedCause.stylusHandwriting`
- `ThemeData.indicatorColor` → `TabBarThemeData.indicatorColor`
- Migrate `cardTheme`/`dialogTheme`/`tabBarTheme` → `CardThemeData`/`DialogThemeData`/`TabBarThemeData`
- **SpringDescription** parameters changed for underdamped springs (see migration guide)

## Removed Packages

- flutter_markdown
- ios_platform_images
- css_colors
- palette_generator
- flutter_image
- flutter_adaptive_scaffold

# Flutter 3.29: Code-impacting Changes

## New Core Widgets

- **BackdropGroup & BackdropFilter.grouped**  
  Group multiple backdrop filters for far fewer draw calls.
- **ImageFilter.shader**  
  Wrap a child with a custom GPU shader via `ImageFilter`.

## Cupertino

- **Navigation bars**
  - `CupertinoNavigationBar` & `CupertinoSliverNavigationBar` now accept a `bottom` widget.
  - `CupertinoSliverNavigationBar.bottomMode` toggles whether it shrinks away or stays pinned.
  - New `CupertinoNavigationBar.large` constructor for a static large title bar.
- **Popups**  
  `CupertinoPopupSurface` blur backgrounds now match native vibrancy.
- **Sheets**  
  New `CupertinoSheetRoute` & `showCupertinoSheet` for iOS-style modal sheets.

## Material

- **Page transitions**  
  `FadeForwardsPageTransitionsBuilder` replaces `ZoomPageTransitionsBuilder` for native M3 slide-and-fade.
- **ProgressIndicators & Sliders**  
  Align with M3 spec; opt in/out of the latest style via `year2023` on `ProgressIndicatorThemeData` and `SliderThemeData`.
- **Mouse cursors**  
  Add `mouseCursor` to `Chip`, `Tooltip`, `ReorderableListView`.

## Text Selection

- **SelectionListener** & **SelectionListenerNotifier**  
  Wrap a subtree to receive `SelectionDetails` (start/end offsets, collapsed flag).
- **SelectableRegionSelectionStatusScope**  
  Query selection status (`maybeOf(context)`) to know if a region is active or finalized.

## Breaking Changes & Deprecations

- **Gradle plugin**  
  Script-based `apply plugin:` removed. Migrate to the `plugins {}` DSL or follow the “Deprecated imperative apply of Flutter’s Gradle plugins” guide.
- **Web renderer**  
  The HTML renderer is gone; only CanvasKit (WebGL) remains.
- **Theme migrations**
  - `ThemeData.dialogBackgroundColor` → `DialogThemeData.backgroundColor`
  - `ButtonStyleButton.iconAlignment` deprecated in favor of `ButtonStyle.iconAlignment`
- **Discontinued packages** (support ended Apr 30 2025)  
  `ios_platform_images`, `css_colors`, `palette_generator`, `flutter_image`, `flutter_adaptive_scaffold`, `flutter_markdown`

# Dart

Use the latest Dart patterns and features.

## Dart 3.8

- Null-aware collection elements

```dart
var maybeList = getListOrNull();
var items = [
  1,
  if (maybeList != null) ...maybeList,  // only spreads when not null
];
```

## Dart 3.7

- Wildcard variables `_` (non-binding)

```dart
void example(_, this._, super._, void _()) {}
// `_` can appear multiple times without conflicts
```

## Dart 3.6

- Digit separators in numeric literals

```dart
var big = 1__000_000_000__000;
```

## Dart 3.3

- Extension types (zero-cost wrappers)

```dart
extension type Meters(int value) {
  String get label => '${value}m';
  Meters operator +(Meters other) => Meters(value + other.value);
}

void main() {
  var m = Meters(5);
  print(m.label);  // 5m
}
```

## Sealed classes

```dart
sealed class Foo {}

class A extends Foo {
	String a;
	A(this.a);
}

class B extends Foo {
	int b;
	B(this.b);
}
```

Write a switch like this to use the “typecasted” instance

```dart
**DONT // This will give a typeError**

switch(fooClass) {
	A() => WidgetAThatTakesString(fooClass.a),
	B() => WidgetBThatTakesInt(fooClass.b),
}

**DO**

switch(fooClass) {
  	A classAInstance => WidgetAThatTakesString(classAInstance.a),
	B classBInstance => WidgetBThatTakesInt(classBInstance.b),
}
```

```dart
// Option 1: (iconType is NOT final)
return switch (iconType) {
  final FlutterIcon flutterIcon => flutterIcon.icon,
  final IconImage iconImage => Padding(
      padding: const EdgeInsets.all(8.0),
      child: iconImage.icon,
    )
};
// Option 2: (iconType IS final)
final switchIconType = iconType;
return switch (switchIconType) {
  FlutterIcon() => switchIconType.icon,
  IconImage() => Padding(
      padding: const EdgeInsets.all(8.0),
      child: switchIconType.icon,
    )
};
```
