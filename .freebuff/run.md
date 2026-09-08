# Run doc — universe_easy_maths (this thread's worktree)

Repo root: `C:\Projects\universe_easy_maths`

## How to reproduce the artifacts this thread created

The worktree adds a first-run config flow so a sideloaded APK can be configured
on-device instead of shipping real Supabase values in source.

Files of interest:
- `assets/env.json` — bundled placeholder config. It intentionally contains
  placeholder values (`YOUR_SUPABASE_URL` / `YOUR_SUPABASE_PUBLISHABLE_KEY`).
  A real device/build must overwrite this at runtime (via the first-run screen)
  or replace the file before building.
- `lib/core/app_constants.dart` — no longer hardcodes Supabase URL/key. It loads
  config at runtime from `assets/env.json` (bundled) and `getApplicationDocumentsDirectory/env.json`
  (writable, user-edited).
- `lib/screens/first_run_config_screen.dart` — the on-device config screen shown
  when `assets/env.json` has placeholder/unconfigured values.
- `lib/main.dart` — boots to the first-run screen when config is missing.
- `pubspec.yaml` — added `assets/env.json` and `path_provider` dependency.
- `.gitignore` — excludes `assets/env.json` from version control so a real
  config is not accidentally committed.

## How to run the server from this worktree

This is a Flutter project, not a Node/npm project. There is no `npm run dev`.

To run the app:

```powershell
cd C:\Projects\universe_easy_maths
flutter run -d web-server --web-port=8090 --web-allow-open-url
```

To build the Android release APK (needs a working Android SDK + NDK r27 LTS or
newer installed locally):

```powershell
cd C:\Projects\universe_easy_maths
flutter build apk --release
```

The APK will be at:

```
build\app\outputs\flutter-apk\app-release.apk
```

### Android build environment requirements

The `android/app/build.gradle.kts` in this worktree pins:

- `ndkVersion = "27.2.12479018"` (NDK r27 LTS series)
- `compileSdk` / `minSdk` / `targetSdk` are still taken from `flutter.*`
  (Flutter 3.13-era defaults)

To build the APK locally, the machine must have:
- Android SDK (ANDROID_HOME pointing at the SDK root)
- NDK r27 LTS installed, e.g. `ndk;27.2.12479018` via `sdkmanager`, or any
  NDK r27 release in that series
- Java 17 (JDK)

If the machine does not have a working NDK, `flutter build apk --release` will
fail at the Gradle `assembleRelease` step with an NDK installation error.

## Secrets

`assets/env.json` is intentionally kept placeholder-only in version control.
Do **not** commit a real Supabase URL/publishable key into this file in a public
repository. Real values belong on the device (first-run screen) or in a private
build step.
