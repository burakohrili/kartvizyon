# English-language readiness and privacy/data-flow review

Status: in progress · 14 October 2026

Target-market legal review: see
[`TARGET_MARKET_LEGAL_REVIEW_UK_US.md`](./TARGET_MARKET_LEGAL_REVIEW_UK_US.md).
UK/US market availability is **not cleared** by the English UI or these draft
legal pages. Complete the legal/data-transfer launch gates in that review
before enabling either market.

This work prepares Turkish and English product experiences in code. It does not
change production configuration, store metadata, prices, store availability,
published binaries, or deployments. The current release remains untouched until
the owner explicitly plans a separate release.

## Current baseline (verified in source)

- Flutter declares `en` and `tr` as supported locales. A persisted Turkish /
  English interface-language choice exists in More; Turkish remains the
  default. The migrated shell, account, customer, visit, task, field-mode,
  workspace, billing, offline, and privacy workflows use paired catalogs. A
  source scan found no remaining Turkish-only user-facing literals in migrated
  feature files; comments and intentionally bilingual helpers are not UI. This
  is not a substitute for on-device visual and accessibility review, so mobile
  is **not yet launch-verified**.
- The web root resolves `lang` from the `kartvizyon_locale` cookie (default
  Turkish); a global EN/TR preference control persists the cookie and refreshes
  the current route. Authenticated dashboard, customer, visit, task, map,
  calendar, activity, notification, report, import, operations, workspace, and
  settings flows use the language catalogs. Fictional demo records in those
  flows follow the selected language; real customer and team records are never
  rewritten. Some API validation text and transactional email still need
  separate localization. Root-level Open Graph metadata is locale-aware; the
  marketing page now selects EN/TR copy from the preference cookie.
- Visit transcription and summary generation previously assumed Turkish.
  The debrief flow now accepts an explicit `tr`/`en` language choice on web and
  mobile, carries it through offline queues, passes it to transcription and
  summary generation, and stores it in the existing transcript language field.
  Old queued items and clients default to Turkish. This is a groundwork change,
  not completion of UI localization.
- Mobile and web migrated screens use locale-sensitive date/time/number/currency
  formatting where displayed; task due dates use Turkish `DD.MM.YYYY` or
  English `M/D/YYYY`, with tests for both. A route-by-route formatting audit
  remains open, especially exports and less-used date fields.
- A static English/Turkish choice on the debrief does not establish the
  interface locale. The complete implementation must keep interface language,
  content/transcript language, and customer-entered data as separate concepts.

## AI and personal-data flow to disclose accurately

### Voice debrief

1. A representative starts a recording or types a post-visit note. The product
   explicitly describes this as the representative's personal debrief, not a
   recording of the customer conversation.
2. Mobile offline drafts are queued in the app's local Drift database; web
   offline drafts use IndexedDB. Do not describe local database encryption
   unless the implementation is separately verified.
3. When submitted, audio is uploaded to the private Supabase `visit-audio`
   storage bucket and an asset row is written. The scheduled retention process
   marks audio for deletion 30 days after creation and removes eligible assets.
4. The server sends audio to OpenAI transcription and then sends the transcript
   and customer/workspace context to OpenAI for a structured summary. The
   provider is currently OpenAI in source; English readiness does not mean
   Claude or another provider is in production.
5. Transcript text and summary are stored for the visit. The visit begins in
   `needs_review`. Only a user approval changes it to approved customer memory
   and makes it eligible for approved reports/briefings.

Before marketing or legal copy claims provider-side retention, model training
exclusion, encryption at rest/in transit, or a particular international data
transfer arrangement, verify the current provider terms, account settings,
Supabase region/configuration, and legal review. Do not infer these from the
application code.

### Business-card OCR and documents

- Business-card image is sent to the server for OCR; extracted data is a draft
  for user review. Do not imply perfect recognition or automatic, verified
  CRM creation.
- Web-managed documents enter private storage and a quarantine/scan workflow;
  they should not be described as immediately available before a clean scan.
- Confirm localized consent/notice text and the end-to-end retention/deletion
  behavior for uploaded images and documents before opening a new market.

### Location / field mode

- Location is user-initiated, permission-gated, and used for a nearby-customer
  candidate request while field mode is active. The API request includes the
  current coordinates; the product decision says coordinates are not persisted
  as a user location. Geofence outcome metadata may be stored without
  latitude/longitude.
- Field mode is visible and auto-stops. It is not continuous hidden tracking;
  notifications are not promised after the app is fully terminated.
- Field-mode card copy, permission/service failures, subscription gating,
  stop/expiry messages, Android foreground notification text, and nearby
  customer notification text now resolve in Turkish or English. This is
  implemented and unit-tested, but English is not yet selectable app-wide.

### Account and workspace data

- Customer, contact, visit, task, order draft, opportunity, and document data is
  scoped to an authenticated workspace/organization and enforced by RLS and
  server authorization.
- The product has consent settings and data export/account deletion request
  flows. A request UI is not proof that processing has completed; never promise
  instant deletion unless verified operationally.
- Crash/diagnostic telemetry is intended to omit transcript/audio/document
  contents; re-test scrubbing after adding English errors and labels.

## Remaining engineering work before declaring English ready

1. Finish device-level EN/TR visual and accessibility smoke testing for mobile
   and authenticated web, including permission prompts, validation, empty,
   loading, and failure states.
2. Audit remaining authenticated API validation/server-action errors and ensure
   clients consistently map failures to safe localized messages without
   leaking provider or database messages.
3. Complete route-by-route date/time/number/distance/currency formatting and
   verify exports and reports without changing stored values or TRY pricing.
4. Verify voice/transcript language through online, offline, retry, persistence,
   and AI prompts with end-to-end Turkish and English cases, including legacy
   queued records and human approval of generated content.
5. Review language-specific OCR, search normalization, geocoding, notifications,
   generated reports, and customer-authored text. UI locale must not silently
   relabel Turkish content as English.
6. Translate and obtain legal review for privacy policy, terms, support, account
   deletion, data-processing disclosures, store privacy/data-safety answers,
   and reviewer instructions for target markets. Do not claim legal compliance
   as a guarantee.
7. Keep store regions, localized listings, availability, pricing, production
   services, and published binaries unchanged in this preparation phase. Any
   later market launch remains a separately reviewed and explicitly approved
   operation.

## Current verification for the language-aware debrief groundwork

- Web: `visit-company-context.test.ts` and
  `api/visits/[id]/debrief/route.test.ts` cover English instruction selection,
  legacy Turkish fallback, and transcript language persistence.
- Web: `src/lib/i18n/locale.test.ts` covers locale resolution and date, time,
  number, and currency formatting without changing stored values. Dashboard
  formatting now consumes the request locale; other app routes remain to be
  migrated.
- Mobile: `sync_engine_test.dart` covers carrying selected language in an
  offline upload; `debrief_flow_test.dart` covers queued debrief behavior.
- Mobile: `app_localizations_test.dart` covers both catalogs for shared
  navigation, access banners, login, home/menu labels, and interpolation;
  task-date tests cover both locale conventions. Flutter analyze is clean.
- These targeted tests do **not** prove full application localization or
  production behavior. Full locale coverage, formatting, privacy/legal review,
  and platform builds remain required.

## Mobile UI localization progress (2026-10-14)

- Both Flutter ARB catalogs now cover the top-level navigation, login,
  dashboard summary, More menu, customer list/OCR/manual-entry and customer
  detail/edit/archive/location-pin flows, visits list/start flow, tasks
  list/create/reopen flow, nearby-customer map,
  post-visit debrief, visit briefing, and AI summary review/reject flow.
- Task due dates shown from visit briefings use the selected UI locale's date
  convention. Nearby distances use a decimal point for English and comma for
  Turkish; labels explain that GPS access is user-initiated and location is
  not stored.
- The debrief UI language selector now distinguishes Turkish and English in
  either UI locale; the chosen transcript language remains part of the offline
  queue and AI processing contract.
- The visit briefing and AI review screens are localized, including approval
  and rejection disclosures, sensitive-data warning, fallback/empty states,
  and follow-up due dates. AI-generated content still requires explicit human
  approval before shared-memory insertion.
- Verification after these additions: `flutter analyze --no-pub` reported no
  issues; targeted debrief and visit-flow tests passed; the complete mobile
  suite passed all 131 tests on the current tree.
- Field Mode UI/service messages and nearby-customer notifications now use
  localized message codes/catalog values rather than fixed Turkish strings.
  Nearby distance, visit recency, and overdue follow-up text follow the active
  locale; the English/Turkish notification-description formatting has a direct
  test. The full mobile suite passes 132 tests after this change.
- Offline Center labels, queue status, sync results, delete confirmations,
  retry/export actions, and sync-error guidance now resolve through the active
  locale. Error labels distinguish connectivity, authentication, quota,
  processing, payload size/format, rate limiting, unsupported records, and
  server failures. The storage notice describes the local app data area
  without claiming unverified encryption.
- Premium/billing screen copy and store/server reconciliation outcomes now
  resolve through the selected locale. StoreBillingException contains stable
  failure kinds rather than Turkish display text; subscription product price
  remains the store-provided localized `priceString`, with no fixed price added.
  Usage counts use locale-aware number formatting and unlimited quotas have an
  explicit label. Widget and reconciliation tests cover both locales.
- The privacy/data-rights screen now localizes consent controls, export/deletion
  requests, request statuses, and safe error messages; it does not expose raw
  server error text. Its widget tests cover unauthenticated controls, request
  states, and deletion confirmation. This does not constitute a legal review of
  the privacy policy or terms.
- English is selectable app-wide and persists across relaunch; Turkish remains
  the default. A widget test exercises the language picker and relaunch
  persistence. Task detail/planning and other screens still need a full
  user-visible-copy audit before calling the app fully localized.
- The scheduled local visit/task/field-plan notification content and Android
  notification channel labels now follow the persisted UI language; stable
  notification IDs and business/user-provided task/customer text are unchanged.
  A direct test verifies English and Turkish reminder plans.
- Latest mobile verification before this notification extension: the full
  suite passed 139 tests and `flutter analyze --no-pub` found no issues. The
  updated suite is being rerun after the new reminder locale test.
- Authenticated web localization remains partial: a user-facing language
  switcher now exists and additional operational, admin, sign-in, invitation,
  offline, reporting, and import flows are localized, but several authenticated
  screens and server/API messages still render Turkish copy. Do not present
  either product surface as fully English-ready yet.

## Web UI localization progress (2026-10-14)

- Added a global EN/TR language control, available across routes. It writes only
  the `kartvizyon_locale` preference cookie (HTTP-only, same-site, one-year
  lifetime); Turkish remains the default. Changing language refreshes the
  current route without changing account, workspace, store, or production
  configuration. The endpoint rejects unsupported locales and cross-origin
  requests.
- Localized the dashboard navigation, workspace labels, date greeting, summary
  hero, metric captions, visit briefing, review banner, and no-visit state; the
  customer list/search/pagination and task list/completion controls; and the
  visits list, status labels, and actions. Customer detail labels/dates and the
  AI review form are also localized. Dates on those pages use locale-aware
  formatters. The global demo-data/sign-in banner also resolves in the selected
  language.
- Web visit debrief UI now resolves in the interface locale; the separate note
  language selector controls transcription and AI-summary language, defaults
  to the interface locale as a suggestion, and is explicit in its explanatory
  copy. The selected content language continues into server processing and the
  offline queue; untranslated stored customer summaries and names are not
  relabeled or rewritten. Known API failures are mapped to localized safe
  messages instead of exposing server-language text. Browser recording selects
  a supported WebM/MP4/etc. MIME type, normalizes codec parameters for server
  validation, and uses matching filenames for direct and offline uploads.
- Dashboard user-entered/generated visit summaries are shown as stored; this
  work does not translate customer content or alter AI/transcription language.
- Web verification: `npm run typecheck`, `npm test -- --reporter=dot` (163
  tests), `npm run lint`, and `npm run build` all passed. Added route tests for
  supported-cookie persistence, same-site enforcement, and invalid locales.
- Additional authenticated pages now use the same locale preference: the
  nearby-customer map's user-facing labels, geolocation states and priority
  reasons; the manager activity feed and comment controls; and notification
  page labels and timestamps; and visit calendar planning labels and dates.
  Existing notification bodies and AI summaries
  remain unchanged because they are stored user/business content. Priority
  reasons now have stable language-neutral codes in the shared contract while
  retaining their existing Turkish labels for current consumers.
- Verification after this extension: web typecheck, lint, and all 163 web
  tests pass; the shared contract suite passes all 38 tests. A full web build
  and release-gate checks still need rerunning after the remaining localization
  work.
- Other authenticated web screens and server/API messages still need
  localization; this preference control is not evidence that all those pages
  are translated. Open Graph metadata, legal copy, exports, and transactional
  emails also remain under review.

- Further web progress: sales opportunities, products/pricing, price lists,
  order drafts, document/form centers, reports and secure sharing, workspace
  selection, team/organization administration, and account security now use
  paired EN/TR catalogs. Locale-aware number, date, currency, and file-size
  formatting is applied where relevant. Server-provided raw error text is
  replaced with safe localized messages in migrated flows.
- Sign-in/sign-up, invitation acceptance, offline guidance, and Excel/CSV
  customer import now use EN/TR copy. Import and invite network failures return
  localized safe errors and reliably clear their busy state. This does not
  localize email templates or every API validation response.
- Customer create and business-card contact/OCR forms now use EN/TR copy;
  scan failures expose localized safe messages, while detected business and
  contact data remains exactly as provided and the OCR result remains a draft
  requiring review. Billing, privacy/data-rights, and integration settings
  panels and navigation now use paired catalogs. TRY values remain TRY and are
  formatted for the selected locale; this does not change store pricing.
- Mobile workspace module/form/document actions were also migrated to EN/TR;
  localized empty states and test harnesses were updated. Latest full mobile
  verification at that point was 139 passing tests and clean
  `flutter analyze --no-pub`.
- Latest web verification after these additions: typecheck, lint, all 166 web
  tests, and local `next build` (84 pages) passed. The newest customer/settings
  changes were included in this successful run. No store submission,
  production deploy, or published binary was changed.

## Latest localization hardening (2026-10-14)

- Mobile workspace fallbacks, home/map/visit/review/customer load and save
  failures, and visit-summary approval errors now use bilingual catalog copy.
  Authentication errors no longer fall back to raw provider/server messages;
  password-reset and resend failures are caught and shown as localized safe
  messages. Card-scan failures also avoid exposing raw API text. English and
  Turkish ARB catalogs were regenerated and normalized.
- Current mobile verification: `flutter analyze --no-pub` clean; full
  `flutter test --no-pub` passes all 142 tests. The map test now verifies that
  a server failure displays a safe localized message rather than the raw
  response or a misleading location-permission error.
- Web offline status, global route errors, fatal errors, loading state, and
  language-preference failure feedback now resolve from the EN/TR catalog. The
  client reads the document language through an external-store subscription,
  avoiding render-time hydration assumptions and synchronous state updates in
  effects.
- Empty business-name fallbacks now use the active locale in mobile customer,
  visit, task, reminder, opportunity, and order displays. Actual
  customer-provided names remain unchanged; direct tests cover both locales
  and preservation of Turkish customer-entered text.
- Price-list and document rows without a server-provided filename now use
  localized fallback labels instead of fixed Turkish strings. A source scan of
  mobile feature string literals found only intentional bilingual copy,
  developer comments, identifier normalization, and non-UI internal errors;
  this does not translate server/customer content.
- Latest mobile rerun after these changes: analyzer clean and all 143 tests
  pass, including the compact-phone English navigation smoke test.
- Web verification after earlier hardening: `npm run typecheck`,
  `npm run lint`, and `npm test` passed (168 tests); `npm run build` compiled
  and generated all 84 routes locally. The latest verification below includes
  the subsequently added locale/demo tests. No deployment was run.
- Public secure-report share pages now localize their chrome and fallback text
  from the viewer's locale preference and format expiry/visit dates with
  `en-US` or `tr-TR`. User-entered report titles, company names, and approved
  summaries are not translated. Locale-catalog tests cover both languages.
- This is still not a launch-ready English market package: the mobile feature
  source-string scan found no remaining untranslated UI literals beyond the
  cases documented above, but full device-level English visual/accessibility
  smoke checks and generated-content review remain. Transactional emails,
  privacy/data-processing disclosures, and target-market legal review are not
  fully localized/approved. No store listing, region, price, release,
  production service, or published binary was changed.
- Fictional seed records in the authenticated customer, visit, task, calendar,
  activity, map, order, product, opportunity, workspace, and team demos now
  follow the viewer's selected locale. User-created customer records and
  summaries are unchanged. Web localization tests compare the complete nested
  English/Turkish message-catalog shape, including array slots. Latest web
  verification after this addition: typecheck, lint, all 170 tests, and the
  local production-mode build passed. A compact-phone English navigation smoke
  test was added on mobile and its targeted run passed; the full mobile suite
  passed, including that case.
- Public about, contact, support, account-deletion, and Türkiye-specific KVKK
  pages now display English drafts when the English preference cookie is set.
  The KVKK translation explicitly defers to the Turkish notice and applicable
  mandatory law. These drafts are not legal approval or UK/US-market terms.
- PDF/XLSX approved-visit exports now localize column/sheet labels, report
  headings, fallback text, and date formatting using the UI language. Stored
  customer names, representative names, outcomes, and summaries remain as
  entered/approved. Two locale-specific export-copy tests were added.
- Latest web verification after public-page and export changes: typecheck,
  lint, all 172 tests, and local production build (84 routes) passed. No
  deployment or production configuration changed.
- Public marketing homepage now has an English variant, a language switch,
  localized product workflow/demo copy, and App Store/Google Play links. It
  states the ₺449 price only as the Türkiye standard and defers to each store's
  purchase sheet for region-specific availability and terms. The English
  homepage uses Apple's region-neutral app URL; Turkish homepage links are
  unchanged. No store listing or availability setting was changed.
- Privacy, terms, distance-sales, and delivery/refund pages now have English
  translations clearly marked as convenience drafts for Türkiye rather than
  market-specific legal terms. Contact, support, company, account-deletion,
  and KVKK public pages also have English variants. Qualified legal review is
  still required before external English-market use.
- Latest web verification after public-page, marketing, and export changes:
  typecheck, lint, all 173 tests, and local production build (84 routes)
  passed. No deployment or production configuration changed.
