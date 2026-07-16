import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import 'purchase_gateway.dart';

abstract interface class GooglePlayBillingClient {
  Stream<List<iap.PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<iap.ProductDetailsResponse> queryProductDetails(Set<String> ids);
  Future<bool> buyConsumable({
    required iap.PurchaseParam purchaseParam,
    required bool autoConsume,
  });
  Future<void> restorePurchases();
  Future<void> completePurchase(iap.PurchaseDetails purchase);
}

class InAppPurchaseBillingClient implements GooglePlayBillingClient {
  InAppPurchaseBillingClient([iap.InAppPurchase? instance])
    : _instance = instance ?? iap.InAppPurchase.instance;
  final iap.InAppPurchase _instance;

  @override
  Stream<List<iap.PurchaseDetails>> get purchaseStream =>
      _instance.purchaseStream;
  @override
  Future<bool> isAvailable() => _instance.isAvailable();
  @override
  Future<iap.ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _instance.queryProductDetails(ids);
  @override
  Future<bool> buyConsumable({
    required iap.PurchaseParam purchaseParam,
    required bool autoConsume,
  }) => _instance.buyConsumable(
    purchaseParam: purchaseParam,
    autoConsume: autoConsume,
  );
  @override
  Future<void> restorePurchases() => _instance.restorePurchases();
  @override
  Future<void> completePurchase(iap.PurchaseDetails purchase) =>
      _instance.completePurchase(purchase);
}

class GooglePlayPurchaseGateway implements PurchaseGateway {
  GooglePlayPurchaseGateway({GooglePlayBillingClient? billingClient})
    : _client = billingClient ?? InAppPurchaseBillingClient() {
    _subscription = _client.purchaseStream.listen(
      _onPurchases,
      onError: _onStreamError,
    );
  }

  final GooglePlayBillingClient _client;
  final _updates = StreamController<PurchaseUpdate>.broadcast();
  final _productDetails = <String, iap.ProductDetails>{};
  final _purchaseDetails = <String, iap.PurchaseDetails>{};
  late final StreamSubscription<List<iap.PurchaseDetails>> _subscription;
  bool _disposed = false;

  @override
  Stream<PurchaseUpdate> get updates => _updates.stream;

  @override
  Future<bool> isAvailable() => _client.isAvailable();

  @override
  Future<List<PremiumProduct>> loadProducts(Set<String> productIds) async {
    if (!setEquals(productIds, PremiumProduct.ids)) {
      throw ArgumentError.value(
        productIds,
        'productIds',
        'must be exact catalog',
      );
    }
    final response = await _client.queryProductDetails(PremiumProduct.ids);
    if (response.error != null) throw StateError(response.error!.message);
    final found = response.productDetails.map((item) => item.id).toSet();
    if (!found.containsAll(PremiumProduct.ids)) {
      throw StateError('Google Play catalog is incomplete');
    }
    _productDetails
      ..clear()
      ..addEntries(
        response.productDetails.map((item) => MapEntry(item.id, item)),
      );
    return [
      for (final id in [
        PremiumProduct.smallId,
        PremiumProduct.mediumId,
        PremiumProduct.largeId,
      ])
        _toProduct(_productDetails[id]!),
    ];
  }

  @override
  Future<void> purchase(PremiumProduct product) async {
    final details = _productDetails[product.id];
    if (details == null) throw StateError('product was not loaded');
    final launched = await _client.buyConsumable(
      purchaseParam: iap.PurchaseParam(productDetails: details),
      autoConsume: false,
    );
    if (!launched) throw StateError('Google Play purchase did not start');
  }

  @override
  Future<void> recoverUnfinishedPurchases() => _client.restorePurchases();

  @override
  Future<void> complete(PurchaseUpdate purchase) async {
    final token = purchase.purchaseToken;
    final details = token == null ? null : _purchaseDetails[token];
    if (details == null) throw StateError('purchase details are unavailable');
    if (details.pendingCompletePurchase) {
      await _client.completePurchase(details);
    }
    _purchaseDetails.remove(token);
  }

  void _onPurchases(List<iap.PurchaseDetails> values) {
    if (_disposed) return;
    for (final details in values) {
      if (!PremiumProduct.ids.contains(details.productID)) continue;
      final token = details.verificationData.serverVerificationData.trim();
      switch (details.status) {
        case iap.PurchaseStatus.pending:
          _updates.add(PurchaseUpdate.pending(productId: details.productID));
        case iap.PurchaseStatus.purchased:
        case iap.PurchaseStatus.restored:
          if (token.isEmpty) {
            _updates.add(
              PurchaseUpdate.error(
                productId: details.productID,
                message: 'Google Play returned an empty purchase token',
              ),
            );
          } else {
            _purchaseDetails[token] = details;
            _updates.add(
              PurchaseUpdate.purchased(
                productId: details.productID,
                purchaseToken: token,
              ),
            );
          }
        case iap.PurchaseStatus.canceled:
          _updates.add(PurchaseUpdate.canceled(productId: details.productID));
        case iap.PurchaseStatus.error:
          _updates.add(
            PurchaseUpdate.error(
              productId: details.productID,
              message: details.error?.message ?? 'Google Play purchase failed',
            ),
          );
      }
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    if (!_disposed) _updates.addError(error, stackTrace);
  }

  static PremiumProduct _toProduct(iap.ProductDetails details) =>
      PremiumProduct(
        id: details.id,
        title: details.title,
        description: details.description,
        price: details.price,
      );

  static bool setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _subscription.cancel();
    await _updates.close();
  }
}
