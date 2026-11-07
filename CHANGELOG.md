# Changelog

## 6.0.4+14

### Fixed
- **Favorites lost / wrong quotes during a download.** Opening a topic or
  Favorites while the first-launch or update download was running showed every
  quote on the server under that topic and could reset all favorites. The
  download now works on its own list and inserts new quotes without touching
  existing rows (`ConflictAlgorithm.ignore`), so favorites always survive.
- **Topic grid reshuffled under the finger** when a download finished; topics
  already on screen now keep their place.
- **Long author names** ("Philip Stanhope, 4th Earl of Chesterfield")
  overflowed the quote card and hid the favorite button.
- **Status bar icons invisible** (white on white) on the quotes screens in the
  light theme.
- **Last row under the gesture bar** on the topic grid and quote lists.
- A non-200 response from the backend now shows the Retry snackbar instead of
  silently doing nothing.

### Changed
- Selection mode: a close button and Back now clear the selection; selected
  cards are outlined; "Selected: N" spacing.
- Quote cards: quieter author line under the quote, full quote text (no
  10-line cut-off), theme ripple instead of a solid blue flash; topic chips
  show their ripple and have page gutters.
- Download progress snackbar uses theme colours with a progress bar; tidier
  copy. Spinners lose the black track. Empty Favorites shows a proper empty
  state. Tooltips on the Favorites, favorite and share buttons.
- Sharing uses `SharePlus.instance.share`.

### Build
- Gradle 8.14.3, AGP 8.13.2, Kotlin 2.3.20 (Flutter 3.47 refuses older).
- Dependencies upgraded (`cupertino_icons` 2.0.0, `share_plus` 13.3.1,
  `sqflite` 2.4.5). `flutter test` now has real tests (11) instead of the
  template counter test.

## 6.0.3+13

### Fixed
- **Android: app stuck at "0%" on first launch.** The `INTERNET` permission was
  declared only in the debug/profile manifests, so release builds had no network
  access and every request failed silently. Added the permission to the main
  manifest (`android/app/src/main/AndroidManifest.xml`) so it applies to all
  build types.
- **macOS: network requests blocked by the sandbox** (`Operation not permitted,
  errno = 1`). Added the `com.apple.security.network.client` entitlement to both
  `DebugProfile.entitlements` and `Release.entitlements`.

### Changed
- **Graceful startup error handling.** `onStart()` in `lib/main.dart` is now
  wrapped in a `try/catch`; on any network/DB failure it clears the stuck
  progress snackbar and shows a "Couldn't connect" snackbar with a **Retry**
  action instead of freezing at 0%. Added the `downloadFailed` snackbar helper.
