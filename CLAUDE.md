# CLAUDE.md

Guidance for AI agents working in this repo. Keep it current when the
architecture or release process changes.

## What this is

A Flutter **quotes** app (Android, iOS, macOS, Linux, Windows). Users browse
quotes by topic, favorite them, and share them. Quotes are fetched from a remote
backend on first launch and cached in a local SQLite database so the app works
offline afterward.

- Android application id / package: `com.zcreations.quotes`
- Version lives in `pubspec.yaml` as `version: <name>+<build>` (e.g. `6.0.3+13`).

## Architecture

Small app, no state-management framework beyond `provider`.

- **`lib/main.dart`** — root `MyApp` + `MyHomePage`. Wraps the app in a single
  `ChangeNotifierProvider<Processor>`. `MyHomePage.onStart()` (called from
  `initState`) drives the whole first-launch data flow. The topic grid renders
  from `Processor.topics`; a `CircularProgressIndicator` shows until topics load.
- **`lib/engine.dart`** — `Processor extends ChangeNotifier`. This is the core:
  all networking, all SQLite access, sharing, and selection/favorite logic. Call
  `notifyListeners()` after mutating state so the UI rebuilds.
- **`lib/models/quote.dart`** — `Quote` model (`quote`, `author`, `topic`,
  `selected`, `favorite`) + `toMap()` for DB rows.
- **`lib/screens/photos_view.dart`** — the per-topic quotes list screen.
- **`lib/snack_bars.dart`** — snackbar builders: `downloading(state, snackText)`
  (progress %) and `downloadFailed({onRetry})` (error + Retry).

### Data flow (Processor)

- **Remote backend:** `Processor.url` = `https://my-qoutes-app-123456.nw.r.appspot.com`
  (Google App Engine). Change the single `url` field to point elsewhere; a local
  dev URL is commented out just above it. Endpoints used (plain HTTP GET):
  - `/see_saved_online` — all quotes
  - `/see_saved_online_preview` — small preview set (shown first on cold start)
  - `/see_saved_online_count` — total count (used to decide if an update is needed)
  - `/getdbtopics`, `/GetQuotesByTopicFromDB/?topic=<t>`, `/see_db`
- **Local cache:** SQLite via `sqflite`, DB file `quotes_database.db`, table
  `quotes` (PK: quote+author+topic). `dbVersion` in `Processor` gates schema
  migration in `checkNewDatabaseVersion()` — bump it when the schema changes.

### First-launch flow (`onStart`)

1. `checkNewDatabaseVersion()` → migrate if the on-disk DB is older than `dbVersion`.
2. `rowsCount()` → if the local DB is **empty**: download preview quotes, then the
   full set (each step updates a progress snackbar 0→100%).
3. If the DB already has rows: load topics locally, then compare local count vs
   `serverQuotesCount()` and download an update only if the server has more.
4. On **any** failure the whole thing is wrapped in try/catch → clears the
   progress snackbar and shows `downloadFailed` with a **Retry** that re-runs
   `onStart`. Preserve this — without it a network failure freezes the UI at "0%".

## Platform gotchas (learned the hard way)

- **Android needs `INTERNET` in the *main* manifest.** Flutter's template only
  puts `INTERNET` in `android/app/src/debug/` and `profile/` manifests, so debug
  runs work but **release builds have no network** and the app hangs at "0%". The
  permission is now in `android/app/src/main/AndroidManifest.xml`. Do not remove it.
- **macOS is sandboxed and needs the network *client* entitlement.** Outgoing
  requests fail with `Operation not permitted, errno = 1` unless
  `com.apple.security.network.client` is present in **both**
  `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.
  (`network.server` is inbound-only and does not help.)
- Backend is served over **HTTPS**, so no Android cleartext / iOS ATS config is
  needed. If you ever switch to an `http://` host, you'll need those.

## Release & CI/CD

**Releasing = pushing to `master`.** `.github/workflows/deploy.yml` triggers on
`push` to `master`: it does `flutter pub get`, `flutter analyze`
(`--no-fatal-infos --no-fatal-warnings`), `flutter build appbundle --release`,
and uploads the AAB to **Google Play internal testing** via
`r0adkll/upload-google-play` (signed with secrets `ANDROID_KEYSTORE`,
`ANDROID_KEY_PROPERTIES`, `PRODUCTION_CREDENTIAL_FILE`).

To cut a release:
1. Bump **both** the version name and build number in `pubspec.yaml`
   (`6.0.3+13` → `6.0.4+14`). **The build number must increase** or Play Store
   rejects the upload as a duplicate version code.
2. Add a `CHANGELOG.md` entry.
3. Commit and push to `master` in **one** push. A second push at the same
   version code will fail at the Play upload step, so bundle related changes
   (docs, fixes, version bump) together.

Notes:
- CI only builds/deploys **Android**. iOS/macOS/desktop are not part of CI.
- The workflow triggers on branch push, **not** on git tags. (Global guidance
  about `v*` tags applies to tag-triggered pipelines; this repo is push-triggered.)
- `concurrency: cancel-in-progress` means a newer push cancels an in-flight run.

## Conventions & housekeeping

- Do not commit build artifacts: `ios/Flutter/ephemeral/*` and
  `macos/Podfile.lock` show up as untracked but should stay out of commits.
- The codebase predates strict lints; `flutter analyze` reports many pre-existing
  `info`/`warning` items (avoid_print, naming, immutability). CI runs analyze
  non-fatal. Don't mass-fix these as part of an unrelated change, but don't add
  new ones either.
- After native/plugin changes, `pubspec.lock` and `macos/*` project files may
  update from tooling — those are expected and safe to commit.
