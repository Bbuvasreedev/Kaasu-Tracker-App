# KaasuTracker

A personal finance tracking app built with Flutter, Riverpod, go_router, and
Supabase Auth. The API is a Spring Boot REST service secured with Supabase JWTs.

## Run the app

Pass your Supabase project URL and publishable key at launch:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Localization resources are in `lib/l10n`; `flutter gen-l10n` generates the
English and Tamil localization classes. Regenerate Riverpod providers with:

```powershell
dart run build_runner build
```
