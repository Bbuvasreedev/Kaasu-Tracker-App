# Kaasu-Tracker-App
A smart expense tracking application.

## Running the app

Pass the Supabase project URL and publishable (or legacy anon) key at runtime;
do not place service-role keys or database credentials in the Flutter app:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_OR_ANON_KEY --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1/
```

The default API URL targets a Spring Boot server running on the Android
emulator's host. Use the backend's reachable URL for physical devices or other
platforms. The backend must validate Supabase-issued access tokens and derive
the current user from the JWT subject.

## Monthly finance integration

The dashboard uses the authenticated backend `GET /finance/monthly-summary`
with the selected `year` and `month`; salary, carry-forward, fund balances,
eligible expenses, funding allocations, overspending, and EMI schedule values
are displayed from that response. Additional and borrowed funds use their
backend collection/create/update/deactivate endpoints. Carry-forward is only
created by the explicit dashboard action, and expense funding uses the
backend's replace-allocation `PUT` semantics.

The configured backend must provide `PUT /finance/monthly-salary`,
`GET`/`POST /finance/carry-forward`, `GET`/`POST`/`PUT`/`DELETE` for
`/additional-funds` and `/borrowed-funds`, and `GET`/`PUT`
`/expenses/{id}/funding`, `GET /expenses`, `POST /expenses`, and
`DELETE /expenses/{id}`, in addition to the existing user and EMI routes.
Expense details use the fields returned by the expense list and the funding
allocation response. All monetary values in the Flutter finance models use integer minor
units; request bodies serialize them as decimal amounts expected by the
backend DTOs. Monthly expenses and their refund treatment come from the backend
summary, not a local dashboard calculation.

## EMI duration and status integration

The Flutter EMI tracker currently sends the following extended EMI requests.
These fields and the status-update route require confirmation/implementation in
the Spring Boot service; no backend source or verified response contract is
included in this repository.

- `POST /emis` accepts the existing `title`, `amount`, `dueDateDay`, and
  `isActive` fields plus `startDate` (`YYYY-MM-DD`) and `durationMonths`
  (positive integer).
- `GET /emis` returns those fields and may return `endDate` (`YYYY-MM-DD`),
  `status` (`ACTIVE`, `INACTIVE`, or `COMPLETED`), `totalInstallments`,
  `paidInstallments`, and `remainingInstallments`. Payment counts must come
  from persisted installment/payment records; the client does not infer them
  from dates.
- The status toggle sends `PUT /emis/{emiId}/status` with
  `{ "status": "ACTIVE" }` or `{ "status": "INACTIVE" }`, matching the
  Spring Boot `EmiController` and `EmiStatusRequest` contract. The service must
  update only whether the EMI is active, preserve the EMI and its payment
  history, and return the updated `EmiResource` after persistence. Completed
  EMIs must not be reactivated.

The backend remains authoritative for `endDate`, installment progress, user
ownership, and clamping a due day to the last day of shorter months. Older EMI
records without duration or payment fields remain supported; those details are
shown only when returned by the API.

## App localization

The app uses Flutter `gen-l10n` with ARB files in `lib/l10n`. English is the
default; the current UI resources cover English, Tamil, Telugu, Malayalam,
Kannada, and Hindi. The language selector stages a choice until **Save
Preferences** is tapped. Saving updates the existing backend `languagePref`
and the local `app_locale` preference; the local value restores the language
at startup without a network request and remains available across sign-out.

To update or add translations:

1. Edit `lib/l10n/app_en.arb` for new message keys, then add a translated value
   for every key in each supported locale's `app_<locale>.arb`.
2. Keep API keys, enum values, stored category identifiers, and date payloads
   unchanged; only localize their displayed labels.
3. Run `flutter gen-l10n`, then `flutter analyze` and `flutter test`.
4. Have each translation reviewed by a fluent speaker and check text direction,
   clipping, and font glyphs on physical Android and iOS devices.

The current translations are complete for the visible app strings but still
need native-speaker review. Other requested Indian languages are not exposed
until complete UI translations and script/font coverage can be verified; the
repository does not bundle fonts for those scripts. Flutter's built-in
widget-localization data does not cover every requested language tag.
