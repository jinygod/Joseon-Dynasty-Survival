# Google Play Console setup

This checklist configures Google OAuth, Play Billing, the Android Publisher API,
and Real-time Developer Notifications (RTDN) for
`com.pixel.survivor.pixel_survivor`. Use separate cloud resources for staging
where possible. Do not store credentials in this repository.

## 1. App and signing identity

1. Create/select the Play Console app whose package name is exactly
   `com.pixel.survivor.pixel_survivor`.
2. Complete developer identity, payments profile, Play App Signing, and the
   required app-content declarations.
3. Upload an Android App Bundle containing Play Billing to the internal testing
   track. Billing product configuration is not fully available until a billing
   build has been uploaded to a track.
4. Record the upload and Play app-signing SHA-1/SHA-256 certificate fingerprints
   in the restricted release inventory. A local debug certificate is for local
   OAuth testing only.

## 2. Google OAuth clients

In Google Auth Platform for the environment:

1. Configure the OAuth consent screen and its support/privacy URLs.
2. Create an **Android** OAuth client for package
   `com.pixel.survivor.pixel_survivor` and the certificate fingerprint used by
   that build. Create separate Android clients for debug/upload/app-signing
   fingerprints when each is genuinely used.
3. Create a **Web application** OAuth client for Supabase Auth. Put its client ID
   and secret in **Supabase > Authentication > Providers > Google**.
4. Configure the Supabase callback URL shown by the Dashboard as an authorized
   redirect URI on the Web client.
5. Enable anonymous sign-in and manual linking in Supabase. Test that linking a
   new Google identity preserves the anonymous Supabase UUID.

Do not put the Web client secret in Android resources. Native Google ID tokens
must target the Web client/audience expected by Supabase. See the official
[Supabase Google login guide](https://supabase.com/docs/guides/auth/social-login/auth-google).

## 3. One-time consumable products

Open **Monetize with Play > Products > One-time products** and create exactly:

| Product ID | Server grant | Required setting |
| --- | ---: | --- |
| `royal_jade_small` | 100 royal jade | Active consumable, quantity fixed to 1 |
| `royal_jade_medium` | 550 royal jade | Active consumable, quantity fixed to 1 |
| `royal_jade_large` | 1,200 royal jade | Active consumable, quantity fixed to 1 |

For every product:

1. Use the exact immutable ID. Product IDs cannot later be renamed or reused.
2. Add localized title/description and regional pricing. The app displays Play's
   localized price; it does not hard-code price text.
3. Create/activate the backwards-compatible purchase option required by the
   Billing Library.
4. Keep multi-quantity checkout disabled. The backend rejects any quantity
   other than one and any response with more than one line item.
5. Activate/publish the product before license testing.

The authoritative grant is the checked-in server catalog, not a client amount or
Play Console description. Review the official [one-time product setup](https://support.google.com/googleplay/android-developer/answer/16430488)
before changing the catalog.

## 4. Android Publisher service account

Enable the Google Play Android Developer API in a controlled Google Cloud
project. Create a dedicated service account used only by these Supabase
Functions; do not use a human or broad CI account.

Invite its email under **Play Console > Users and permissions**, scoped to this
app. Google documents these billing API permissions as required:

- **View financial data** (app scope), or its account-level equivalent
  **View financial data, orders, and cancellation survey responses**;
- **Manage orders and subscriptions**.

Do not grant release, store-listing, user-management, reviews, or admin rights.
The credential uses only the
`https://www.googleapis.com/auth/androidpublisher` scope. Create a JSON key only
if workload identity is unavailable, store it as the Supabase Function secret
`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, restrict access, and rotate it. Never paste
the JSON into Play Console notes, CI logs, or Git.

Reference: [Google Play Developer API getting started](https://developers.google.com/android-publisher/getting_started)
and [Play Console permission definitions](https://support.google.com/googleplay/android-developer/answer/9844686).

## 5. RTDN Pub/Sub

In Google Cloud:

1. Enable Pub/Sub and create a dedicated topic.
2. On that topic only, grant
   `google-play-developer-notifications@system.gserviceaccount.com` the
   **Pub/Sub Publisher** role.
3. Create a push subscription whose endpoint is:

   ```text
   https://{PROJECT_REF}.supabase.co/functions/v1/google-play-notification
   ```

4. Enable authenticated push. Select a dedicated push-auth service account and
   set an explicit audience, preferably the exact endpoint URL.
5. Ensure the Pub/Sub service agent
   `service-{GCP_PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com` can mint
   OIDC tokens for that push-auth account (`Service Account Token Creator`). The
   operator creating/updating the subscription also needs permission to act as
   the push-auth account.
6. Set the exact audience as `PUBSUB_AUDIENCE` and exact push-auth email as
   `PUBSUB_SERVICE_ACCOUNT_EMAIL` in Supabase Function secrets.
7. In **Play Console > Monetize > Monetization setup**, enable RTDN for this app,
   enter `projects/{GCP_PROJECT_ID}/topics/{TOPIC_NAME}`, select one-time-product
   notifications, save, and send a test notification.

The topic publisher identity and push-auth identity are different. The former
lets Google Play publish to the topic; the latter signs requests delivered to
Supabase. The Function checks the OIDC audience, email, and verified-email claim.

Pub/Sub retries non-2xx delivery. This backend deliberately returns 503 for an
unknown voided token so a void arriving before its purchase grant is retried.
Do not add a dead-letter policy that discards messages before the agreed
incident/reconciliation window. Monitor delivery attempts and oldest unacked
message age.

References: [Play RTDN setup](https://developer.android.com/google/play/billing/getting-ready#configure-rtdn)
and [authenticated Pub/Sub push](https://cloud.google.com/pubsub/docs/authenticate-push-subscriptions).

## 6. License testers and internal testing

1. Add the test Google accounts or a controlled Google Group at
   **Play Console > Settings > License testing**.
2. Add the same accounts to the internal-track tester list and have each tester
   accept the track opt-in URL.
3. Install from Google Play, not via sideload, with the tester account active in
   Play Store.
4. Confirm all three products are published/active.

Execute and record:

- successful purchase of each product and exact 100/550/1,200 grant;
- pending/cancelled purchase with no grant;
- app process death and response-loss retry with one grant and one consume;
- duplicate callback/token with no duplicate ledger entry;
- refund/void after spend, including debt behavior;
- RTDN arriving before the client verification path;
- account switch and purchase ownership isolation;
- in-app deletion followed by token replay rejection.

License testers can make test purchases without being charged, but products
must still be published. See [Play license testing](https://support.google.com/googleplay/android-developer/answer/6062777).

## 7. Privacy, data safety, and deletion URLs

Before any production rollout:

1. Publish a public HTTPS privacy-policy URL that accurately describes Supabase
   account/profile/progress data, Google identity, Play purchase verification,
   retained pseudonymous purchase-token audit, retention, and contact method.
2. Publish a public HTTPS account-deletion URL where a user can request deletion
   without reinstalling the app. It must identify the app/developer, explain the
   request steps, state what is deleted, and disclose the limited purchase audit
   retained for fraud/replay prevention and its retention period.
3. Put both exact URLs in Play Console. Complete **App content > Data safety** and
   its data-deletion questions consistently with actual behavior.
4. Verify the in-app Settings deletion flow requires recent authentication and
   explicit confirmation, removes gameplay/account data, and signs the user out.

Apps that permit account creation must provide both an in-app deletion path and
a web deletion resource. See [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111).

## 8. Launch and rollback checklist

Before rollout, confirm the backend migration/Function deployment commit, all
four Function smoke tests, Pub/Sub test notification, three license purchases,
privacy/deletion URLs, Data safety approval, and key inventory. Start with a
small staged rollout and watch Function failures, Google API errors, Pub/Sub
backlog, and refund/debt metrics.

To roll back, halt the Play rollout, redeploy all Functions from the last
approved commit, and use a tested forward compensating database migration.
Never delete an applied migration or hide history with `migration repair`.
Rotate a suspected key by adding the replacement, verifying it, then revoking
the old key; do not leave two active keys indefinitely.
