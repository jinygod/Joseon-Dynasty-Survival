# Android Backend, Account, Cloud Save, and Premium Economy Design

## Objective

Ship Android first with immediate guest play, optional Google account linking, cross-device cloud progress, and server-authoritative paid currency. The existing offline game remains playable without a network connection. Online identity, paid purchases, and paid-currency spending require a permanent Google-linked account.

The backend uses Supabase Auth, PostgreSQL, Row Level Security (RLS), and Edge Functions. Google Play Billing processes Android purchases, while a server function verifies every purchase token with the Google Play Developer API before granting value.

## Scope

This release adds:

- anonymous guest sessions created at first launch;
- Google account linking without replacing the guest user identity;
- session restoration and sign-out;
- cloud progress snapshots for permanent accounts;
- deterministic first-upload and subsequent revision-based synchronization;
- a new paid currency named **금옥** with internal code `royal_jade`;
- an append-only currency ledger and server-maintained wallet balance;
- three Google Play consumable products;
- idempotent purchase verification, grant, consume, refund, and revocation handling;
- an in-app account deletion flow;
- local emulation, unit, integration, security, and Android billing tests.

This release does not add iOS, multiplayer, social features, advertising, subscriptions, a web store, trading, gifting, or a competitive leaderboard.

## Product Decisions

- Initial platform: Android only.
- Backend: Supabase hosted platform with PostgreSQL.
- Login: guest session by default; Google linking is offered from the lobby and required before purchase or cross-device sync.
- Existing `coin` and `spiritJade`/혼옥 remain earnable gameplay currencies. They are never sold for money in this release.
- Paid currency: `royal_jade`/금옥. It can only be changed by trusted backend code.
- Initial products:
  - `royal_jade_small`: 100 금옥
  - `royal_jade_medium`: 550 금옥
  - `royal_jade_large`: 1,200 금옥
- Prices and localized display strings come from Google Play Product Details and are never hard-coded in the client.
- A guest may play indefinitely, but the shop purchase action and paid-currency spending are disabled until Google linking succeeds.
- The client never directly inserts ledger rows or updates paid balances.

## System Architecture

```text
Flutter Android application
  |-- local SharedPreferences cache
  |-- Supabase Flutter client (publishable key only)
  |     |-- Auth: anonymous session and Google identity link
  |     `-- Data API: read-own profile, progress, wallet, and ledger
  |-- Google Play Billing client
  `-- HTTPS calls to Supabase Edge Functions
          |-- authenticated request validation
          |-- Google Play Developer API verification/consume
          `-- privileged PostgreSQL transactions

Supabase PostgreSQL
  |-- public user-owned read models protected by RLS
  `-- private purchase verification and mutation functions
```

The Flutter application contains interfaces for authentication, cloud progress, wallet reads, and purchase submission. Production adapters use Supabase and Google Play; deterministic in-memory adapters keep widget and game tests independent of external services.

## Authentication and Account Linking

On first launch, the app requests a Supabase anonymous session and continues locally if the network is unavailable. A guest session is not considered a permanent account.

Google linking uses Supabase Auth identity linking so the existing Supabase user ID remains stable. This preserves server rows created for the guest instead of copying them to a second account. The UI clearly distinguishes `게스트` and the linked Google account.

Rules:

- gameplay never blocks on authentication bootstrap;
- purchase and paid spending require a valid non-anonymous session;
- linking retries safely after cancellation or network failure;
- signing out removes local session credentials and paid wallet cache, but does not delete local offline progress;
- signing into another account reloads that account's server progress and wallet;
- account deletion requires recent authentication and a confirmation step.

## Database Model

All exposed tables have RLS enabled. Every ownership policy uses `(select auth.uid()) = user_id`, specifies `TO authenticated`, and includes both `USING` and `WITH CHECK` for updates. Ownership columns are indexed.

### `profiles`

- `user_id uuid primary key references auth.users`
- `display_name text`
- `is_permanent boolean not null default false`
- `created_at timestamptz`
- `updated_at timestamptz`

Users may read their own profile. Profile permanence is synchronized from trusted auth identity state and cannot be promoted by client metadata.

### `player_progress`

- `user_id uuid primary key references auth.users`
- `schema_version integer not null`
- `revision bigint not null default 1`
- `progress jsonb not null`
- `created_at timestamptz`
- `updated_at timestamptz`

`progress` stores the existing non-paid `SaveState` representation, including unlocks, selected content, records, earnable currencies, training, and shop progression. It explicitly excludes `royal_jade` and purchase state.

The client may read its row. Writes go through the `sync-progress` Edge Function, which validates the supported schema, known content identifiers, non-negative bounded counters, payload size, and expected revision.

### `wallets`

- `user_id uuid primary key references auth.users`
- `royal_jade bigint not null default 0 check (royal_jade >= 0)`
- `royal_jade_debt bigint not null default 0 check (royal_jade_debt >= 0)`
- `version bigint not null default 0`
- `updated_at timestamptz`

The client may read its wallet but receives no insert, update, or delete permission.

### `wallet_ledger`

- `id uuid primary key`
- `user_id uuid references auth.users on delete set null`
- `subject_hash text not null`
- `currency_code text not null check (currency_code = 'royal_jade')`
- `delta bigint not null check (delta <> 0)`
- `balance_after bigint not null check (balance_after >= 0)`
- `reason text not null`
- `reference_type text not null`
- `reference_id text not null`
- `idempotency_key text not null unique`
- `metadata jsonb not null default '{}'`
- `created_at timestamptz`

Ledger rows are immutable. The user may read their own rows. Only private trusted database functions may insert rows while atomically locking and updating the wallet.

### `google_play_purchases`

This table resides in a non-exposed `private` schema.

- `id uuid primary key`
- `user_id uuid not null references auth.users`
- `product_id text not null`
- `purchase_token text not null unique`
- `order_id text`
- `purchase_state text not null`
- `acknowledgement_state text`
- `consumption_state text`
- `quantity integer not null default 1`
- `granted_amount bigint not null default 0`
- `raw_verification jsonb`
- `verified_at timestamptz`
- `consumed_at timestamptz`
- `revoked_at timestamptz`
- `created_at timestamptz`
- `updated_at timestamptz`

No client role can query this table. Purchase tokens and Google responses are available only to Edge Functions and administrative roles.

`subject_hash` is a server-keyed pseudonymous identifier. Account deletion nulls `user_id` but retains the token, product, state, and pseudonymous identifier so a previously granted token can never be replayed against a new account.

### `product_catalog`

This table resides in `private` and maps the three fixed product IDs to currency code, grant amount, active status, and version. The Edge Function looks up grants here rather than trusting client-supplied amounts.

## Cloud Progress Synchronization

SharedPreferences remains the immediate gameplay store and offline cache. Server sync never runs in the Flame frame loop.

1. Guest play saves locally as it does today.
2. When Google linking completes, the app fetches `player_progress`.
3. If no cloud row exists, the validated local save becomes revision 1.
4. If a cloud row exists, cloud progress wins and replaces the local cache. This avoids duplicating counters or rewards across installations.
5. Later writes include `expectedRevision`. A matching revision advances atomically; a mismatch returns the current cloud snapshot.
6. On conflict, the app adopts the server snapshot and informs the user that newer cloud progress was loaded.
7. Offline runs continue to save locally. When connectivity returns, synchronization retries with bounded exponential backoff.

Paid currency is never included in progress merge logic. A wallet refresh always comes from the server.

## Google Play Purchase Flow

1. The app confirms a permanent Google-linked Supabase session.
2. Google Play Billing returns current Product Details; the app displays Google's localized price.
3. The user completes or begins a purchase through Google Play.
4. Pending purchases remain pending and grant nothing.
5. For a purchased item, the app sends `productId`, `purchaseToken`, and package name to `verify-google-play-purchase` with the Supabase access token.
6. The Edge Function validates the user, package name, product ID, and purchase token with the Google Play Developer API.
7. In one PostgreSQL transaction, the backend locks the token and wallet, rejects mismatched ownership or products, inserts the purchase if new, appends one ledger grant, and updates the wallet.
8. A repeated token returns the previously recorded result without granting again.
9. The backend consumes the consumable product through Google Play. Failed consumption remains retryable without duplicating the ledger grant.
10. The app refreshes the wallet and completes its local purchase handling.

Real-time Developer Notifications feed a second authenticated webhook function. Refunds and revocations append compensating negative ledger entries. If already-spent funds would make the balance negative, the wallet remains at zero and the shortfall is added to `royal_jade_debt`, which blocks further paid spending. Future grants settle debt before increasing the spendable balance; historical ledger rows are never edited.

## Trusted Backend Operations

Edge Functions:

- `sync-progress`: validated optimistic-concurrency cloud save.
- `verify-google-play-purchase`: purchase verification, idempotent grant, and consume retry.
- `google-play-notification`: authenticated Pub/Sub push handling for refunds and state changes.
- `spend-royal-jade`: atomic balance check, ledger debit, and entitlement grant.
- `delete-account`: revoke sessions, remove gameplay/profile/wallet/ledger data, detach and pseudonymize retained purchase-token audit records, then delete the auth user.

Privileged secrets, including the Google service-account credentials and Supabase secret/service role, exist only in Edge Function secrets. The Android app contains only the Supabase project URL and publishable key.

## Security Invariants

- No paid balance mutation is reachable through direct client table writes.
- Every purchase token is globally unique and grants at most once.
- Every wallet change has exactly one immutable ledger entry and a resulting balance.
- Product quantity and grant amount come from trusted Google data and server catalog data.
- Anonymous users cannot purchase or spend paid currency.
- `user_metadata` is never used for authorization.
- Service-role and Google credentials never enter the repository, APK, logs, or client environment.
- RLS is enabled and tested for all exposed tables; views are `security_invoker` or private.
- Privileged database functions live in a private schema, revoke default `PUBLIC` execute permission, validate `auth.uid()`, and set a safe `search_path`.
- Edge endpoints enforce authentication, body-size limits, strict schemas, idempotency, and rate limits.

## Failure and Offline Behavior

- Auth bootstrap failure: continue as a local guest and show a non-blocking offline status.
- Google link cancellation: keep the guest session and local save unchanged.
- Cloud conflict: load the server snapshot; never silently overwrite it.
- Purchase pending: show `결제 승인 대기 중`; grant nothing.
- Verification timeout: retain the token locally in a retry queue and query owned purchases on resume.
- Duplicate submission: return the original completed result.
- Backend unavailable: disable paid spending and purchasing; offline gameplay remains available.
- Wallet read failure: show the last cached amount as unavailable/stale and prohibit spending.

## UI Changes

- Lobby account chip: guest status, Google link action, connected identity, and sync state.
- Settings account section: link, sign out, manual sync, account deletion, and privacy notice.
- Shop screen: three 금옥 packs using Google Product Details, pending/retry states, purchase restoration query, and server wallet balance.
- Currency display: existing 코인 and 혼옥 remain; 금옥 receives a visually distinct paid-currency badge and accessibility label.
- No login wall appears before the first game.

## Testing and Release Gates

- Pure Dart tests for progress validation, revision conflicts, product catalog, ledger invariants, and idempotency.
- PostgreSQL tests proving cross-user reads/writes fail, direct wallet writes fail, ledger immutability, token uniqueness, and atomic rollback.
- Edge Function tests with fake Google API responses for purchased, pending, invalid, duplicate, consumed, retry, refund, and revoked states.
- Flutter tests for guest bootstrap, Google link success/cancel/failure, account switching, cloud-first load, offline play, stale wallet, and purchase UI states.
- Android license-tester runs for all three products, interrupted purchases, app restart, duplicate callback, pending purchase, refund, and multi-device login.
- Existing analyze, 462-test baseline, web build, Android build, performance profile, and golden gates remain required.
- Supabase database advisors and migration status must pass before production deployment.

## Delivery Boundaries and Agent Ownership

Implementation begins with shared contracts on the integration branch, then proceeds in isolated worktrees:

1. **Database/backend agent** owns `supabase/`, SQL migrations, seed data, RLS tests, and Edge Function shared server modules.
2. **Flutter identity/sync agent** owns auth and cloud-save adapters under `lib/backend/`, account UI, local migration bridge, and corresponding tests.
3. **Android billing agent** owns billing adapters, shop UI, Android billing configuration, purchase retry queue, and corresponding tests.
4. **Main orchestrator** owns shared Dart contracts, dependency changes, cross-agent integration, security review, release documentation, and full gates.

No agent edits another agent's owned files without an explicit handoff. Database contracts and Dart interfaces land before parallel implementation starts.

## Deployment Inputs

Local development and tests use emulators/fakes and require no production secrets. Live staging and production deployment require these external values when the implementation is ready:

- Supabase project URL and publishable key;
- Google OAuth Android client configuration tied to the release application ID and signing certificate;
- Google Play Console product definitions for the three fixed product IDs;
- Google Play Developer API service account with least-privilege access;
- Real-time Developer Notifications Pub/Sub configuration;
- production privacy-policy and account-deletion URLs.

These values are injected through platform configuration and secret stores, never committed to Git.
