import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/economy/purchase_gateway.dart';
import 'package:pixel_survivor/backend/economy/purchase_retry_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'pending purchases survive recreation and duplicate tokens are idempotent',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final first = SharedPreferencesPurchaseRetryStore(preferences);
      const purchase = PendingPurchase(
        productId: PremiumProduct.smallId,
        purchaseToken: 'token-1',
      );

      await first.put(purchase);
      await first.put(purchase);
      final restored = SharedPreferencesPurchaseRetryStore(preferences);

      expect(await restored.load(), {purchase});
    },
  );

  test('removal is durable and malformed entries are ignored', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesPurchaseRetryStore.storageKey: [
        '{bad json',
        '{"productId":"","purchaseToken":"bad"}',
        '{"productId":"royal_jade_medium","purchaseToken":"token-2"}',
      ],
    });
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesPurchaseRetryStore(preferences);

    expect(await store.load(), {
      const PendingPurchase(
        productId: PremiumProduct.mediumId,
        purchaseToken: 'token-2',
      ),
    });
    await store.remove('token-2');
    expect(
      await SharedPreferencesPurchaseRetryStore(preferences).load(),
      isEmpty,
    );
  });
}
