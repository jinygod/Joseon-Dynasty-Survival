# Backend launch TODO

This checklist tracks external staging/production work. Do not mark an item
complete without a dated change record or test evidence. Never paste secret
values into this file.

## Supabase projects

- [ ] Create separate staging and production projects and record project refs in
      the restricted deployment inventory.
- [ ] Enable anonymous sign-in, manual identity linking, and Google Auth for both
      projects; limit production redirects to approved URLs.
- [ ] Verify fresh anonymous session, UUID-preserving Google link, existing-account
      conflict handling, sign-out, and cross-device restore on staging.
- [ ] Inventory Function secret names and set environment-specific values outside
      Git: `ANDROID_PACKAGE_NAME`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`,
      `PUBSUB_AUDIENCE`, and `PUBSUB_SERVICE_ACCOUNT_EMAIL`.
- [ ] Run `.\tool\backend_check.ps1`, `supabase migration list --linked`, and
      `supabase db push --linked --dry-run` from a clean release commit.
- [ ] Confirm backup/PITR recovery point, then push migrations and deploy all four
      Edge Functions using the documented order.

## Google and Play Console

- [ ] Create/verify Android OAuth clients for the actual debug/upload/app-signing
      certificates and a Web OAuth client for Supabase Auth.
- [ ] Create and activate `royal_jade_small`, `royal_jade_medium`, and
      `royal_jade_large`; keep multi-quantity disabled and verify localized prices.
- [ ] Create a dedicated Android Publisher service account scoped to this app with
      only billing API permissions; store and rotate its credential securely.
- [ ] Configure the RTDN topic, Google Play publisher grant, authenticated push
      subscription, OIDC audience/email secrets, Play Console topic, and test send.
- [ ] Add license testers and internal-track testers, then install from Google Play.
- [ ] Execute all three purchase grants, response-loss/duplicate, pending/cancel,
      refund/debt, RTDN-before-grant, account switch, and deletion/replay tests.

## Policy and launch

- [ ] Publish reviewed HTTPS privacy-policy and account-deletion web URLs.
- [ ] Complete Play Console Data safety and deletion declarations consistently
      with retained pseudonymous purchase audit behavior.
- [ ] Verify the in-app recent-auth deletion flow and the public web request flow.
- [ ] Approve rollback, compensating-migration, Pub/Sub backlog, and key-rotation
      runbooks with named incident owners.
- [ ] Start a staged rollout and monitor Function errors, Google API permissions,
      Pub/Sub backlog, duplicate-token mismatch, refunds, and wallet debt.

See `docs/backend/android-backend-operations.md` and
`docs/backend/google-play-console-setup.md` for exact steps.
