# Android backend operations

This runbook covers the hosted Supabase deployment used by the Android build.
It intentionally contains names of configuration variables, but no secret or
production value. Commands use `{PROJECT_REF}` and similar braces for values
supplied by the release operator.

## Fixed application contract

- Android application ID: `com.pixel.survivor.pixel_survivor`
- Supabase Edge Functions:
  - `verify-google-play-purchase`
  - `google-play-notification`
  - `spend-royal-jade`
  - `delete-account`
- Google Play consumables: `royal_jade_small`, `royal_jade_medium`, and
  `royal_jade_large`
- Database changes are committed only as files under `supabase/migrations/`.
- Production seed data is never pushed. The three currency grants are created
  by the migration; test-only premium catalog entries remain inside pgTAP
  transactions.

## Access and separation of duties

Use separate staging and production Supabase projects. Give the deployer only
the Supabase permissions needed to link, push migrations, set Function secrets,
and deploy Functions. Keep Google Play Console owner/admin access out of CI.

The Android binary receives only:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

These are passed as Dart defines. Never place `SUPABASE_SERVICE_ROLE_KEY`, a
database URL/password, Google OAuth client secret, Google service-account JSON,
or Pub/Sub administrative credentials in Dart defines, Gradle files, the APK,
logs, screenshots, tickets, or Git.

## Supabase Auth configuration

For each hosted project, open **Authentication > Providers** and configure:

1. Enable anonymous sign-ins.
2. Enable manual identity linking.
3. Enable the Google provider with the Google Auth Platform **Web application**
   client ID and secret for this environment.
4. Add only the required production redirect/deep-link URLs. Remove temporary
   localhost URLs from production.
5. Keep JWT expiry and refresh-token rotation aligned with the checked-in
   `supabase/config.toml`; do not authorize from user-editable metadata.

Anonymous sign-in creates a real `auth.users` row and uses the
`authenticated` database role. It is not the same thing as the public API key.
The app must use manual `linkIdentity(provider: OAuthProvider.google)` or the
equivalent native-ID-token link while the anonymous session is active. A
successful link must preserve the existing Supabase user UUID. If Google is
already attached to another account, stop the link flow, sign in to that
existing account, and apply the documented cloud-wins policy; never move paid
ledger or purchase rows between UUIDs.

After configuration, verify with a staging device:

1. A fresh install creates an anonymous session.
2. `profiles.is_permanent` is false and premium purchase/spend is refused.
3. Google linking preserves the UUID and changes trusted `auth.users`
   anonymous state, causing `profiles.is_permanent` to become true.
4. Sign-out and sign-in restore the permanent UUID and its wallet.

References: [Supabase anonymous sign-ins](https://supabase.com/docs/guides/auth/auth-anonymous),
[identity linking](https://supabase.com/docs/guides/auth/auth-identity-linking),
and [Google login](https://supabase.com/docs/guides/auth/social-login/auth-google).

## Build-time client configuration

Use environment-scoped CI variables and pass only the public values:

```powershell
flutter build appbundle `
  --dart-define=SUPABASE_URL={HTTPS_SUPABASE_PROJECT_URL} `
  --dart-define=SUPABASE_PUBLISHABLE_KEY={PROJECT_PUBLISHABLE_KEY}
```

An empty define pair disables the backend in the current client. A mixed or
partially populated pair is a release configuration error.

## Edge Function environment

Hosted Supabase supplies `SUPABASE_URL`, `SUPABASE_DB_URL`, and legacy
`SUPABASE_SERVICE_ROLE_KEY` to Functions. Confirm their presence by name in the
Dashboard; never print their values. Set these custom secrets:

| Name | Purpose |
| --- | --- |
| `ANDROID_PACKAGE_NAME` | Must equal `com.pixel.survivor.pixel_survivor`. |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Complete JSON credential for the restricted Play API service account. |
| `PUBSUB_AUDIENCE` | Exact OIDC audience configured on the push subscription. |
| `PUBSUB_SERVICE_ACCOUNT_EMAIL` | Exact push-auth service-account email expected in the OIDC token. |

Prepare an ignored, access-controlled env file outside the repository and run:

```powershell
npx supabase link --project-ref {PROJECT_REF}
npx supabase secrets set --env-file {ABSOLUTE_SECURE_ENV_FILE} --project-ref {PROJECT_REF}
npx supabase secrets list --project-ref {PROJECT_REF}
```

`secrets list` is a name/inventory check, not permission to copy values into a
report. Supabase makes updated Function secrets available without a redeploy.
See [Edge Function secrets](https://supabase.com/docs/guides/functions/secrets).

## Pre-deployment gate

From a clean worktree:

```powershell
.\tool\backend_check.ps1
git status --short
```

The script must finish every required gate. Docker unavailable or unhealthy is
`BLOCKED`, not a skipped or successful database gate. Resolve it before remote
deployment.

Also review the pending remote change without applying it:

```powershell
npx supabase migration list --linked
npx supabase db push --linked --dry-run
```

Reject the release if migration history diverges, the dry run lists an
unexpected migration, a destructive statement lacks an approved backup and
rollback plan, or the target project ref is not the intended environment.
Never use `--include-seed` against production. Supabase documents `--dry-run`
as a listing-only operation in the [CLI reference](https://supabase.com/docs/reference/cli/supabase-db-push).

## Deployment order

Use one operator and one terminal for a project.

1. Record the Git commit, target project ref, current Function versions, and
   remote migration list in the change record.
2. Confirm a recent database backup/PITR recovery point.
3. Run the dry run again immediately before the push.
4. Apply migrations:

   ```powershell
   npx supabase db push --linked
   npx supabase migration list --linked
   ```

5. Set or verify secrets by name.
6. Deploy all four Functions from the same commit:

   ```powershell
   npx supabase functions deploy verify-google-play-purchase --project-ref {PROJECT_REF}
   npx supabase functions deploy google-play-notification --project-ref {PROJECT_REF}
   npx supabase functions deploy spend-royal-jade --project-ref {PROJECT_REF}
   npx supabase functions deploy delete-account --project-ref {PROJECT_REF}
   ```

   `google-play-notification` has `verify_jwt = false` in `config.toml` because
   Pub/Sub does not send a Supabase user JWT. The handler instead authenticates
   the Google OIDC token and pins its audience and email. Do not change this to
   an unauthenticated webhook.

7. Invoke authenticated staging smoke tests with test accounts. Never paste
   bearer tokens into a shared shell history or report.
8. Send a Play Console test notification and confirm a 2xx response. Verify a
   license-tester purchase, duplicate retry, consume, refund/void, and account
   deletion before production rollout.

Supabase deployment commands are documented in [Deploy Edge Functions](https://supabase.com/docs/guides/functions/deploy)
and [Database migrations](https://supabase.com/docs/guides/deployment/database-migrations).

## Health checks and incident signals

Monitor Function status/error rate and Postgres connections immediately after
deploy. Alert on repeated:

- `purchase_not_found_retry` or `reconciliation_retry_required` responses;
- Google API authentication/permission failures;
- Pub/Sub push 401/403/5xx responses or growing oldest-unacked age;
- wallet debt/refund anomalies or duplicate-token owner mismatch;
- database connection exhaustion.

Do not acknowledge an unknown voided purchase manually. Its 503 response is
intentional so Pub/Sub retries after a purchase grant becomes known.

## Rollback

Edge Functions are rolled back by checking out the last approved commit and
redeploying all mutually dependent Functions. Verify the deployed Function
version afterwards.

Database migrations are forward-only in normal operations. Never delete or edit
an already-applied migration, and never run `migration repair` merely to silence
a mismatch. Create and test a compensating migration. Use backup/PITR restore
only under the incident plan because it rewinds all project data, not just this
release. After any database rollback, reconcile Play purchase tokens and Pub/Sub
backlog before reopening purchases.

If the client release is faulty, halt the Play rollout and roll back to the last
known-good artifact. Do not point a production client at staging.

## Key and credential rotation

Rotate one credential class at a time:

1. Create the replacement with overlapping validity.
2. Update the appropriate Supabase secret or Google/Supabase provider setting.
3. Verify staging, then production purchase verification and Pub/Sub auth.
4. Revoke/delete the old credential.
5. Record only key IDs/fingerprints and timestamps, never secret material.

For the Play service-account key, upload new JSON to
`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, verify `getproductpurchasev2` and consume,
then disable/delete the old key. For the Pub/Sub push-auth account, change the
subscription and both `PUBSUB_*` secrets as one controlled change. OAuth client
secret rotation must update the Supabase Google provider before revoking the old
secret. Supabase signing/secret-key rotation requires a separate client/session
impact plan; it is not interchangeable with rotating the publishable key.
