# Universe Easy Maths

Flutter learning app with courses, lessons, progress tracking, payments, and a Supabase-backed doubt corner.

## Run locally

1. Install Flutter and Android Studio.
2. Run `flutter pub get`.
3. Start the app with `flutter run`.
4. On a fresh device, enter the Supabase project URL and publishable key in the first-run setup screen.

The real `assets/env.json` is intentionally ignored so it is not published with the source. The app can also be configured on-device from the first-run screen.

## Build an APK

```powershell
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Supabase setup

Run the SQL files in `supabase/` in order for a new project. For an existing project, also run `supabase/03_questions_permissions.sql` to restore doubt operation privileges.
