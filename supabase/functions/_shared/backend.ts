export async function createBackend(databaseUrl: string) {
  const postgres = (await import("postgres")).default;
  const sql = postgres(databaseUrl, {
    max: 2,
    prepare: false,
    idle_timeout: 20,
  });
  return {
    catalog: {
      async findProduct(productId: string) {
        const rows =
          await sql`select grant_amount, active from private.product_catalog where product_id = ${productId}`;
        return rows[0]
          ? {
            grantAmount: Number(rows[0].grant_amount),
            active: rows[0].active,
          }
          : null;
      },
    },
    economy: {
      async grantPurchase(input: Record<string, unknown>) {
        const rows =
          await sql`select * from private.record_google_play_purchase(
          ${input.userId as string}::uuid, ${input.productId as string}, ${input
            .purchaseToken as string},
          ${input.orderId as string | null}, 'PURCHASED', ${
            sql.json(input.rawVerification as never)
          }::jsonb)`;
        return {
          balance: Number(rows[0].balance),
          debt: Number(rows[0].debt),
          duplicate: rows[0].duplicate,
        };
      },
      async spend(userId: string, sku: string) {
        const rows =
          await sql`select * from private.spend_for_entitlement(${userId}::uuid, ${sku})`;
        return {
          entitlementKey: rows[0].entitlement_key,
          balance: Number(rows[0].balance),
          duplicate: rows[0].duplicate,
        };
      },
      async refund(
        input: {
          purchaseToken: string;
          eventId: string;
          refundType: number;
        },
      ) {
        return await sql.begin(async (tx) => {
          const purchase =
            await tx`select user_id, granted_amount, revoked_at from private.google_play_purchases where purchase_token = ${input.purchaseToken} for update`;
          if (!purchase[0]) {
            return { ignored: true, reason: "unknown_token" };
          }
          if (!purchase[0].user_id || purchase[0].revoked_at) {
            return { ignored: true, reason: "already_revoked" };
          }
          const result = await tx`select * from private.apply_wallet_entry(
            ${purchase[0].user_id}::uuid, ${-Number(
            purchase[0].granted_amount,
          )}, 'google_play_refund',
            'google_play_notification', ${input.eventId}, ${`google-play-event:${input.eventId}`},
            ${tx.json({ refundType: input.refundType })}::jsonb)`;
          await tx`update private.google_play_purchases set purchase_state = 'REVOKED', revoked_at = coalesce(revoked_at, now()), updated_at = now() where purchase_token = ${input.purchaseToken}`;
          return {
            balance: Number(result[0].balance),
            debt: Number(result[0].debt),
          };
        });
      },
    },
    accounts: {
      async pseudonymizeAndDelete(userId: string) {
        await sql`select private.pseudonymize_and_delete_account(${userId}::uuid)`;
      },
    },
  };
}
