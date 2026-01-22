# Observability Architecture

> **Note**: This document uses example file paths and feature names from a real Flutter project to illustrate the architecture. Adapt the structure and naming to fit your specific project.

This app treats analytics + crash reporting as reusable modules so that new destinations can be registered without touching feature code.

## Layers

1. **Config** – `lib/observability/observability_config.dart` reads `dart-define` values (DSNs, tokens, feature flags) and describes the current runtime environment.
2. **Initializer** – `lib/observability/observability_initializer.dart` wires up providers once (Firebase, Sentry, Datadog), registers `AnalyticsService`, `CrashReportingService`, `ObservabilityUserScope`, and installs Flutter error handlers.
3. **Services** – `lib/analytics/analytics_service.dart` and `lib/crash/crash_reporting_service.dart` fan out to any number of destinations/reporters, expose handles for disabling/removing, and keep the core API app-agnostic.
4. **Destinations / Reporters** – Small adapters under `lib/analytics/destinations/` and `lib/crash/reporters/` translate the shared data model into provider-specific calls (Firebase Analytics, Sentry, Datadog, debug console, Crashlytics).
5. **Bindings** – `lib/observability/observability_bindings.dart` subscribes to `AppLifecycleObserver` so lifecycle changes emit analytics events and crash breadcrumbs.
6. **User scope** – `lib/observability/observability_user_scope.dart` keeps analytics + crash users in sync from `AuthService`.

## Analytics

- `AnalyticsService`
  - Registers destinations, tracks the latest `AnalyticsScreenView`, and enriches every `AnalyticsEvent` with screen metadata.
  - Provides `logEvent`, `trackScreen`, `updateAppLifecycle`, `updateUserProperties`, `clearUserProperties`, and `flush`.
  - Destinations can be toggled/removed at runtime via `AnalyticsDestinationHandle`.
- Destinations implemented:
  - `DebugAnalyticsDestination` – prints to console.
  - `FirebaseAnalyticsDestination` – enforces Firebase naming rules and user property limits.
  - `AmplitudeAnalyticsDestination` – sends events/user traits to Amplitude via the native SDK.
  - `PosthogAnalyticsDestination` – captures events/screens against a PostHog project.
  - `SentryAnalyticsDestination` – logs breadcrumbs so crash traces include recent actions.
  - `DatadogAnalyticsDestination` – forwards structured logs (requires `DatadogConfiguration`).
- App integration:
  - `AnalyticsNavigationObserver` is injected into `GoRouter` so every route push/pop becomes a screen view.
  - `lib/analytics/app_analytics_events.dart` exposes strongly-typed helpers (e.g., `logFeatureUsed`, `logActionCompleted`). Feature actions emit events with contextual properties.

## Crash Reporting

- `CrashReportingService`
  - Mirrors the analytics fan-out model with `CrashReporterHandle`s and convenience APIs (`recordError`, `recordFlutterError`, `recordBreadcrumb`, `setUserContext`).
  - Installs `FlutterError.onError` + `PlatformDispatcher.instance.onError` exactly once.
- Reporters implemented:
  - `DebugCrashReporter` – console output for local debugging.
  - `FirebaseCrashlyticsReporter` – honors `COLLECT_CRASHES_IN_DEBUG` and mirrors user metadata via custom keys.
  - `SentryCrashReporter` – captures exceptions/breadcrumbs with severity mapping.
  - `DatadogCrashReporter` – ships enriched error logs.
- `runZonedGuarded` in `main.dart` ensures uncaught zone errors flow through `CrashReportingService`.

## User + Lifecycle wiring

- `ObservabilityUserScope` is injected into `AuthService`; whenever sessions change (sign in/out, device-only session) it updates analytics user properties and crash user context in lockstep.
- `bindObservabilityLifecycle()` listens to `AppLifecycleObserver` so foreground/background transitions:
  - Toggle analytics lifecycle state + emit high-level events (`app_foregrounded`, `app_backgrounded`).
  - Add crash breadcrumbs for better post-mortem context.

## Adding another destination or reporter

1. Create a class that extends `AnalyticsDestination` or `CrashReporter` under the respective `destinations/` or `reporters/` folder.
2. Register it inside `ObservabilityInitializer._registerAnalyticsDestinations` or `_registerCrashReporters`. Because each service returns handles you can also register dynamically elsewhere if needed.
3. If the provider needs extra configuration, extend `ObservabilityConfig` (add a new `dart-define`) and feed it through the initializer.

## Environment configuration

Prod/staging builds enable analytics + crash reporting automatically; dev builds keep them off unless you override the `ENABLE_*` flags. The `run-observability` just command (below) wires everything up from `.env` so you only need to care about secrets/tokens.

Set these `dart-define`s per flavor/deployment:

| Key                           | Purpose                                                 | Default                                               |
| ----------------------------- | ------------------------------------------------------- | ----------------------------------------------------- |
| `DATADOG_CLIENT_TOKEN`        | Enables Datadog logging/crash reporting when non-empty. | _disabled_                                            |
| `DATADOG_APPLICATION_ID`      | Optional: turns on Datadog RUM.                         | _disabled_                                            |
| `SENTRY_DSN`                  | Enables Sentry analytics + crash reporters when set.    | _disabled_                                            |
| `ENABLE_ANALYTICS`            | Force-enable analytics in dev/test builds.              | defaults to `true` on prod/staging, `false` otherwise |
| `ENABLE_CRASH_REPORTING`      | Force-enable crash reporting in dev/test builds.        | defaults to `true` on prod/staging, `false` otherwise |
| `ENABLE_FIREBASE_ANALYTICS`   | Toggles Firebase Analytics destination.                 | falls back to `ENABLE_ANALYTICS`                      |
| `ENABLE_FIREBASE_CRASHLYTICS` | Toggles Crashlytics destination.                        | falls back to `ENABLE_CRASH_REPORTING`                |
| `ENABLE_DEBUG_OBSERVABILITY`  | Adds console destinations (useful locally).             | `true` outside prod/staging                           |
| `COLLECT_CRASHES_IN_DEBUG`    | Allows Crashlytics to collect crashes while debugging.  | `false`                                               |
| `AMPLITUDE_API_KEY`           | Enables the Amplitude destination.                      | _disabled_                                            |
| `POSTHOG_API_KEY`             | Enables the PostHog destination.                        | _disabled_                                            |

- Flutter Web embeds Amplitude's Browser SDK 2 snippet (see `web/index.html`) so Amplitude 4.x can track browser sessions without the legacy script.

### CLI shortcuts

- `just run-observability` launches `flutter run` with every required `--dart-define`, reading tokens/flags from `.env` (in prod everything is on; in dev set the `ENABLE_*` vars if you need observability).
- `just build-ipa` automatically applies the same define set so release builds go out with the correct configuration.

### CI / GitHub Actions

- The Firebase Hosting workflows export every repository secret as an environment variable, then automatically turn any secret that starts with `DART_DEFINE_` into a `--dart-define`. For example, a secret named `DART_DEFINE_DATADOG_CLIENT_TOKEN` becomes `--dart-define=DATADOG_CLIENT_TOKEN=...` during `flutter build web`.
- Keep your production tokens/DSNs in GitHub Secrets with the `DART_DEFINE_` prefix to ensure the deploys pick them up without editing the workflow.

Add the defines to your launch configs (`flutter run --dart-define=...`) or CI/CD secrets as needed.
