# Production readiness review

Reviewed against the deployed GitHub Pages site, the signed Android build, and the Android emulator on 2026-09-11.

## Release gate completed

- `flutter analyze` reports no issues.
- `flutter test` passes all tests.
- Release signing no longer falls back to the debug keystore.
- The local upload keystore is ignored by Git and configured through `android/key.properties`.
- `flutter build appbundle --release` succeeds.
- `flutter build apk --release` succeeds.
- APK verification passes Android APK Signature Scheme v2.
- AAB verification reports `jar verified` and the expected Universe Easy Maths certificate.
- The APK installs on the `uem` Android emulator, launches the main activity, and reports version `1.0.0` / build `11`.
- The emulator smoke test reached the welcome screen and signup screen without an app crash or fatal exception.
- The deployed web splash, landing screen, and signup route render without console errors or failed network requests.

## Remaining professional polish

### P0 — before Play Store submission

1. **Confirm the final Android application ID.**
   `com.example.universe_easy_maths` is still the template-style package name in `android/app/build.gradle.kts`. Set the final reverse-domain ID before the first Play Console release; changing it later creates a different app listing.
2. **Back up the upload keystore securely.**
   Keep `android/upload-keystore.jks` and `android/key.properties` outside Git, in an encrypted password manager or secure release vault. The generated key is the upload identity for this release line.
3. **Enroll in Google Play App Signing.**
   Upload the AAB to Play Console and retain the Play signing certificate and upload certificate records. Do not distribute a debug-signed APK.
4. **Run a production Supabase smoke test.**
   Verify the deployed functions, private `lesson-videos` bucket, storage policies, RLS policies, payment secrets, and the production publishable key against a test student and staff account.

### P1 — recommended next release

1. **Add Android release CI.**
   Store the keystore as a protected base64 GitHub secret and build the AAB from a tagged workflow. Never put the keystore or passwords in the repository.
2. **Add real Firebase configuration if push is required.**
   The current `PushService` intentionally degrades to no push when `google-services.json` is absent. Add the Android/iOS Firebase app configuration and test foreground, background, sign-out, and token-refresh flows.
3. **Tighten function CORS.**
   `get-lesson-url` and `manage-user` currently allow `Access-Control-Allow-Origin: *`. Restrict browser calls to the deployed web origin if these functions are not intended for arbitrary web origins.
4. **Propagate database errors in admin operations.**
   `manage-user` should check each profile update and cleanup query and return a safe failure instead of reporting success after a partial operation.
5. **Bound home data loading.**
   `HomeScreenContent.load()` has no timeout. Match the lesson/startup timeout pattern so a stalled network request reaches the retry state deterministically.
6. **Stream large uploads.**
   `StorageService.uploadXFile()` reads the complete file into memory. Large lesson videos should use a bounded or resumable upload strategy to avoid mobile memory pressure.
7. **Improve automated coverage.**
   Add integration tests for first-run persistence, auth redirects, signed lesson URL failures, payment failure states, and notification permission/token handling.

## Known environment notes

- A connected physical Android device was not available; validation used the configured `uem` emulator.
- Flutter Doctor still reports Android license status needing acceptance and no Visual Studio installation. These do not block the Android or web release artifacts.
- Gradle emits AGP/Kotlin deprecation warnings from the current Flutter/Android template. Plan the built-in Kotlin/new DSL migration when upgrading the Android toolchain.
