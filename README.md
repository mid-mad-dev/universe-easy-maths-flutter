# Universe Easy Maths

Flutter learning app with courses, lessons, progress tracking, payments, and a Supabase-backed doubt corner.

## Run locally

1. Install Flutter and Android Studio.
2. Run `flutter pub get`.
3. Start the app with `flutter run`.
4. On a fresh device, enter the Supabase project URL and publishable key in the first-run setup screen.

The real `assets/env.json` is intentionally ignored so it is not published with the source. The app can also be configured on-device from the first-run screen.

## Build signed Android releases

Release builds require a private upload keystore. The repository intentionally does not
contain signing credentials or a keystore.

1. Install a JDK with `keytool` available.
2. Generate or obtain your private upload keystore.
3. Copy `android/key.properties.example` to `android/key.properties`.
4. Set the keystore alias, passwords, and `storeFile` path in `android/key.properties`.
5. Keep both `android/key.properties` and the keystore backed up privately.

Build the Play Store bundle and a sideloadable signed APK:

```powershell
flutter build appbundle --release
flutter build apk --release
```

Artifacts:

- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/flutter-apk/app-release.apk`

Use a JDK 17+ runtime when invoking Gradle directly. Flutter can use the Android
Studio JDK automatically, or set `JAVA_HOME` to that JDK before building.

The release checklist and remaining professional polish items are tracked in
[docs/production-readiness.md](docs/production-readiness.md).

The latest public Android release is available at:

`https://github.com/mid-mad-dev/universe-easy-maths-flutter/releases/latest/download/app-release.apk`

## Supabase setup

Run the SQL files in `supabase/` in order for a new project. For an existing project, also run `supabase/03_questions_permissions.sql` to restore doubt operation privileges.

Deploy the protected video function with the Supabase CLI:

```powershell
supabase functions deploy get-lesson-url
```

Keep the `lesson-videos` bucket private. The app and web build use the same Supabase project, so lessons, doubts, answers, profiles, uploads, and progress are shared across platforms. Reopen or refresh the other client after a change to fetch the latest data.

## GitHub Pages web deployment

The workflow in `.github/workflows/deploy-web.yml` deploys the web app after every push to `main`. Add these repository secrets before enabling Pages:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

In GitHub, open **Settings > Pages** and set the source to **GitHub Actions**. The deployed site will be available at:

`https://mid-mad-dev.github.io/universe-easy-maths-flutter/`

Video playback is access-controlled through the `get-lesson-url` function and short-lived signed URLs. The web client blocks the context menu, but no browser can guarantee prevention of developer tools, downloads, or screen recording; direct public video URLs are rejected.
