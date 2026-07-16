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
        ownerUserId: 'u1',
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
        '{"ownerUserId":"u1","productId":"royal_jade_medium","purchaseToken":"token-2"}',
      ],
    });
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesPurchaseRetryStore(preferences);

    expect(await store.load(), {
      const PendingPurchase(
        ownerUserId: 'u1',
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

  test(
    'concurrent writes are serialized without losing either owner token',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesPurchaseRetryStore(preferences);

      await Future.wait([
        store.put(
          const PendingPurchase(
            ownerUserId: 'u1',
            productId: PremiumProduct.smallId,
            purchaseToken: 'token-a',
          ),
        ),
        store.put(
          const PendingPurchase(
            ownerUserId: 'u2',
            productId: PremiumProduct.largeId,
            purchaseToken: 'token-b',
          ),
        ),
      ]);

      expect((await store.load()).map((entry) => entry.purchaseToken).toSet(), {
        'token-a',
        'token-b',
      });
    },
  );

  test(
    'failed SharedPreferences writes throw and are never reported durable',
    () async {
      final store = SharedPreferencesPurchaseRetryStore.withPreferences(
        FailingPurchasePreferences(),
      );
      await expectLater(
        store.put(
          const PendingPurchase(
            ownerUserId: 'u1',
            productId: PremiumProduct.smallId,
            purchaseToken: 'token-a',
          ),
        ),
        throwsA(isA<PurchasePersistenceException>()),
      );
    },
  );
}

class FailingPurchasePreferences implements PurchasePreferences {
  @override
  List<String>? getStringList(String key) => null;

  @override
  Future<bool> setStringList(String key, List<String> value) async => false;
}
