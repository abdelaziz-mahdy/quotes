# Changelog

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
