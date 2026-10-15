# Release audit — 2 October 2026

## Verified live console state

- Apple 1.0.1 (60): manually released; App Store Connect now shows **Ready for Distribution**. Release confirmation retained the existing 175-country availability.
- Apple monthly subscription `app.kartvizyon.mobile.premium.monthly`: Approved, one-month duration, available for sale. Türkiye price: TRY 449.00.
- Google production: 55 (1.0.1), **Google Play'de Mevcut**, released 1 October 19:10, one country active.
- Apple description includes monthly auto-renewal, quotas, cancellation, standard Apple EULA and privacy links. Six iPhone screenshots present.
- Support, privacy and Apple standard EULA pages loaded successfully.
- RevenueCat default offering includes the Apple monthly product and Google `premium_individual:monthly`. Apple product is attached to `premium` entitlement.
- Native billing code uses platform-specific RevenueCat keys, localized `priceString`, native purchase, restore and subscription management. Purchase availability is not suppressed merely because the user is premium.

## Findings and verification limits

- The public Turkish App Store page still displayed the previous description immediately after release. Console metadata is corrected; public metadata propagation remains unverified.
- RevenueCat product Store Status shows **Could not check**. Its tooltip identifies App Store Connect API credential configuration. The app settings have no App Store Connect API key uploaded, while the separate **in-app purchase key shows Valid credentials**. Do not conflate this catalog-management warning with an invalid purchase key or prove purchase failure from it.
- RevenueCat says **No notifications received** for Apple server notifications. End-to-end delivery is not demonstrated by configuration alone.
- No production transactions appeared in the Apple product's recent transactions view at inspection time.
- Public storefront lists English as app language despite Turkish presentation; bundle localization should be checked for a future build.
- This audit did not execute a physical-device purchase, renewal, cancellation, expiry and restore cycle, nor rerun the full automated test suite. Those lifecycle behaviors are not certified by this report.

## Evidence

- `artifacts/app-store-review/apple-released-2026-10-02.png`
- Apple app ID: 6797552440.
- Google app ID: 4974987214470094540.

No credentials were changed and no database migrations or production backend deployment were performed during this release audit.

## Follow-up verification — 21:29 Türkiye time

- Revalidated the Apple in-app purchase credential using RevenueCat's validation button: **Valid credentials**.
- Sent one RevenueCat dashboard TEST delivery to the production endpoint. Response **HTTP 200**, body `{"received":true,"test":true}`. This proves authenticated/signed delivery reaches the deployed TEST handler, not database reconciliation or a real store transaction. Event ID: `4B7CFA63-52C8-439F-B389-1553802130A8`.
- Production webhook: HMAC signing enabled, Production only, All apps / All events. Keep sandbox transactions isolated; do not change production to accept sandbox merely to pass testing.
- Apple product recent transactions: **No transactions yet** in both production and sandbox views.
- **New actionable gap:** App Store Connect → App Information → App Store Server Notifications has no production or sandbox URL (both show Set Up URL). RevenueCat's lack of Apple notifications is therefore consistent with missing configuration. This is distinct from RevenueCat → application webhook, which passed TEST delivery.
- Re-ran 4 RevenueCat library tests, 17 webhook route tests and 11 mobile store compliance tests: all 32 passed. Route tests mock database access; mobile compliance tests inspect source and are not native StoreKit E2E.
- `flutter devices` found only Windows, Chrome and Edge; no physical iOS/Android device is available to this agent.
- Need configure Apple server notification targets, then conduct an actual sandbox purchase/renewal/cancellation/expiry/restore with a non-lifetime test user and independently verify RevenueCat state and staging database reconciliation. Existing lifetime premium should not be removed just to test.
- No API credential created/uploaded, no Apple notification setting changed, no production purchase performed.
- Live TEST screenshot: `artifacts/app-store-review/revenuecat-webhook-test-2026-10-02.png`.

## Authorized Apple notification remediation

- Following user approval, configured **both Production Server URL and Sandbox Server URL** in App Store Connect to the exact Apple Server Notification URL shown by the KartVizyon App Store app in RevenueCat.
- Verified both saved values persisted after a full page reload. Proof: `artifacts/app-store-review/apple-notification-urls-2026-10-02.png`.
- Did not change subscription pricing, existing lifetime premium, API credentials, or the production-only RevenueCat application webhook environment.
- Clarification: missing Apple notification URLs were an integration/latency gap, not proof that subscription processing was broken. RevenueCat states most subscription updates work without these notifications. Both environments should use its provided endpoint: https://www.revenuecat.com/docs/platform-resources/server-notifications/apple-server-notifications .
- Actual Apple notification delivery and real-device sandbox subscription lifecycle remain unverified; saved configuration and the separate successful RevenueCat TEST delivery are not substitutes for a native purchase.
