import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:pixel_survivor/backend/economy/google_play_purchase_gateway.dart';
import 'package:pixel_survivor/backend/economy/purchase_gateway.dart';

void main() {
  test(
    'subscribes once, queries exact catalog, and keeps localized prices',
    () async {
      final client = FakeBillingClient();
      final gateway = GooglePlayPurchaseGateway(billingClient: client);

      final products = await gateway.loadProducts(PremiumProduct.ids);

      expect(client.listenerCount, 1);
      expect(client.queriedIds, PremiumProduct.ids);
      expect(products.map((item) => item.price), ['₩1,100', r'$4.99', '€8,99']);
      await gateway.purchase(products.first, applicationUserName: 'user-a');
      expect(client.autoConsume, isFalse);
      expect(client.purchasedProductId, PremiumProduct.smallId);
      expect(client.applicationUserName, 'user-a');
      await gateway.recoverUnfinishedPurchases(applicationUserName: 'user-a');
      expect(client.restoredApplicationUserName, 'user-a');
      await gateway.dispose();
    },
  );

  test(
    'uses server token and completes only when explicitly accepted',
    () async {
      final client = FakeBillingClient();
      final gateway = GooglePlayPurchaseGateway(billingClient: client);
      final updates = <PurchaseUpdate>[];
      final subscription = gateway.updates.listen(updates.add);
      final details = purchaseDetails(
        status: iap.PurchaseStatus.purchased,
        token: 'server-token',
      )..pendingCompletePurchase = true;

      client.emit([details]);
      await flush();

      expect(updates.single.purchaseToken, 'server-token');
      expect(updates.single.ownerUserId, 'user-a');
      expect(client.completed, isEmpty);
      await gateway.complete(updates.single);
      expect(client.completed, [details]);
      await subscription.cancel();
      await gateway.dispose();
    },
  );

  test('pending, canceled, and error map without a grant token', () async {
    final client = FakeBillingClient();
    final gateway = GooglePlayPurchaseGateway(billingClient: client);
    final updates = <PurchaseUpdate>[];
    final subscription = gateway.updates.listen(updates.add);

    client.emit([
      purchaseDetails(status: iap.PurchaseStatus.pending),
      purchaseDetails(status: iap.PurchaseStatus.canceled),
      purchaseDetails(status: iap.PurchaseStatus.error)
        ..error = iap.IAPError(
          source: 'google_play',
          code: 'declined',
          message: 'declined',
        ),
    ]);
    await flush();

    expect(updates.map((item) => item.status), [
      PurchaseStatus.pending,
      PurchaseStatus.canceled,
      PurchaseStatus.error,
    ]);
    expect(updates.every((item) => item.purchaseToken == null), isTrue);
    await subscription.cancel();
    await gateway.dispose();
  });

  test(
    'stream errors and unknown callbacks do not stop later valid updates',
    () async {
      final client = FakeBillingClient();
      final gateway = GooglePlayPurchaseGateway(billingClient: client);
      final updates = <PurchaseUpdate>[];
      final errors = <Object>[];
      final subscription = gateway.updates.listen(
        updates.add,
        onError: errors.add,
      );

      client.emitError(StateError('billing disconnected'));
      client.emit([
        iap.PurchaseDetails(
          productID: PremiumProduct.smallId,
          verificationData: iap.PurchaseVerificationData(
            localVerificationData: 'local',
            serverVerificationData: 'generic-token',
            source: 'test',
          ),
          transactionDate: null,
          status: iap.PurchaseStatus.purchased,
        ),
        purchaseDetails(
          status: iap.PurchaseStatus.purchased,
          token: 'unknown-token',
          productId: 'unknown-product',
        ),
        purchaseDetails(status: iap.PurchaseStatus.pending),
      ]);
      await flush();

      expect(errors.single, isA<StateError>());
      expect(updates.single.status, PurchaseStatus.pending);
      await subscription.cancel();
      await gateway.dispose();
    },
  );
}

GooglePlayPurchaseDetails purchaseDetails({
  required iap.PurchaseStatus status,
  String token = '',
  String productId = PremiumProduct.smallId,
  String? ownerUserId = 'user-a',
}) => GooglePlayPurchaseDetails(
  purchaseID: 'purchase-id',
  productID: productId,
  verificationData: iap.PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: token,
    source: 'google_play',
  ),
  transactionDate: null,
  status: status,
  billingClientPurchase: PurchaseWrapper(
    orderId: 'order-id',
    packageName: 'com.pixel.survivor.pixel_survivor',
    purchaseTime: 1,
    purchaseToken: token,
    signature: 'signature',
    products: [productId],
    isAutoRenewing: false,
    originalJson: '{}',
    isAcknowledged: false,
    purchaseState: status == iap.PurchaseStatus.pending
        ? PurchaseStateWrapper.pending
        : PurchaseStateWrapper.purchased,
    obfuscatedAccountId: ownerUserId,
  ),
);

Future<void> flush() => Future<void>.delayed(Duration.zero);

class FakeBillingClient implements GooglePlayBillingClient {
  final _purchases = StreamController<List<iap.PurchaseDetails>>.broadcast(
    onListen: null,
  );
  int listenerCount = 0;
  Set<String>? queriedIds;
  bool? autoConsume;
  String? purchasedProductId;
  String? applicationUserName;
  String? restoredApplicationUserName;
  final completed = <iap.PurchaseDetails>[];

  FakeBillingClient() {
    _purchases.onListen = () => listenerCount += 1;
  }

  void emit(List<iap.PurchaseDetails> values) => _purchases.add(values);
  void emitError(Object error) => _purchases.addError(error);

  @override
  Stream<List<iap.PurchaseDetails>> get purchaseStream => _purchases.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<iap.ProductDetailsResponse> queryProductDetails(
    Set<String> ids,
  ) async {
    queriedIds = Set.of(ids);
    return iap.ProductDetailsResponse(
      productDetails: [
        product(PremiumProduct.smallId, '₩1,100'),
        product(PremiumProduct.mediumId, r'$4.99'),
        product(PremiumProduct.largeId, '€8,99'),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyConsumable({
    required iap.PurchaseParam purchaseParam,
    required bool autoConsume,
  }) async {
    this.autoConsume = autoConsume;
    purchasedProductId = purchaseParam.productDetails.id;
    applicationUserName = purchaseParam.applicationUserName;
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoredApplicationUserName = applicationUserName;
  }

  @override
  Future<void> completePurchase(iap.PurchaseDetails purchase) async {
    completed.add(purchase);
  }
}

iap.ProductDetails product(String id, String price) => iap.ProductDetails(
  id: id,
  title: id,
  description: id,
  price: price,
  rawPrice: 1,
  currencyCode: 'KRW',
);
