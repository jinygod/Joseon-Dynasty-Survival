# Android Backend and Premium Economy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add guest-to-Google accounts, revisioned cloud saves, and server-authoritative Google Play paid currency to the Android game without breaking offline play.

**Architecture:** Shared Dart contracts isolate the existing game from Supabase and Google Play adapters. Supabase Auth and RLS protect user-owned reads, while Edge Functions and private PostgreSQL functions exclusively mutate progress and paid wallets. SharedPreferences remains the offline gameplay cache; Google Play purchase tokens are verified and granted idempotently on the server.

**Tech Stack:** Flutter/Dart 3.12, Flame, `supabase_flutter` 2.16.0, `google_sign_in` 7.2.0, `in_app_purchase` 3.3.0, Supabase CLI 2.109.1, PostgreSQL/pgTAP, Supabase Edge Functions/Deno, Google Play Billing and Developer API.

## Global Constraints

- Android is the only release platform in this plan.
- Guest play must remain available when auth or the backend is offline.
- Google linking is required before cloud sync, purchasing, or paid-currency spending.
- Existing `coin` and `spiritJade`/혼옥 remain earnable and stay in `SaveState`; paid `royal_jade`/금옥 never enters `SaveState`.
- Fixed product IDs and grants are `royal_jade_small=100`, `royal_jade_medium=550`, and `royal_jade_large=1200`.
- No client code may update wallets, insert ledger rows, choose grant amounts, or contain a Supabase secret/service-role key or Google service-account credential.
- Every exposed table enables RLS; private tables and privileged functions are not Data API surfaces.
- Every purchase, spend, refund, and retry is idempotent.
- TDD is mandatory: observe the focused test fail before adding implementation, then run the focused and adjacent suites.
- Each agent edits only the files assigned to its worktree.

---

### Task 1: Shared Dart contracts and pinned dependencies

**Owner:** Main orchestrator; complete before parallel agents start.

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `lib/backend/backend_config.dart`
- Create: `lib/backend/account/account_session.dart`
- Create: `lib/backend/account/account_service.dart`
- Create: `lib/backend/progress/cloud_progress_repository.dart`
- Create: `lib/backend/economy/premium_wallet.dart`
- Create: `lib/backend/economy/purchase_gateway.dart`
- Test: `test/backend/backend_contracts_test.dart`

**Interfaces:**
- Produces: `BackendConfig`, `AccountSession`, `AccountService`, `CloudProgressSnapshot`, `CloudProgressRepository`, `PremiumWallet`, `PremiumProduct`, `PurchaseUpdate`, and `PurchaseGateway`.
- Consumes: existing `SaveState` from `lib/game/systems/save_system.dart`.

- [ ] **Step 1: Write contract tests**

```dart
test('paid wallet cannot be represented as a negative balance', () {
  expect(() => PremiumWallet(balance: -1, debt: 0, version: 0),
      throwsArgumentError);
});

test('cloud snapshot carries the server revision and SaveState', () {
  final snapshot = CloudProgressSnapshot(revision: 7, save: SaveState.defaults());
  expect(snapshot.revision, 7);
  expect(snapshot.save.schemaVersion, SaveState.currentSchemaVersion);
});
```

- [ ] **Step 2: Run the tests and observe missing contracts**

Run: `flutter test test/backend/backend_contracts_test.dart -r compact`

Expected: FAIL because `PremiumWallet` and `CloudProgressSnapshot` do not exist.

- [ ] **Step 3: Add pinned packages and minimal interfaces**

```yaml
dependencies:
  google_sign_in: 7.2.0
  in_app_purchase: 3.3.0
  supabase_flutter: 2.16.0
```

```dart
abstract interface class CloudProgressRepository {
  Future<CloudProgressSnapshot?> fetch();
  Future<CloudProgressSnapshot> create(SaveState save);
  Future<CloudSyncResult> update({
    required SaveState save,
    required int expectedRevision,
  });
}

abstract interface class AccountService {
  Stream<AccountSession> get changes;
  AccountSession get current;
  Future<AccountSession> ensureGuest();
  Future<AccountSession> connectGoogle();
  Future<void> signOut();
  Future<void> deleteAccount();
}
```

`BackendConfig.fromEnvironment()` reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` through `String.fromEnvironment`; an absent configuration returns `BackendConfig.disabled` rather than crashing offline play.

- [ ] **Step 4: Resolve dependencies and pass focused tests**

Run: `flutter pub get`

Run: `flutter test test/backend/backend_contracts_test.dart -r compact`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add pubspec.yaml pubspec.lock lib/backend test/backend/backend_contracts_test.dart
git commit -m "feat: define backend account progress and economy contracts"
```

### Task 2: Supabase local project, schema, RLS, and wallet transaction core

**Owner:** Database/backend agent.

**Files:**
- Create: `package.json`
- Create: `package-lock.json`
- Create: `supabase/config.toml`
- Create: `supabase/seed.sql`
- Create: the timestamped `supabase/migrations/*_backend_economy.sql` path printed by `npx supabase migration new backend_economy`
- Create: `supabase/tests/backend_economy_test.sql`
- Create: `supabase/functions/_shared/contracts.ts`
- Modify: `.gitignore`

**Interfaces:**
- Produces: tables `profiles`, `player_progress`, `wallets`, `wallet_ledger`, `private.google_play_purchases`, `private.product_catalog`, `private.premium_catalog`, and `player_entitlements`; private functions `apply_wallet_entry`, `spend_for_entitlement`, and `sync_progress`.
- Consumes: fixed product IDs and JSON field names from Task 1 and the design spec.

- [ ] **Step 1: Pin and discover the Supabase CLI**

```json
{
  "private": true,
  "devDependencies": {"supabase": "2.109.1"},
  "scripts": {
    "supabase:start": "supabase start",
    "supabase:reset": "supabase db reset --local",
    "supabase:test": "supabase test db"
  }
}
```

Run: `npm install`

Run: `npx supabase --help`

Expected: command help prints successfully.

- [ ] **Step 2: Initialize config and create the migration through the CLI**

Run: `npx supabase init`

Run: `npx supabase migration new backend_economy`

Expected: `supabase/config.toml` and one timestamped migration file exist. Configure anonymous sign-ins and manual linking, and reference Google OAuth secrets only with `env(...)`.

- [ ] **Step 3: Write failing pgTAP security and invariant tests**

Tests must assert:

```sql
select policies_are('public', 'wallets', array['wallet_read_own']);
select throws_ok(
  $$ update public.wallets set royal_jade = 999 $$,
  '42501'
);
select throws_ok(
  $$ insert into public.wallet_ledger
     (user_id, currency_code, delta, balance_after, reason,
      reference_type, reference_id, idempotency_key)
     values (auth.uid(), 'royal_jade', 1, 1, 'hack', 'test', '1', 'hack') $$,
  '42501'
);
```

Also prove cross-user reads return zero rows, a duplicate idempotency key grants once, a duplicate purchase token grants once, unknown or inactive premium SKUs cannot spend, insufficient spending rolls back, an entitlement is granted once, ledger update/delete is denied, and refund debt settles before a later grant. Seed the spend tests with a test-only `test_cosmetic` SKU; leave the production seed catalog empty.

- [ ] **Step 4: Run tests and observe missing relations**

Run: `npx supabase start`

Run: `npx supabase test db`

Expected: FAIL because schema objects do not exist.

- [ ] **Step 5: Implement schema and private transaction functions**

Create all columns and constraints verbatim from the design. Enable RLS explicitly. Revoke all wallet and ledger mutations from `anon` and `authenticated`. Put privileged functions in `private`, set `search_path = ''`, revoke execute from `public`, and grant only the server execution role.

The wallet function accepts `(user_id, delta, reason, reference_type, reference_id, idempotency_key, metadata)`, locks the wallet row, returns an existing ledger result for a repeated key, settles debt before credits, creates debt for refund shortfalls, and inserts exactly one ledger row.

- [ ] **Step 6: Reset, test, and run advisors**

Run: `npx supabase db reset --local`

Run: `npx supabase test db`

Run: `npx supabase db lint --local --level warning`

Expected: all pgTAP tests pass and lint reports no security error.

- [ ] **Step 7: Commit**

```powershell
git add package.json package-lock.json supabase .gitignore
git commit -m "feat: add secure Supabase economy schema"
```

### Task 3: Google Play verification Edge Functions

**Owner:** Database/backend agent after Task 2.

**Files:**
- Create: `supabase/functions/_shared/auth.ts`
- Create: `supabase/functions/_shared/google_play_client.ts`
- Create: `supabase/functions/_shared/http.ts`
- Create: `supabase/functions/verify-google-play-purchase/index.ts`
- Create: `supabase/functions/google-play-notification/index.ts`
- Create: `supabase/functions/spend-royal-jade/index.ts`
- Create: `supabase/functions/delete-account/index.ts`
- Create: `supabase/functions/tests/google_play_functions_test.ts`

**Interfaces:**
- Produces: authenticated JSON endpoints named by their directory paths.
- Consumes: Task 2 private schema/functions and catalog; request purchase fields from Task 1.

- [ ] **Step 1: Write fake-client function tests**

```ts
Deno.test('duplicate verified token returns one grant', async () => {
  const first = await handler(request('royal_jade_small', 'token-1'), deps);
  const second = await handler(request('royal_jade_small', 'token-1'), deps);
  assertEquals(first.body.balance, 100);
  assertEquals(second.body.balance, 100);
  assertEquals(deps.ledgerEntries.length, 1);
});
```

Cover missing JWT, anonymous JWT, malformed body, package mismatch, unknown product, pending, invalid, purchased, duplicate, consume retry, Pub/Sub authentication failure, refund, debt, spend, and deletion pseudonymization.

- [ ] **Step 2: Run tests and observe missing handlers**

Run: `npx supabase functions serve --env-file supabase/.env.test`

Run the function tests through the Deno runtime bundled by the Supabase CLI.

Expected: FAIL because handlers and dependency interfaces do not exist.

- [ ] **Step 3: Implement strict transport and Google API adapters**

Every function must:

```ts
if (request.method !== 'POST') return json(405, {code: 'method_not_allowed'});
const user = await requirePermanentUser(request, deps.auth);
const body = PurchaseRequest.parse(await boundedJson(request, 16_384));
```

The verifier obtains Google credentials from function secrets, calls Android Publisher API v3 `purchases.productsv2.getproductpurchasev2`, checks `PURCHASED`, package and product ownership, calls the database transaction once, and then calls `purchases.products.consume`. It never accepts amount, balance, user ID, or order state from the client.

- [ ] **Step 4: Pass function tests and database tests**

Run the focused Deno tests, `npx supabase test db`, and `npx supabase db lint --local --level warning`.

Expected: PASS with secrets redacted from all logs.

- [ ] **Step 5: Commit**

```powershell
git add supabase/functions
git commit -m "feat: verify Google Play purchases server-side"
```

### Task 4: Flutter guest auth, Google linking, and account UI

**Owner:** Flutter identity/sync agent.

**Files:**
- Create: `lib/backend/account/supabase_account_service.dart`
- Create: `lib/backend/account/account_controller.dart`
- Create: `lib/app/account_section.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app/pixel_survivor_app.dart`
- Modify: `lib/app/lobby_screen.dart`
- Modify: `lib/app/settings_screen.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Test: `test/backend/account_controller_test.dart`
- Test: `test/app/account_section_test.dart`

**Interfaces:**
- Consumes: `BackendConfig`, `AccountService`, and `AccountSession` from Task 1.
- Produces: `SupabaseAccountService`, `AccountController`, and account/sync UI callbacks for Task 5.

- [ ] **Step 1: Write controller and widget tests**

Test disabled backend, offline guest fallback, restored anonymous session, restored Google session, new-identity link preserving the guest user ID, existing-identity sign-in switching to the permanent account, Google cancellation, Google error, sign-out cache clearing, and delete confirmation. A test fake implements `AccountService` without loading Supabase.

- [ ] **Step 2: Run focused tests and observe missing classes**

Run: `flutter test test/backend/account_controller_test.dart test/app/account_section_test.dart -r compact`

Expected: FAIL because the controller and widget do not exist.

- [ ] **Step 3: Initialize Supabase only when configured**

```dart
final config = BackendConfig.fromEnvironment();
if (config.enabled) {
  await Supabase.initialize(url: config.url, anonKey: config.publishableKey);
}
runApp(PixelSurvivorApp(backendConfig: config));
```

`ensureGuest()` restores the current session or calls `signInAnonymously`. Initialize `GoogleSignIn.instance` exactly once with the server client ID, obtain its ID token, then call `linkIdentityWithIdToken(provider: OAuthProvider.google, idToken: token)`. If Supabase reports that the identity already belongs to an account, sign out the anonymous Supabase session and call `signInWithIdToken` with the same token; Task 5 then loads that account's cloud snapshot. No OAuth client secret or Google access token is persisted in the app.

- [ ] **Step 4: Add non-blocking lobby and settings surfaces**

Guest copy is `게스트 · 이 기기에만 저장`; permanent copy shows the Google email and sync state. Purchase readiness is derived from `AccountSession.isPermanent`, never from editable user metadata.

- [ ] **Step 5: Pass focused and existing app tests**

Run: `flutter test test/backend/account_controller_test.dart test/app/account_section_test.dart test/app/lobby_screen_test.dart test/app/settings_screen_test.dart -r compact`

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib/main.dart lib/backend/account lib/app android/app/src/main/AndroidManifest.xml test/backend test/app
git commit -m "feat: add guest and Google account linking"
```

### Task 5: Cloud save adapter and offline synchronization

**Owner:** Flutter identity/sync agent after Task 4.

**Files:**
- Create: `lib/backend/progress/supabase_cloud_progress_repository.dart`
- Create: `lib/backend/progress/progress_sync_controller.dart`
- Create: `lib/backend/progress/save_state_validator.dart`
- Modify: `lib/app/lobby_controller.dart`
- Modify: `lib/app/game_screen.dart`
- Modify: `lib/app/account_section.dart`
- Test: `test/backend/progress_sync_controller_test.dart`
- Test: `test/backend/save_state_validator_test.dart`

**Interfaces:**
- Consumes: Task 1 cloud contracts and Task 4 account state.
- Produces: `ProgressSyncController.syncNow()` and `SyncStatus` for lobby/settings.

- [ ] **Step 1: Write deterministic synchronization tests**

Cover local-only guest, initial upload, cloud-first replacement, successful expected-revision update, conflict adopting the server snapshot, offline retry, account switch, and rejection of paid fields or unknown content IDs.

- [ ] **Step 2: Run focused tests and observe missing controller**

Run: `flutter test test/backend/progress_sync_controller_test.dart test/backend/save_state_validator_test.dart -r compact`

Expected: FAIL.

- [ ] **Step 3: Implement validation and synchronization**

`syncNow()` does no work for guests. For permanent users it loads local `SaveState`, fetches cloud, creates only if absent, otherwise updates with the remembered revision. Conflict replaces SharedPreferences with the returned cloud snapshot. Retries use 1, 2, 4, 8, and 16 second delays and stop when the app disposes the controller.

- [ ] **Step 4: Wire sync outside the game loop**

Run sync after account linking, lobby resume, and completed run settlement. Never call Supabase from `PixelSurvivorGame.update` or component methods.

- [ ] **Step 5: Pass focused, save migration, and flow tests**

Run: `flutter test test/backend test/game/save_system_test.dart test/game/save_migration_regression_test.dart test/app -r compact`

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib/backend/progress lib/app test/backend test/app
git commit -m "feat: synchronize local progress with cloud saves"
```

### Task 6: Android billing adapter, purchase retry queue, and shop UI

**Owner:** Android billing agent.

**Files:**
- Create: `lib/backend/economy/google_play_purchase_gateway.dart`
- Create: `lib/backend/economy/supabase_economy_repository.dart`
- Create: `lib/backend/economy/purchase_controller.dart`
- Create: `lib/backend/economy/purchase_retry_store.dart`
- Create: `lib/app/premium_shop_screen.dart`
- Create: `lib/app/premium_wallet_badge.dart`
- Modify: `lib/app/lobby_screen.dart`
- Modify: `android/app/build.gradle.kts`
- Test: `test/backend/purchase_controller_test.dart`
- Test: `test/backend/purchase_retry_store_test.dart`
- Test: `test/app/premium_shop_screen_test.dart`

**Interfaces:**
- Consumes: Task 1 economy contracts and permanent account status from Task 4.
- Produces: `PurchaseController`, shop navigation, wallet refresh, and resumable verification queue.

- [ ] **Step 1: Write purchase state-machine tests**

Cover unavailable store, product query failure, localized product display, guest purchase rejection, pending, purchased, canceled, error, duplicate callbacks, verification timeout, restart retry, server rejection, wallet refresh, and `completePurchase` only after durable server acceptance.

- [ ] **Step 2: Run focused tests and observe missing implementation**

Run: `flutter test test/backend/purchase_controller_test.dart test/backend/purchase_retry_store_test.dart test/app/premium_shop_screen_test.dart -r compact`

Expected: FAIL.

- [ ] **Step 3: Implement `in_app_purchase` adapter**

Subscribe once to `InAppPurchase.instance.purchaseStream`, query exactly the three product IDs, call `buyConsumable(autoConsume: false)`, and send `serverVerificationData` as the Google purchase token. Persist unverified tokens before the network request and retry them on startup/resume.

- [ ] **Step 4: Implement server wallet and shop UI**

Prices come only from `ProductDetails.price`. Guest action opens the account-link prompt. A stale wallet displays `금옥 —` and cannot spend. Pending text is `결제 승인 대기 중`; retry text is `구매 확인 다시 시도`.

- [ ] **Step 5: Pass focused and lobby tests**

Run: `flutter test test/backend test/app/premium_shop_screen_test.dart test/app/lobby_screen_test.dart -r compact`

Expected: PASS.

- [ ] **Step 6: Build Android debug**

Run: `flutter build apk --debug`

Expected: `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 7: Commit**

```powershell
git add lib/backend/economy lib/app android/app/build.gradle.kts test/backend test/app
git commit -m "feat: add verified Google Play premium shop"
```

### Task 7: Integration, security review, and release documentation

**Owner:** Main orchestrator after Tasks 2-6 are reviewed and merged.

**Files:**
- Modify: overlapping application composition files during merge only
- Create: `docs/backend/android-backend-operations.md`
- Create: `docs/backend/google-play-console-setup.md`
- Create: `tool/backend_check.ps1`
- Modify: `README.md`
- Modify: `TODO.md`
- Test: `test/app/backend_game_flow_test.dart`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: one integrated, documented, locally verifiable Android backend build.

- [ ] **Step 1: Add an end-to-end fake-backed app flow test**

The test launches as guest, finishes a run locally, links Google, uploads revision 1, sees 100 server 금옥, submits a duplicate purchase callback without a second grant, signs out, signs into the same fake account, and restores both cloud progress and wallet.

- [ ] **Step 2: Review security boundaries before merge**

Search for forbidden secrets and mutations:

```powershell
rg -n "service_role|sb_secret_|private_key|client_email" lib android
rg -n "from\(['\"]wallets|from\(['\"]wallet_ledger" lib
```

Expected: no client secret and no direct client wallet/ledger mutation.

- [ ] **Step 3: Create the aggregate backend check**

`tool/backend_check.ps1` runs formatting, analyze, all Flutter tests, Supabase database tests when Docker is available, function tests, `supabase db lint`, web build, and Android debug build. If Docker is unavailable it reports the database gates as blocked rather than passing them.

- [ ] **Step 4: Run all available gates**

Run: `dart format --output=none --set-exit-if-changed lib test`

Run: `dart analyze`

Run: `flutter test -r compact`

Run: `npm run supabase:test`

Run: `flutter build web`

Run: `flutter build apk --debug`

Expected: all configured gates pass; external live-store tests remain explicitly blocked until credentials are supplied.

- [ ] **Step 5: Document external activation exactly**

Document Supabase environment creation, anonymous/manual-linking switches, Google OAuth redirect, Edge Function secrets, migration dry-run/push, Play product creation, service-account least privilege, RTDN Pub/Sub, license testers, privacy URLs, rollback, and key rotation. Never include real secret values.

- [ ] **Step 6: Commit**

```powershell
git add docs README.md TODO.md tool test/app/backend_game_flow_test.dart
git commit -m "docs: add Android backend operations and release gates"
```

## Integration Order

1. Task 1 lands on `master` and becomes the branch point for all worktrees.
2. Database/backend agent performs Tasks 2 and 3.
3. Flutter identity/sync agent performs Tasks 4 and 5.
4. Android billing agent performs Task 6 against Task 1 contracts, using fakes until Task 3 is merged.
5. Main orchestrator reviews each branch for spec compliance and test quality, merges database first, identity second, billing third, resolves only composition overlaps, and performs Task 7.

## Expected External Blockers

Local code, migrations, fakes, and unit/widget tests proceed without user action. Live verification cannot complete until the user supplies or authorizes a Supabase project, Google OAuth configuration, Play Console application/products, Play Developer API service account, RTDN Pub/Sub, license tester account, and production privacy/account-deletion URLs. These are deployment inputs, not reasons to postpone local implementation.
